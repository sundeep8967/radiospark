import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../stations/station_api.dart';
import '../audio/audio_provider.dart';
import 'dart:ui';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FavoritesScreen(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final audioState = ref.watch(audioControllerProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) {
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
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Favorite Stations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: favorites.isEmpty
                        ? Center(
                            child: Text(
                              'No favorites yet.',
                              style: TextStyle(color: Colors.white.withOpacity(0.5)),
                            ),
                          )
                        : ListView.builder(
                            controller: controller,
                            itemCount: favorites.length,
                            itemBuilder: (context, index) {
                              final station = favorites[index];
                              final isPlaying = audioState.status == AudioStatus.playing &&
                                  audioState.currentStation?.stationUuid == station.stationUuid;

                              return ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPlaying ? Icons.multitrack_audio : Icons.radio,
                                    color: isPlaying ? const Color(0xFF00E676) : Colors.white70,
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
                                  station.country,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.favorite, color: Color(0xFF00E676)),
                                  onPressed: () {
                                    ref.read(favoritesProvider.notifier).toggleFavorite(station);
                                  },
                                ),
                                onTap: () {
                                  ref.read(nearestStationProvider.notifier).state = station;
                                  ref.read(audioControllerProvider.notifier).playStream(station);
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
