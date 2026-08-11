import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../stations/station_api.dart';
import '../audio/audio_provider.dart';
import '../ui/settings_screen.dart';
import 'crosshair.dart';

final globeCenterProvider = StateProvider<Map<String, double>>((ref) => {'lat': 52.3676, 'lng': 4.9041});
final selectedPlaceProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

class GlobeView extends ConsumerStatefulWidget {
  const GlobeView({super.key});

  @override
  ConsumerState<GlobeView> createState() => _GlobeViewState();
}

class _GlobeViewState extends ConsumerState<GlobeView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'GlobeChannel',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = jsonDecode(message.message) as Map<String, dynamic>;
            final type = data['type'] as String?;

            if (type == 'haptic_tick') {
              HapticFeedback.selectionClick();
            } else if (type == 'place_selected') {
              final id = data['id'] as String;
              final title = data['title'] as String;
              final country = data['country'] as String;
              final lat = (data['lat'] as num).toDouble();
              final lng = (data['lng'] as num).toDouble();

              print("Flutter: Snapped to place: $title, $country ($id)");

              ref.read(globeCenterProvider.notifier).state = {'lat': lat, 'lng': lng};
              ref.read(selectedPlaceProvider.notifier).state = {
                'id': id,
                'title': title,
                'country': country,
              };
            } else if (type == 'stations_loaded') {
              final rawStations = data['stations'] as List<dynamic>;
              print("Flutter: Stations loaded from WebView: ${rawStations.length} stations");
              final List<Station> stations = rawStations.map((item) {
                return Station(
                  stationUuid: item['id'] as String,
                  name: item['title'] as String,
                  urlResolved: item['url'] as String,
                  country: item['city'] as String,
                  countryCode: item['country'] as String,
                );
              }).toList();

              ref.read(currentStationsProvider.notifier).state = stations;
              ref.read(currentStationIndexProvider.notifier).state = 0;

              if (stations.isNotEmpty) {
                final firstStation = stations.first;
                ref.read(nearestStationProvider.notifier).state = firstStation;
                print("Flutter: Playing first station: ${firstStation.name} (${firstStation.urlResolved})");
                ref.read(audioControllerProvider.notifier).playStream(firstStation);
              } else {
                ref.read(nearestStationProvider.notifier).state = null;
              }
            } else if (type == 'fetch_error') {
              print("Flutter: WebView API fetch error: ${data['error']}");
            } else {
              final lat = (data['lat'] as num).toDouble();
              final lng = (data['lng'] as num).toDouble();
              ref.read(globeCenterProvider.notifier).state = {'lat': lat, 'lng': lng};
            }
          } catch (e) {
            debugPrint("Error parsing globe channel message: $e");
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print("Flutter: WebView started loading: $url");
          },
          onPageFinished: (String url) {
            print("Flutter: WebView finished loading: $url");
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print("Flutter: WebView resource error: ${error.description}, code: ${error.errorCode}, type: ${error.errorType}");
          },
        ),
      );

    _loadLocalHtml();
  }

  Future<void> _loadLocalHtml() async {
    try {
      print("Flutter: Loading local HTML asset and places JSON...");
      final htmlString = await rootBundle.loadString('assets/globe.html');
      final jsonStr = await rootBundle.loadString('assets/places.json');
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final list = decoded['data']['list'] as List<dynamic>;
      final listStr = jsonEncode(list);

      final finalHtml = htmlString.replaceFirst('%PLACES_JSON%', listStr);
      print("Flutter: HTML template injected. Total string size: ${finalHtml.length} characters.");

      await _controller.loadHtmlString(finalHtml, baseUrl: 'https://radio.garden');
      print("Flutter: loadHtmlString completed with baseUrl: https://radio.garden");
    } catch (e, stack) {
      print("Flutter: Error loading local HTML asset: $e\n$stack");
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(mapThemeProvider, (previous, next) {
      if (previous != next) {
        _controller.runJavaScript("setTheme('$next');");
      }
    });

    return Stack(
      children: [
        WebViewWidget(
          controller: _controller,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
        ),
        const IgnorePointer(
          child: Crosshair(),
        ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
        // Zoom Controls
        Positioned(
          right: 16,
          bottom: MediaQuery.of(context).size.height * 0.15, // Above Now Playing Bar
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'zoomIn',
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
                onPressed: () => _controller.runJavaScript("zoomIn();"),
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'zoomOut',
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
                onPressed: () => _controller.runJavaScript("zoomOut();"),
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
