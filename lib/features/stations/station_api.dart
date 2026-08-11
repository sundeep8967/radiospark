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
  };

  /// Determine Indian state language purely from GPS coordinates.
  /// Bounding boxes checked from most-specific to broadest (handles overlaps).
  /// Covers every Indian city — no city list needed.
  static String? indiaStateLanguage(double lat, double lng) {
    // ── South ──────────────────────────────────────────────────
    // Kerala (narrow coastal — check before KA/TN)
    if (lat >= 8.2 && lat <= 12.8 && lng >= 74.8 && lng <= 77.5) return 'malayalam';
    // Tamil Nadu (south-east coast)
    if (lat >= 8.0 && lat <= 13.5 && lng >= 77.5 && lng <= 80.4) return 'tamil';
    // Goa
    if (lat >= 14.9 && lat <= 15.8 && lng >= 73.7 && lng <= 74.4) return 'konkani';
    // Telangana (north of AP)
    if (lat >= 15.8 && lat <= 19.9 && lng >= 77.2 && lng <= 81.8) return 'telugu';
    // Andhra Pradesh (Rayalaseema & Coastal AP — lat 12.6 to 19.1, lng 76.8 to 84.7)
    if (lat >= 12.6 && lat <= 19.1 && lng >= 76.8 && lng <= 84.7) return 'telugu';
    // Karnataka (KA east border is ~lng 77.3, past that is AP/TN)
    if (lat >= 11.5 && lat <= 18.5 && lng >= 74.0 && lng <= 77.3) return 'kannada';

    // ── West ───────────────────────────────────────────────────
    // Gujarat
    if (lat >= 20.1 && lat <= 24.7 && lng >= 68.2 && lng <= 74.5) return 'gujarati';
    // Maharashtra
    if (lat >= 15.6 && lat <= 22.1 && lng >= 72.6 && lng <= 80.9) return 'marathi';

    // ── East ───────────────────────────────────────────────────
    // West Bengal
    if (lat >= 21.5 && lat <= 27.2 && lng >= 85.8 && lng <= 89.9) return 'bengali';
    // Odisha
    if (lat >= 17.8 && lat <= 22.6 && lng >= 81.3 && lng <= 87.5) return 'odia';
    // Assam
    if (lat >= 24.0 && lat <= 28.0 && lng >= 89.5 && lng <= 96.0) return 'assamese';

    // ── North ──────────────────────────────────────────────────
    // Punjab
    if (lat >= 29.5 && lat <= 32.5 && lng >= 73.9 && lng <= 76.9) return 'punjabi';
    // Haryana + Delhi
    if (lat >= 27.6 && lat <= 30.9 && lng >= 74.5 && lng <= 77.6) return 'hindi';
    // Rajasthan
    if (lat >= 23.0 && lat <= 30.2 && lng >= 69.5 && lng <= 78.3) return 'hindi';
    // UP, Bihar, Jharkhand, MP → all Hindi belt
    if (lat >= 21.0 && lat <= 30.5 && lng >= 77.0 && lng <= 88.0) return 'hindi';
    if (lat >= 21.0 && lat <= 26.9 && lng >= 74.0 && lng <= 82.8) return 'hindi';

    return null; // NEVER force Hindi — fallback to geo (50km nearby stations) if unclassified
  }

  /// Full world coordinate-based language detection.
  /// Uses bounding boxes per country + finer regional boxes for multi-lingual countries.
  static String? coordLanguage(double lat, double lng) {
    // India — state-level precision (already implemented)
    if (lat >= 8.0 && lat <= 37.0 && lng >= 68.0 && lng <= 97.5) {
      return indiaStateLanguage(lat, lng);
    }

    // ── East / SE Asia ──────────────────────────────────────────
    if (lat >= 30.0 && lat <= 45.6 && lng >= 129.0 && lng <= 145.5) return 'japanese';
    if (lat >= 33.0 && lat <= 38.7 && lng >= 125.5 && lng <= 130.0) return 'korean';
    if (lat >= 37.5 && lat <= 43.0 && lng >= 124.0 && lng <= 131.0) return 'korean';
    // China — Cantonese in Guangdong/HK, Mandarin elsewhere
    if (lat >= 21.0 && lat <= 24.5 && lng >= 109.0 && lng <= 117.5) return 'cantonese';
    if (lat >= 18.0 && lat <= 53.5 && lng >= 73.5 && lng <= 135.0) return 'chinese';
    if (lat >= 21.9 && lat <= 25.4 && lng >= 120.0 && lng <= 122.0) return 'chinese'; // Taiwan
    if (lat >= 8.0  && lat <= 21.5 && lng >= 102.0 && lng <= 110.0) return 'vietnamese';
    if (lat >= 5.5  && lat <= 21.5 && lng >= 97.5  && lng <= 105.7) return 'thai';
    if (lat >= 0.9  && lat <= 7.6  && lng >= 99.6  && lng <= 119.6) return 'malay';
    if (lat >= -8.5 && lat <= 5.9  && lng >= 95.0  && lng <= 141.0) return 'indonesian';
    if (lat >= 4.6  && lat <= 20.5 && lng >= 116.7 && lng <= 126.5) return 'filipino';
    if (lat >= 5.9  && lat <= 13.9 && lng >= 99.6  && lng <= 105.7) return 'khmer';
    if (lat >= 13.9 && lat <= 22.5 && lng >= 100.1 && lng <= 107.7) return 'lao';
    if (lat >= 9.5  && lat <= 28.5 && lng >= 92.0  && lng <= 101.2) return 'burmese';
    if (lat >= 26.5 && lat <= 30.5 && lng >= 80.0  && lng <= 88.2)  return 'nepali';
    if (lat >= 5.9  && lat <= 9.9  && lng >= 79.7  && lng <= 81.9)  return 'sinhala';

    // ── Central Asia / Middle East ──────────────────────────────
    if (lat >= 38.0 && lat <= 51.0 && lng >= 51.0 && lng <= 87.0)  return 'kazakh';
    if (lat >= 37.0 && lat <= 41.5 && lng >= 60.0 && lng <= 73.5)  return 'uzbek';
    if (lat >= 36.5 && lat <= 42.0 && lng >= 44.0 && lng <= 50.5)  return 'azerbaijani';
    if (lat >= 35.0 && lat <= 42.0 && lng >= 44.0 && lng <= 63.5)  return 'persian';
    if (lat >= 29.5 && lat <= 38.2 && lng >= 60.5 && lng <= 75.0)  return 'urdu';
    if (lat >= 35.8 && lat <= 42.1 && lng >= 26.0 && lng <= 44.8)  return 'turkish';
    if (lat >= 29.5 && lat <= 33.3 && lng >= 34.2 && lng <= 35.9)  return 'hebrew';
    // Arabic belt (Middle East + North Africa)
    if (lat >= 8.0 && lat <= 37.5 && lng >= -5.5 && lng <= 60.0)   return 'arabic';

    // ── Africa ──────────────────────────────────────────────────
    if (lat >= -11.7 && lat <= 4.2  && lng >= 29.5 && lng <= 41.9) return 'swahili';
    if (lat >= 3.4   && lat <= 15.0 && lng >= 33.0 && lng <= 48.0) return 'amharic';
    if (lat >= 1.5   && lat <= 12.0 && lng >= 40.5 && lng <= 51.5) return 'somali';
    if (lat >= -18.0 && lat <= -5.0 && lng >= 11.5 && lng <= 21.0) return 'portuguese'; // Angola
    if (lat >= -26.9 && lat <= -10.5 && lng >= 30.2 && lng <= 40.9) return 'portuguese'; // Mozambique
    if (lat >= -35.0 && lat <= 5.0 && lng >= -18.0 && lng <= 24.0) return 'french'; // W Africa
    if (lat >= -35.0 && lat <= 5.0 && lng >= 24.0  && lng <= 52.0) return 'english'; // E/S Africa

    // ── Europe ──────────────────────────────────────────────────
    if (lat >= 35.0 && lat <= 71.2 && lng >= -10.0 && lng <= 40.0) {
      // UK & Ireland
      if (lat >= 49.9 && lat <= 58.7 && lng >= -8.2  && lng <= 1.8)  return 'english';
      if (lat >= 51.4 && lat <= 55.4 && lng >= -10.5 && lng <= -6.0) return 'english';
      // Scandinavia
      if (lat >= 55.3 && lat <= 57.8 && lng >= 8.0  && lng <= 15.2) return 'danish';
      if (lat >= 57.0 && lat <= 71.2 && lng >= 4.5  && lng <= 15.5) return 'norwegian';
      if (lat >= 55.3 && lat <= 69.1 && lng >= 11.1 && lng <= 24.2) return 'swedish';
      if (lat >= 59.8 && lat <= 70.1 && lng >= 20.5 && lng <= 31.6) return 'finnish';
      // Baltic
      if (lat >= 55.7 && lat <= 57.9 && lng >= 21.0 && lng <= 28.2) return 'latvian';
      if (lat >= 53.9 && lat <= 56.5 && lng >= 20.9 && lng <= 26.8) return 'lithuanian';
      if (lat >= 57.5 && lat <= 59.7 && lng >= 21.8 && lng <= 28.2) return 'estonian';
      // Germany
      if (lat >= 47.3 && lat <= 55.1 && lng >= 6.0  && lng <= 15.0) return 'german';
      // Austria
      if (lat >= 46.4 && lat <= 49.0 && lng >= 9.5  && lng <= 17.2) return 'german';
      // Switzerland (multi-lingual)
      if (lat >= 45.8 && lat <= 47.8 && lng >= 6.0 && lng <= 10.5) {
        if (lat < 46.5 && lng > 8.5) return 'italian';
        if (lng < 7.5) return 'french';
        return 'german';
      }
      // Belgium (multi-lingual)
      if (lat >= 49.5 && lat <= 51.5 && lng >= 2.5 && lng <= 6.4) {
        return lat >= 50.5 ? 'dutch' : 'french';
      }
      // Netherlands
      if (lat >= 50.8 && lat <= 53.6 && lng >= 3.4 && lng <= 7.2) return 'dutch';
      // France
      if (lat >= 41.3 && lat <= 51.1 && lng >= -5.1 && lng <= 8.2) return 'french';
      // Portugal
      if (lat >= 36.0 && lat <= 42.2 && lng >= -9.5 && lng <= -6.2) return 'portuguese';
      // Spain
      if (lat >= 35.9 && lat <= 43.8 && lng >= -9.3 && lng <= 3.3) return 'spanish';
      // Italy
      if (lat >= 35.5 && lat <= 47.1 && lng >= 6.6  && lng <= 18.5) return 'italian';
      // Poland
      if (lat >= 48.5 && lat <= 54.9 && lng >= 14.1 && lng <= 24.2) return 'polish';
      // Czech
      if (lat >= 48.5 && lat <= 51.1 && lng >= 12.1 && lng <= 18.9) return 'czech';
      // Slovakia
      if (lat >= 47.7 && lat <= 49.6 && lng >= 16.9 && lng <= 22.6) return 'slovak';
      // Hungary
      if (lat >= 45.7 && lat <= 48.6 && lng >= 16.1 && lng <= 22.9) return 'hungarian';
      // Romania
      if (lat >= 43.6 && lat <= 48.3 && lng >= 22.0 && lng <= 30.0) return 'romanian';
      // Bulgaria
      if (lat >= 41.2 && lat <= 44.2 && lng >= 22.4 && lng <= 28.6) return 'bulgarian';
      // Serbia
      if (lat >= 42.2 && lat <= 46.2 && lng >= 19.0 && lng <= 23.0) return 'serbian';
      // Croatia
      if (lat >= 42.4 && lat <= 46.6 && lng >= 13.5 && lng <= 19.5) return 'croatian';
      // Bosnia
      if (lat >= 42.5 && lat <= 45.3 && lng >= 15.7 && lng <= 19.7) return 'bosnian';
      // Albania
      if (lat >= 39.6 && lat <= 42.7 && lng >= 19.3 && lng <= 21.1) return 'albanian';
      // North Macedonia
      if (lat >= 40.9 && lat <= 42.4 && lng >= 20.5 && lng <= 22.7) return 'macedonian';
      // Slovenia
      if (lat >= 45.4 && lat <= 46.9 && lng >= 13.4 && lng <= 16.6) return 'slovenian';
      // Greece
      if (lat >= 35.0 && lat <= 41.8 && lng >= 19.4 && lng <= 29.7) return 'greek';
      // Ukraine
      if (lat >= 44.0 && lat <= 52.4 && lng >= 22.1 && lng <= 40.2) return 'ukrainian';
      // Belarus
      if (lat >= 51.3 && lat <= 53.7 && lng >= 23.2 && lng <= 32.8) return 'belarusian';
      // Russia (European part)
      if (lat >= 44.0 && lat <= 71.2 && lng >= 28.0 && lng <= 40.0) return 'russian';
    }

    // Russia (vast — Asia)
    if (lat >= 41.2 && lat <= 81.0 && lng >= 28.0 && lng <= 190.0) return 'russian';

    // ── Americas ────────────────────────────────────────────────
    // Canada — Quebec French, rest English
    if (lat >= 42.0 && lat <= 83.0 && lng >= -141.0 && lng <= -52.0) {
      if (lat >= 45.0 && lat <= 62.6 && lng >= -79.8 && lng <= -57.0) return 'french';
      return 'english';
    }
    // USA
    if (lat >= 24.0 && lat <= 49.5 && lng >= -125.0 && lng <= -66.9) return 'english';
    if (lat >= 18.0 && lat <= 22.2 && lng >= -160.3 && lng <= -154.8) return 'english'; // Hawaii
    if (lat >= 57.0 && lat <= 71.4 && lng >= -168.0 && lng <= -141.0) return 'english'; // Alaska
    // Haiti
    if (lat >= 17.6 && lat <= 20.1 && lng >= -74.5 && lng <= -71.6) return 'french';
    // Cuba, DR → Spanish
    if (lat >= 19.8 && lat <= 23.3 && lng >= -85.0 && lng <= -74.1) return 'spanish';
    if (lat >= 17.4 && lat <= 20.0 && lng >= -72.0 && lng <= -68.3) return 'spanish';
    // Caribbean default
    if (lat >= 10.0 && lat <= 27.0 && lng >= -90.0 && lng <= -59.0) return 'english';
    // Mexico + Central America
    if (lat >= 7.5 && lat <= 32.7 && lng >= -118.4 && lng <= -77.0) return 'spanish';
    // Brazil
    if (lat >= -34.0 && lat <= 5.3 && lng >= -73.5 && lng <= -34.8) return 'portuguese';
    // Rest of South America
    if (lat >= -56.0 && lat <= 13.0 && lng >= -81.0 && lng <= -34.0) return 'spanish';

    // ── Oceania ─────────────────────────────────────────────────
    if (lat >= -44.0 && lat <= -10.0 && lng >= 113.0 && lng <= 154.0) return 'english'; // Australia
    if (lat >= -47.0 && lat <= -34.0 && lng >= 166.0 && lng <= 178.0) return 'english'; // NZ
    if (lat >= -9.0  && lat <= -1.0  && lng >= 141.0 && lng <= 156.0) return 'english'; // PNG

    return null;
  }

  /// Resolve the best language for a globe snap — purely by coordinates.
  /// City name only used as a fast-path override for known major cities.
  static String? resolveLanguage(
      String placeTitle, String countryName, double lat, double lng) {
    // 1. City-level lookup (fast path for explicitly mapped cities)
    final cityLang = regionToLanguage(placeTitle);
    if (cityLang != null && !_broadLanguages.contains(cityLang)) return cityLang;

    // 2. Full coordinate-based world detection
    final geoLang = coordLanguage(lat, lng);
    if (geoLang != null && !_broadLanguages.contains(geoLang)) return geoLang;

    // 3. Broad/unknown → caller uses geo + country search
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
