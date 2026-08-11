import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'station_database.dart';

/// Station model — uuid, name, direct stream URL, and geo coordinates
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

  /// Parse directly from Radio Browser API JSON
  factory Station.fromRadioBrowserJson(Map<String, dynamic> json) {
    return Station(
      stationUuid: json['stationuuid'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Station',
      urlResolved: json['url_resolved'] as String? ?? json['url'] as String? ?? '',
      lat: _parseDouble(json['geo_lat']),
      geoLong: _parseDouble(json['geo_long']),
      country: json['state'] as String? ?? json['country'] as String? ?? '',
      countryCode: json['countrycode'] as String? ?? '',
    );
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

/// Radio Browser API — completely independent, no Radio.garden involved
class RadioBrowserApi {
  final Dio _dio;

  // Radio Browser has multiple community servers — pick a stable one
  static const _baseUrl = 'https://de1.api.radio-browser.info/json';

  RadioBrowserApi(this._dio);

  /// Fetch stations near a lat/lng point (radius in km)
  Future<List<Station>> getStationsByGeo(double lat, double lng, {int radiusKm = 100, int limit = 20}) async {
    try {
      // First check cache using a geo-based key
      final cacheKey = 'geo_${lat.toStringAsFixed(1)}_${lng.toStringAsFixed(1)}';
      final cached = await StationDatabase.instance.getCachedStations(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        print('RadioBrowser: Serving ${cached.length} stations from cache for $cacheKey');
        return cached;
      }

      final response = await _dio.get(
        '$_baseUrl/stations/search',
        queryParameters: {
          'limit': limit,
          'order': 'clickcount',
          'reverse': 'true',
          'hidebroken': 'true',
          'geo_lat': lat,
          'geo_long': lng,
          'geo_distance': radiusKm * 1000, // API expects meters
        },
      );

      final List<dynamic> data = response.data as List<dynamic>? ?? [];
      final stations = data
          .whereType<Map<String, dynamic>>()
          .where((j) => (j['url_resolved'] as String? ?? '').isNotEmpty)
          .map((j) => Station.fromRadioBrowserJson(j))
          .toList();

      if (stations.isNotEmpty) {
        await StationDatabase.instance.cacheStationsForPlace(cacheKey, stations);
      }
      print('RadioBrowser: Fetched ${stations.length} stations near ($lat, $lng)');
      return stations;
    } catch (e) {
      print('RadioBrowser: Error fetching by geo: $e');
      return [];
    }
  }

  /// Fetch top stations for a country code
  Future<List<Station>> getStationsByCountry(String countryCode, {int limit = 20}) async {
    try {
      final cacheKey = 'country_$countryCode';
      final cached = await StationDatabase.instance.getCachedStations(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }

      final response = await _dio.get(
        '$_baseUrl/stations/bycountrycodeexact/$countryCode',
        queryParameters: {
          'limit': limit,
          'order': 'clickcount',
          'reverse': 'true',
          'hidebroken': 'true',
        },
      );

      final List<dynamic> data = response.data as List<dynamic>? ?? [];
      final stations = data
          .whereType<Map<String, dynamic>>()
          .where((j) => (j['url_resolved'] as String? ?? '').isNotEmpty)
          .map((j) => Station.fromRadioBrowserJson(j))
          .toList();

      if (stations.isNotEmpty) {
        await StationDatabase.instance.cacheStationsForPlace(cacheKey, stations);
      }
      return stations;
    } catch (e) {
      print('RadioBrowser: Error fetching by country $countryCode: $e');
      return [];
    }
  }

  /// Search stations by name (global)
  Future<List<Station>> searchStations(String query) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/stations/search',
        queryParameters: {
          'name': query,
          'limit': 30,
          'order': 'clickcount',
          'reverse': 'true',
          'hidebroken': 'true',
        },
      );
      final List<dynamic> data = response.data as List<dynamic>? ?? [];
      return data
          .whereType<Map<String, dynamic>>()
          .where((j) => (j['url_resolved'] as String? ?? '').isNotEmpty)
          .map((j) => Station.fromRadioBrowserJson(j))
          .toList();
    } catch (e) {
      print('RadioBrowser: Error searching "$query": $e');
      return [];
    }
  }
}

final dioProvider = Provider((ref) {
  final dio = Dio();
  dio.options.headers = {
    'User-Agent': 'RadiosparkApp/1.0 (Android; contact@radiospark.app)',
  };
  dio.options.connectTimeout = const Duration(seconds: 10);
  dio.options.receiveTimeout = const Duration(seconds: 10);
  return dio;
});

final radioBrowserApiProvider = Provider((ref) {
  return RadioBrowserApi(ref.watch(dioProvider));
});

// Keep old name as alias so nothing else breaks
final radioGardenApiProvider = radioBrowserApiProvider;

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
