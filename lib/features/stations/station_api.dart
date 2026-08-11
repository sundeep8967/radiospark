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


  /// Exact city name → primary language lookup
  /// Covers every major Radio.garden place in India
  static const _cityLanguage = <String, String>{
    // ── Karnataka ──────────────────────────────────────────────
    'bengaluru': 'kannada', 'bangalore': 'kannada',
    'mysuru': 'kannada',    'mysore': 'kannada',
    'hubli': 'kannada',     'hubballi': 'kannada',
    'dharwad': 'kannada',
    'mangaluru': 'kannada', 'mangalore': 'kannada',
    'belgaum': 'kannada',   'belagavi': 'kannada',
    'shimoga': 'kannada',   'shivamogga': 'kannada',
    'tumkur': 'kannada',    'tumakuru': 'kannada',
    'davanagere': 'kannada','davangere': 'kannada',
    'bellary': 'kannada',   'ballari': 'kannada',
    'bidar': 'kannada',
    'kolar': 'kannada',
    'mandya': 'kannada',
    'hassan': 'kannada',
    'udupi': 'kannada',
    'chikmagalur': 'kannada', 'chikkamagaluru': 'kannada',
    'hospet': 'kannada',    'hosapete': 'kannada',
    'chitradurga': 'kannada',
    'bagalkot': 'kannada',
    'gadag': 'kannada',
    'raichur': 'kannada',
    'bijapur': 'kannada',   'vijayapura': 'kannada',
    'gulbarga': 'kannada',  'kalaburagi': 'kannada',
    'koppal': 'kannada',
    'yadgir': 'kannada',

    // ── Tamil Nadu ─────────────────────────────────────────────
    'chennai': 'tamil',     'madras': 'tamil',
    'coimbatore': 'tamil',
    'madurai': 'tamil',
    'tiruchirappalli': 'tamil', 'trichy': 'tamil',
    'salem': 'tamil',
    'tirunelveli': 'tamil',
    'vellore': 'tamil',
    'erode': 'tamil',
    'tiruppur': 'tamil',    'tirupur': 'tamil',
    'thoothukudi': 'tamil', 'tuticorin': 'tamil',
    'thanjavur': 'tamil',
    'kanchipuram': 'tamil',
    'kumbakonam': 'tamil',
    'cuddalore': 'tamil',
    'dindigul': 'tamil',
    'nagercoil': 'tamil',
    'pudukkottai': 'tamil',
    'sivakasi': 'tamil',
    'karur': 'tamil',
    'namakkal': 'tamil',
    'dharmapuri': 'tamil',
    'krishnagiri': 'tamil',
    'villupuram': 'tamil',
    'virudhunagar': 'tamil',

    // ── Andhra Pradesh ─────────────────────────────────────────
    'vijayawada': 'telugu',
    'visakhapatnam': 'telugu', 'vizag': 'telugu',
    'tirupati': 'telugu',
    'guntur': 'telugu',
    'nellore': 'telugu',    'nelluru': 'telugu',
    'kurnool': 'telugu',
    'rajahmundry': 'telugu','rajamahendravaram': 'telugu',
    'kakinada': 'telugu',
    'eluru': 'telugu',
    'ongole': 'telugu',
    'anantapur': 'telugu',  'anantapuramu': 'telugu',
    'kadapa': 'telugu',     'cuddapah': 'telugu',
    'chittoor': 'telugu',
    'srikakulam': 'telugu',
    'vizianagaram': 'telugu',
    'bhimavaram': 'telugu',
    'machilipatnam': 'telugu',
    'puttaparthi': 'telugu',
    'hindupur': 'telugu',
    'proddatur': 'telugu',
    'nandyal': 'telugu',
    'tadepalligudem': 'telugu',
    'tenali': 'telugu',
    'bapatla': 'telugu',
    'narasaraopet': 'telugu',
    'chilakaluripet': 'telugu',
    'gudivada': 'telugu',
    'kavali': 'telugu',
    'madanapalle': 'telugu',
    'tadipatri': 'telugu',
    'dhone': 'telugu',
    'adoni': 'telugu',
    'guntakal': 'telugu',
    'narasapuram': 'telugu',
    'palasa': 'telugu',
    'srikalahasti': 'telugu',
    'puttur': 'telugu',

    // ── Telangana ──────────────────────────────────────────────
    'hyderabad': 'telugu',  'secunderabad': 'telugu',
    'warangal': 'telugu',
    'karimnagar': 'telugu',
    'nizamabad': 'telugu',
    'khammam': 'telugu',
    'mahbubnagar': 'telugu','mahabubnagar': 'telugu',
    'nalgonda': 'telugu',
    'adilabad': 'telugu',
    'medak': 'telugu',
    'rangareddy': 'telugu',

    // ── Kerala ─────────────────────────────────────────────────
    'kochi': 'malayalam',   'cochin': 'malayalam',
    'thiruvananthapuram': 'malayalam', 'trivandrum': 'malayalam',
    'kozhikode': 'malayalam', 'calicut': 'malayalam',
    'thrissur': 'malayalam','trichur': 'malayalam',
    'kollam': 'malayalam',  'quilon': 'malayalam',
    'kannur': 'malayalam',  'cannanore': 'malayalam',
    'palakkad': 'malayalam','palghat': 'malayalam',
    'alappuzha': 'malayalam','alleppey': 'malayalam',
    'malappuram': 'malayalam',
    'kottayam': 'malayalam',
    'idukki': 'malayalam',
    'ernakulam': 'malayalam',
    'pathanamthitta': 'malayalam',
    'kasaragod': 'malayalam',
    'wayanad': 'malayalam',

    // ── Maharashtra ────────────────────────────────────────────
    'mumbai': 'marathi',    'bombay': 'marathi',
    'pune': 'marathi',      'poona': 'marathi',
    'nagpur': 'marathi',
    'nashik': 'marathi',
    'aurangabad': 'marathi','chhatrapati sambhajinagar': 'marathi',
    'solapur': 'marathi',
    'kolhapur': 'marathi',
    'thane': 'marathi',
    'navi mumbai': 'marathi',
    'amravati': 'marathi',
    'akola': 'marathi',
    'latur': 'marathi',
    'jalgaon': 'marathi',
    'nanded': 'marathi',
    'satara': 'marathi',
    'sangli': 'marathi',
    'ahmednagar': 'marathi',
    'bid': 'marathi',       'beed': 'marathi',
    'osmanabad': 'marathi', 'dharashiv': 'marathi',

    // ── Gujarat ────────────────────────────────────────────────
    'ahmedabad': 'gujarati','amdavad': 'gujarati',
    'surat': 'gujarati',
    'vadodara': 'gujarati', 'baroda': 'gujarati',
    'rajkot': 'gujarati',
    'gandhinagar': 'gujarati',
    'bhavnagar': 'gujarati',
    'jamnagar': 'gujarati',
    'junagadh': 'gujarati',
    'anand': 'gujarati',
    'nadiad': 'gujarati',
    'bharuch': 'gujarati',
    'morbi': 'gujarati',
    'mehsana': 'gujarati',
    'surendranagar': 'gujarati',
    'porbandar': 'gujarati',

    // ── Punjab ─────────────────────────────────────────────────
    'amritsar': 'punjabi',
    'ludhiana': 'punjabi',
    'chandigarh': 'punjabi',
    'jalandhar': 'punjabi',
    'patiala': 'punjabi',
    'bathinda': 'punjabi',
    'mohali': 'punjabi',
    'pathankot': 'punjabi',
    'hoshiarpur': 'punjabi',
    'gurdaspur': 'punjabi',

    // ── West Bengal ────────────────────────────────────────────
    'kolkata': 'bengali',   'calcutta': 'bengali',
    'howrah': 'bengali',
    'durgapur': 'bengali',
    'asansol': 'bengali',
    'siliguri': 'bengali',
    'bardhaman': 'bengali', 'burdwan': 'bengali',
    'malda': 'bengali',
    'jalpaiguri': 'bengali',
    'kharagpur': 'bengali',
    'haldia': 'bengali',

    // ── Rajasthan ──────────────────────────────────────────────
    'jaipur': 'hindi',
    'jodhpur': 'hindi',
    'udaipur': 'hindi',
    'kota': 'hindi',
    'ajmer': 'hindi',
    'bikaner': 'hindi',
    'alwar': 'hindi',
    'bharatpur': 'hindi',
    'sikar': 'hindi',

    // ── Uttar Pradesh ──────────────────────────────────────────
    'lucknow': 'hindi',
    'kanpur': 'hindi',      'cawnpore': 'hindi',
    'agra': 'hindi',
    'varanasi': 'hindi',    'banaras': 'hindi',
    'allahabad': 'hindi',   'prayagraj': 'hindi',
    'meerut': 'hindi',
    'ghaziabad': 'hindi',
    'noida': 'hindi',
    'mathura': 'hindi',
    'aligarh': 'hindi',
    'bareilly': 'hindi',
    'moradabad': 'hindi',
    'gorakhpur': 'hindi',
    'firozabad': 'hindi',
    'saharanpur': 'hindi',

    // ── Delhi / NCR ────────────────────────────────────────────
    'delhi': 'hindi',       'new delhi': 'hindi',
    'gurgaon': 'hindi',     'gurugram': 'hindi',
    'faridabad': 'hindi',

    // ── Madhya Pradesh ─────────────────────────────────────────
    'bhopal': 'hindi',
    'indore': 'hindi',
    'jabalpur': 'hindi',
    'gwalior': 'hindi',
    'ujjain': 'hindi',
    'sagar': 'hindi',
    'rewa': 'hindi',
    'satna': 'hindi',

    // ── Bihar ──────────────────────────────────────────────────
    'patna': 'hindi',
    'gaya': 'hindi',
    'bhagalpur': 'hindi',
    'muzaffarpur': 'hindi',

    // ── Haryana ────────────────────────────────────────────────
    'ambala': 'hindi',
    'karnal': 'hindi',
    'rohtak': 'hindi',
    'hisar': 'hindi',
    'panipat': 'hindi',

    // ── Odisha ─────────────────────────────────────────────────
    'bhubaneswar': 'odia',  'bhubaneshwar': 'odia',
    'cuttack': 'odia',
    'rourkela': 'odia',
    'berhampur': 'odia',
    'sambalpur': 'odia',

    // ── Assam ──────────────────────────────────────────────────
    'guwahati': 'assamese', 'gauhati': 'assamese',
    'dibrugarh': 'assamese',
    'silchar': 'assamese',
    'jorhat': 'assamese',
  };

  /// Guess primary language from place title — exact lookup first, then substring
  static String? regionToLanguage(String placeTitle) {
    final t = placeTitle.trim().toLowerCase();
    // Exact match first (most reliable)
    if (_cityLanguage.containsKey(t)) return _cityLanguage[t];
    // Word-boundary match (e.g. "Greater Bangalore" → kannada)
    for (final entry in _cityLanguage.entries) {
      if (t.contains(entry.key)) return entry.value;
    }
    return null;
  }

  /// Country name → primary language (Radio Browser language tag)
  static const _countryLanguage = <String, String>{
    // ── Europe ──────────────────────────────────────────────────
    'albania': 'albanian',
    'andorra': 'catalan',
    'armenia': 'armenian',
    'austria': 'german',
    'azerbaijan': 'azerbaijani',
    'belarus': 'belarusian',
    'belgium': 'dutch',
    'bosnia and herzegovina': 'bosnian',
    'bulgaria': 'bulgarian',
    'croatia': 'croatian',
    'cyprus': 'greek',
    'czech republic': 'czech', 'czechia': 'czech',
    'denmark': 'danish',
    'estonia': 'estonian',
    'finland': 'finnish',
    'france': 'french',
    'georgia': 'georgian',
    'germany': 'german',
    'greece': 'greek',
    'hungary': 'hungarian',
    'iceland': 'icelandic',
    'ireland': 'english',
    'italy': 'italian',
    'kazakhstan': 'kazakh',
    'kosovo': 'albanian',
    'latvia': 'latvian',
    'liechtenstein': 'german',
    'lithuania': 'lithuanian',
    'luxembourg': 'french',
    'malta': 'maltese',
    'moldova': 'romanian',
    'monaco': 'french',
    'montenegro': 'serbian',
    'netherlands': 'dutch',
    'north macedonia': 'macedonian',
    'norway': 'norwegian',
    'poland': 'polish',
    'portugal': 'portuguese',
    'romania': 'romanian',
    'russia': 'russian',
    'san marino': 'italian',
    'serbia': 'serbian',
    'slovakia': 'slovak',
    'slovenia': 'slovenian',
    'spain': 'spanish',
    'sweden': 'swedish',
    'switzerland': 'german',
    'ukraine': 'ukrainian',
    'united kingdom': 'english',
    'vatican city': 'italian',

    // ── Americas ────────────────────────────────────────────────
    'argentina': 'spanish',
    'belize': 'english',
    'bolivia': 'spanish',
    'brazil': 'portuguese',
    'canada': 'english',
    'chile': 'spanish',
    'colombia': 'spanish',
    'costa rica': 'spanish',
    'cuba': 'spanish',
    'dominican republic': 'spanish',
    'ecuador': 'spanish',
    'el salvador': 'spanish',
    'guatemala': 'spanish',
    'haiti': 'french',
    'honduras': 'spanish',
    'jamaica': 'english',
    'mexico': 'spanish',
    'nicaragua': 'spanish',
    'panama': 'spanish',
    'paraguay': 'spanish',
    'peru': 'spanish',
    'puerto rico': 'spanish',
    'trinidad and tobago': 'english',
    'united states': 'english',
    'uruguay': 'spanish',
    'venezuela': 'spanish',

    // ── Middle East ─────────────────────────────────────────────
    'bahrain': 'arabic',
    'egypt': 'arabic',
    'iran': 'persian',
    'iraq': 'arabic',
    'israel': 'hebrew',
    'jordan': 'arabic',
    'kuwait': 'arabic',
    'lebanon': 'arabic',
    'libya': 'arabic',
    'oman': 'arabic',
    'palestine': 'arabic',
    'qatar': 'arabic',
    'saudi arabia': 'arabic',
    'syria': 'arabic',
    'turkey': 'turkish',
    'united arab emirates': 'arabic',
    'yemen': 'arabic',

    // ── Africa ──────────────────────────────────────────────────
    'algeria': 'arabic',
    'angola': 'portuguese',
    'cameroon': 'french',
    'democratic republic of the congo': 'french',
    'ethiopia': 'amharic',
    'ghana': 'english',
    'ivory coast': 'french', "côte d'ivoire": 'french',
    'kenya': 'english',
    'madagascar': 'malagasy',
    'mali': 'french',
    'morocco': 'arabic',
    'mozambique': 'portuguese',
    'nigeria': 'english',
    'senegal': 'french',
    'somalia': 'somali',
    'south africa': 'english',
    'sudan': 'arabic',
    'tanzania': 'swahili',
    'tunisia': 'arabic',
    'uganda': 'english',
    'zimbabwe': 'english',

    // ── Asia ────────────────────────────────────────────────────
    'afghanistan': 'pashto',
    'bangladesh': 'bengali',
    'cambodia': 'khmer',
    'china': 'chinese',
    'hong kong': 'chinese',
    'indonesia': 'indonesian',
    'india': 'hindi',         // NOT used — removed so unknown Indian cities use geo
    // ↑ INTENTIONALLY keeping key but routing to broad so resolveLanguage returns null
    // Unknown Indian cities fall to tight geo (50km) in globe_view.dart
    'japan': 'japanese',
    'laos': 'lao',
    'malaysia': 'malay',
    'maldives': 'dhivehi',
    'mongolia': 'mongolian',
    'myanmar': 'burmese',
    'nepal': 'nepali',
    'north korea': 'korean',
    'pakistan': 'urdu',
    'philippines': 'filipino',
    'singapore': 'english',
    'south korea': 'korean',
    'sri lanka': 'sinhala',
    'taiwan': 'chinese',
    'thailand': 'thai',
    'uzbekistan': 'uzbek',
    'vietnam': 'vietnamese',

    'australia': 'english',
    'fiji': 'english',
    'new zealand': 'english',
    'papua new guinea': 'english',
  };

  /// Get primary language for a given country name (from Radio.garden place data)
  static String? countryToLanguage(String countryName) {
    final t = countryName.trim().toLowerCase();
    return _countryLanguage[t];
  }

  /// Languages shared across many countries — too broad for language-search.
  /// These fall back to geo + country-name search for local relevance.
  static const _broadLanguages = {
    'english',    // US, UK, AU, CA, NZ, IE, SG, ZA...
    'spanish',    // ES, MX, AR, CO, CL, PE, VE...
    'arabic',     // SA, EG, AE, IQ, JO, KW, QA...
    'portuguese', // BR + PT + MZ + AO
    'french',     // FR + BE + CH + CA (Quebec) + African francophone
    'hindi',      // India country-level default — too broad, use geo instead
  };

  /// Resolve language for a place:
  ///  - Indian cities → state-specific language (kannada, telugu, etc.)
  ///  - Country-specific language (japanese, german, etc.) → use that language
  ///  - Broad/shared language (english, spanish, arabic...) → return null so
  ///    caller uses geo + country search for local relevance
  static String? resolveLanguage(String placeTitle, String countryName) {
    // 1. City-level match (India sub-state precision)
    final cityLang = regionToLanguage(placeTitle);
    if (cityLang != null && !_broadLanguages.contains(cityLang)) return cityLang;

    // 2. Country-level match
    final countryLang = countryToLanguage(countryName);
    if (countryLang != null && !_broadLanguages.contains(countryLang)) return countryLang;

    // 3. Broad language or unknown → caller uses geo + country
    return null;
  }

  /// Fetch stations near a lat/lng point with optional language filter
  Future<List<Station>> getStationsByGeo(
    double lat,
    double lng, {
    int radiusKm = 60,   // tight radius avoids crossing state borders
    int limit = 20,
    String? language,    // e.g. 'kannada', 'telugu'
  }) async {
    try {
      final langKey = language != null ? '_${language}' : '';
      final cacheKey = 'geo_${lat.toStringAsFixed(1)}_${lng.toStringAsFixed(1)}$langKey';
      final cached = await StationDatabase.instance.getCachedStations(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        print('RadioBrowser: Cache hit $cacheKey (${cached.length} stations)');
        return cached;
      }

      final params = <String, dynamic>{
        'limit': limit,
        'order': 'clickcount',
        'reverse': 'true',
        'hidebroken': 'true',
        'geo_lat': lat,
        'geo_long': lng,
        'geo_distance': radiusKm * 1000,
      };
      if (language != null) params['language'] = language;

      final response = await _dio.get('$_baseUrl/stations/search', queryParameters: params);

      final List<dynamic> data = response.data as List<dynamic>? ?? [];
      final stations = data
          .whereType<Map<String, dynamic>>()
          .where((j) => (j['url_resolved'] as String? ?? '').isNotEmpty)
          .map((j) => Station.fromRadioBrowserJson(j))
          .toList();

      if (stations.isNotEmpty) {
        await StationDatabase.instance.cacheStationsForPlace(cacheKey, stations);
      }
      print('RadioBrowser: ${stations.length} stations within ${radiusKm}km of ($lat,$lng)'
          '${language != null ? " [$language]" : ""}');
      return stations;
    } catch (e) {
      print('RadioBrowser: Error fetching by geo: $e');
      return [];
    }
  }

  /// Fetch top stations by language globally
  Future<List<Station>> getStationsByLanguage(String language, {int limit = 20}) async {
    try {
      final cacheKey = 'lang_$language';
      final cached = await StationDatabase.instance.getCachedStations(cacheKey);
      if (cached != null && cached.isNotEmpty) return cached;

      final response = await _dio.get(
        '$_baseUrl/stations/bylanguageexact/$language',
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
      print('RadioBrowser: Error fetching by language $language: $e');
      return [];
    }
  }


  /// Fetch top stations by full country name (e.g. "India", "France", "Germany")
  /// Uses Radio Browser's /stations/bycountry/{name} which accepts the full name
  Future<List<Station>> getStationsByCountry(String countryName, {int limit = 20}) async {
    if (countryName.isEmpty) return [];
    try {
      // Encode for URL (e.g. "United States" → "United%20States")
      final encoded = Uri.encodeComponent(countryName.toLowerCase());
      final cacheKey = 'country_${countryName.toLowerCase().replaceAll(' ', '_')}';
      final cached = await StationDatabase.instance.getCachedStations(cacheKey);
      if (cached != null && cached.isNotEmpty) return cached;

      final response = await _dio.get(
        '$_baseUrl/stations/bycountry/$encoded',
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
      print('RadioBrowser: ${stations.length} stations for country "$countryName"');
      return stations;
    } catch (e) {
      print('RadioBrowser: Error fetching by country "$countryName": $e');
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
