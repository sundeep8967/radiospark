import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../stations/station_api.dart';
import '../audio/audio_provider.dart';
import '../ui/settings_screen.dart';
import 'globe_view.dart';

class Map2DView extends ConsumerStatefulWidget {
  const Map2DView({super.key});

  @override
  ConsumerState<Map2DView> createState() => _Map2DViewState();
}

class _Map2DViewState extends ConsumerState<Map2DView> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final stations = ref.watch(currentStationsProvider);
    final nearest = ref.watch(nearestStationProvider);
    final isDark = ref.watch(mapThemeProvider) == 'graphic';
    final centerMap = ref.watch(globeCenterProvider);
    
    final markers = stations.map((s) {
      final isNearest = s.stationUuid == nearest?.stationUuid;
      return Marker(
        point: LatLng(s.lat ?? 0.0, s.geoLong ?? 0.0),
        width: isNearest ? 24 : 12,
        height: isNearest ? 24 : 12,
        child: GestureDetector(
          onTap: () {
            ref.read(nearestStationProvider.notifier).state = s;
            ref.read(audioControllerProvider.notifier).playStream(s);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isNearest ? const Color(0xFF00E676) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
          ),
        ),
      );
    }).toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(centerMap['lat']!, centerMap['lng']!),
        initialZoom: 4.0,
      ),
      children: [
        TileLayer(
          urlTemplate: isDark 
            ? 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png'
            : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.ravana.radiostation',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
