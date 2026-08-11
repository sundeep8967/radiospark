import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'station_api.dart';

class StationDatabase {
  static final StationDatabase instance = StationDatabase._init();
  static Database? _database;

  StationDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('stations_cache.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 2,        // bumped → wipes stale geo-based cache
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Clear all cached station data so stale geo/wrong-language results are gone
        await db.execute('DELETE FROM stations_cache');
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE stations_cache (
  place_id TEXT PRIMARY KEY,
  stations_json TEXT NOT NULL,
  timestamp INTEGER NOT NULL
)
''');

    await db.execute('''
CREATE TABLE favorites (
  stationUuid TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  urlResolved TEXT NOT NULL,
  lat REAL,
  geoLong REAL,
  country TEXT,
  countryCode TEXT,
  added_at INTEGER NOT NULL
)
''');
  }

  Future<void> cacheStationsForPlace(String placeId, List<Station> stations) async {
    final db = await instance.database;
    final stationsList = stations.map((s) => {
      'stationUuid': s.stationUuid,
      'name': s.name,
      'urlResolved': s.urlResolved,
      'lat': s.lat,
      'geoLong': s.geoLong,
      'country': s.country,
      'countryCode': s.countryCode,
    }).toList();

    await db.insert(
      'stations_cache',
      {
        'place_id': placeId,
        'stations_json': jsonEncode(stationsList),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Station>?> getCachedStations(String placeId) async {
    final db = await instance.database;

    final maps = await db.query(
      'stations_cache',
      columns: ['stations_json', 'timestamp'],
      where: 'place_id = ?',
      whereArgs: [placeId],
    );

    if (maps.isNotEmpty) {
      final timestamp = maps.first['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      // 7 days in milliseconds
      final sevenDays = 7 * 24 * 60 * 60 * 1000;

      if (now - timestamp < sevenDays) {
        final jsonStr = maps.first['stations_json'] as String;
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        return jsonList.map((json) => Station(
          stationUuid: json['stationUuid'],
          name: json['name'],
          urlResolved: json['urlResolved'],
          lat: json['lat'],
          geoLong: json['geoLong'],
          country: json['country'],
          countryCode: json['countryCode'],
        )).toList();
      } else {
        // Cache expired, delete it
        await db.delete(
          'stations_cache',
          where: 'place_id = ?',
          whereArgs: [placeId],
        );
      }
    }
    return null;
  }

  // Favorites
  Future<void> toggleFavorite(Station station) async {
    final db = await instance.database;
    final isFav = await isFavorite(station.stationUuid);

    if (isFav) {
      await db.delete(
        'favorites',
        where: 'stationUuid = ?',
        whereArgs: [station.stationUuid],
      );
    } else {
      await db.insert(
        'favorites',
        {
          'stationUuid': station.stationUuid,
          'name': station.name,
          'urlResolved': station.urlResolved,
          'lat': station.lat,
          'geoLong': station.geoLong,
          'country': station.country,
          'countryCode': station.countryCode,
          'added_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<bool> isFavorite(String stationUuid) async {
    final db = await instance.database;
    final maps = await db.query(
      'favorites',
      where: 'stationUuid = ?',
      whereArgs: [stationUuid],
    );
    return maps.isNotEmpty;
  }

  Future<List<Station>> getFavorites() async {
    final db = await instance.database;
    final maps = await db.query('favorites', orderBy: 'added_at DESC');

    return maps.map((json) => Station(
      stationUuid: json['stationUuid'] as String,
      name: json['name'] as String,
      urlResolved: json['urlResolved'] as String,
      lat: json['lat'] as double?,
      geoLong: json['geoLong'] as double?,
      country: json['country'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? '',
    )).toList();
  }
}
