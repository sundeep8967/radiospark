import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'station_database.dart';

class Station {
  final String stationUuid;
  final String name;
  final String urlResolved;
  final double? lat;
  final double? geoLong;
  final String country;
  final String countryCode;

  Station({
    required this.stationUuid,
    required this.name,
    required this.urlResolved,
    this.lat,
    this.geoLong,
    this.country = '',
    this.countryCode = '',
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    final page = json['page'] ?? json;
    final urlPath = page['url'] as String? ?? '';
    final channelId = urlPath.split('/').last;
    
    final place = page['place'] as Map<String, dynamic>?;
    final countryObj = page['country'] as Map<String, dynamic>?;

    return Station(
      stationUuid: channelId,
      name: page['title'] ?? 'Unknown Station',
      urlResolved: 'https://radio.garden/api/ara/content/listen/$channelId/channel.mp3',
      lat: null,
      geoLong: null,
      country: place?['title'] ?? page['subtitle'] ?? '',
      countryCode: countryObj?['title'] ?? '',
    );
  }
}

class RadioGardenApi {
  final Dio _dio;
  final String _baseUrl = 'https://radio.garden/api';

  RadioGardenApi(this._dio);

  Future<List<Station>> getStationsInPlace(String placeId) async {
    try {
      final cachedStations = await StationDatabase.instance.getCachedStations(placeId);
      if (cachedStations != null && cachedStations.isNotEmpty) {
        print("Flutter: Serving ${cachedStations.length} stations from SQLite cache for $placeId");
        return cachedStations;
      }

      final response = await _dio.get('$_baseUrl/ara/content/page/$placeId');
      final data = response.data as Map<String, dynamic>;
      
      final contentList = data['data']['content'] as List<dynamic>? ?? [];
      final List<Station> stations = [];

      for (var block in contentList) {
        if (block is Map<String, dynamic> &&
            block['itemsType'] == 'channel' &&
            block['items'] != null) {
          final items = block['items'] as List<dynamic>;
          for (var item in items) {
            if (item is Map<String, dynamic>) {
              stations.add(Station.fromJson(item));
            }
          }
        }
      }
      
      if (stations.isNotEmpty) {
        await StationDatabase.instance.cacheStationsForPlace(placeId, stations);
      }
      return stations;
    } catch (e) {
      print("Error fetching Radio Garden stations for place $placeId: $e");
      return [];
    }
  }

  Future<List<Station>> searchStations(String query) async {
    try {
      final response = await _dio.get('$_baseUrl/search', queryParameters: {'q': query});
      final hits = response.data['hits']['hits'] as List<dynamic>? ?? [];
      final List<Station> results = [];
      for (var hit in hits) {
        final source = hit['_source'];
        if (source != null && source['type'] == 'channel') {
          results.add(Station.fromJson(source));
        }
      }
      return results;
    } catch (e) {
      print("Error searching Radio Garden stations: $e");
      return [];
    }
  }
}

final dioProvider = Provider((ref) {
  final dio = Dio();
  dio.options.headers = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
    'Origin': 'https://radio.garden',
    'Referer': 'https://radio.garden/',
  };
  return dio;
});

final radioGardenApiProvider = Provider((ref) {
  return RadioGardenApi(ref.watch(dioProvider));
});

class FavoritesNotifier extends Notifier<List<Station>> {
  @override
  List<Station> build() {
    _loadFavorites();
    return [];
  }

  Future<void> _loadFavorites() async {
    final favs = await StationDatabase.instance.getFavorites();
    state = favs;
  }

  Future<void> toggleFavorite(Station station) async {
    await StationDatabase.instance.toggleFavorite(station);
    await _loadFavorites();
  }

  bool isFavorite(String uuid) {
    return state.any((s) => s.stationUuid == uuid);
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, List<Station>>(() {
  return FavoritesNotifier();
});

final currentStationsProvider = StateProvider<List<Station>>((ref) => []);
final nearestStationProvider = StateProvider<Station?>((ref) => null);
final currentStationIndexProvider = StateProvider<int>((ref) => 0);
