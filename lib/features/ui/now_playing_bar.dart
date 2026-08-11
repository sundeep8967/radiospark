import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../stations/station_api.dart';
import '../audio/audio_provider.dart';
import '../map/globe_view.dart';
import 'favorites_screen.dart';
import 'search_screen.dart';

class NowPlayingBar extends ConsumerWidget {
  const NowPlayingBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearestStation = ref.watch(nearestStationProvider);
    final audioState = ref.watch(audioControllerProvider);
    final isPlaying = audioState.status == AudioStatus.playing;
    final isLoading = audioState.status == AudioStatus.loading;
    final place = ref.watch(selectedPlaceProvider);
    final stations = ref.watch(currentStationsProvider);
    final favorites = ref.watch(favoritesProvider);

    bool isFav = false;
    if (nearestStation != null) {
      isFav = ref.read(favoritesProvider.notifier).isFavorite(nearestStation.stationUuid);
    }

    final cityTitle = place?['title'] as String? ?? '';
    final countryTitle = place?['country'] as String? ?? '';
    final totalStations = stations.length;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
            ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // City row
            if (place != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                child: Row(
                  children: [
                    // Station count badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E676),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          totalStations > 0 ? totalStations.toString() : '...',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cityTitle.isNotEmpty ? cityTitle : 'Spin the globe',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (countryTitle.isNotEmpty)
                            Text(
                              countryTitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Divider(
                color: Colors.white.withOpacity(0.08),
                height: 1,
                indent: 16,
                endIndent: 16,
              ),

              // Station row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLoading ? 'Tuning into station...' : (nearestStation?.name ?? 'Loading station...'),
                            style: const TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            cityTitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Favorite button
                    if (nearestStation != null)
                      GestureDetector(
                        onTap: () {
                          ref.read(favoritesProvider.notifier).toggleFavorite(nearestStation);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? const Color(0xFF00E676) : Colors.white.withOpacity(0.9),
                            size: 28,
                          ),
                        ),
                      ),
                    // Play/Pause/Stop button
                    GestureDetector(
                      onTap: () {
                        final ctrl = ref.read(audioControllerProvider.notifier);
                        if (isPlaying) {
                          ctrl.pause();
                        } else if (nearestStation != null) {
                          ctrl.playStream(nearestStation);
                        }
                      },
                      child: isLoading 
                          ? const SizedBox(
                              width: 36, 
                              height: 36, 
                              child: CircularProgressIndicator(color: Color(0xFF00E676), strokeWidth: 2)
                            )
                          : Icon(
                              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                              color: Colors.white.withOpacity(0.9),
                              size: 36,
                            ),
                    ),
                    const SizedBox(width: 16),
                    // Skip/next button
                    GestureDetector(
                      onTap: () {
                        final index = ref.read(currentStationIndexProvider);
                        final list = ref.read(currentStationsProvider);
                        if (list.isNotEmpty) {
                          final nextIndex = (index + 1) % list.length;
                          ref.read(currentStationIndexProvider.notifier).state = nextIndex;
                          final nextStation = list[nextIndex];
                          ref.read(nearestStationProvider.notifier).state = nextStation;
                          ref.read(audioControllerProvider.notifier).playStream(nextStation);
                        }
                      },
                      child: Icon(
                        Icons.skip_next_rounded,
                        color: totalStations > 1
                            ? Colors.white.withOpacity(0.9)
                            : Colors.white.withOpacity(0.3),
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Spin the globe to explore',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],

            // Bottom nav
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.5),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItem(icon: Icons.language, label: 'Explore', active: true),
                      _NavItem(
                        icon: Icons.favorite_border, 
                        label: 'Favourites',
                        onTap: () => FavoritesScreen.show(context),
                      ),
                      _NavItem(
                        icon: Icons.search, 
                        label: 'Search',
                        onTap: () => SearchScreen.show(context),
                      ),
                      _NavItem(icon: Icons.settings_outlined, label: 'Settings'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
      ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _NavItem({required this.icon, required this.label, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF00E676) : Colors.white.withOpacity(0.4);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
