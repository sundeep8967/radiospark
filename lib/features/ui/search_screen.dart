import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../stations/station_api.dart';
import '../audio/audio_provider.dart';
import '../map/globe_view.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SearchScreen(),
    );
  }

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Station> _results = [];
  bool _isSearching = false;
  String _error = '';

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = '';
    });

    try {
      final api = ref.read(radioBrowserApiProvider);
      final results = await api.searchStations(query);
      setState(() {
        _results = results;
        if (results.isEmpty) {
          _error = 'No stations found.';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Error searching stations.';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              color: Colors.black.withOpacity(0.6),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search for a station or location...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        prefixIcon: const Icon(Icons.search, color: Colors.white70),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            _controller.clear();
                            _performSearch('');
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: _performSearch,
                      textInputAction: TextInputAction.search,
                    ),
                  ),

                  // Results
                  Expanded(
                    child: _isSearching
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
                        : _error.isNotEmpty
                            ? Center(
                                child: Text(
                                  _error,
                                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: _results.length,
                                itemBuilder: (context, index) {
                                  final station = _results[index];
                                  return ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.radio,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    title: Text(
                                      station.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      station.country.isNotEmpty ? station.country : 'Unknown',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                    onTap: () {
                                      ref.read(nearestStationProvider.notifier).state = station;
                                      ref.read(currentStationsProvider.notifier).state = [station];
                                      // Play directly via WebView audio element
                                      final webCtrl = ref.read(globeControllerProvider);
                                      final url = station.urlResolved.replaceAll("'", "\\'");
                                      webCtrl?.runJavaScript("playStation('$url');");
                                      ref.read(audioControllerProvider.notifier).setPlaying(station);
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
