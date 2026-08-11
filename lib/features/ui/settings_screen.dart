import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../map/globe_view.dart';

final mapThemeProvider = StateProvider<String>((ref) => 'night');

// Globe texture map
const _globeThemes = [
  {
    'id': 'night',
    'label': 'Night City Lights',
    'desc': 'Earth at night — glowing cities',
    'url': 'https://unpkg.com/three-globe/example/img/earth-night.jpg',
    'atmos': '#7c3aed',
    'grad': [Color(0xFF1a0533), Color(0xFF3b1380)],
  },
  {
    'id': 'day',
    'label': 'Blue Marble',
    'desc': 'Classic NASA satellite view',
    'url': 'https://unpkg.com/three-globe/example/img/earth-blue-marble.jpg',
    'atmos': '#3b82f6',
    'grad': [Color(0xFF0c1e42), Color(0xFF1a3a6b)],
  },
  {
    'id': 'dark',
    'label': 'Dark Graphic',
    'desc': 'Minimal dark map style',
    'url': 'https://unpkg.com/three-globe/example/img/earth-dark.jpg',
    'atmos': '#00E676',
    'grad': [Color(0xFF0a0a0a), Color(0xFF1a1a2e)],
  },
  {
    'id': 'topo',
    'label': 'Topographic',
    'desc': 'Terrain elevation relief',
    'url': 'https://unpkg.com/three-globe/example/img/earth-topology.png',
    'atmos': '#f59e0b',
    'grad': [Color(0xFF1a1200), Color(0xFF3d2e00)],
  },
];

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SettingsScreen(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(mapThemeProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0e0e18),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Settings',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Section label
          const Text(
            'GLOBE STYLE',
            style: TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),

          // Globe style grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _globeThemes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, i) {
              final theme = _globeThemes[i];
              final id = theme['id'] as String;
              final selected = currentTheme == id;
              final grads = (theme['grad'] as List).cast<Color>();
              final atmosHex = theme['atmos'] as String; // stored as '#7c3aed'
              final atmosColor = Color(int.parse('0xFF${atmosHex.substring(1)}'));

              return GestureDetector(
                onTap: () {
                  ref.read(mapThemeProvider.notifier).state = id;
                  // Update globe texture via WebView
                  final webCtrl = ref.read(globeControllerProvider);
                  final url = theme['url'] as String;
                  webCtrl?.runJavaScript(
                    "myGlobe.globeImageUrl('$url').atmosphereColor('$atmosHex');",
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: grads,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? const Color(0xFF00E676) : Colors.white12,
                      width: selected ? 2 : 1,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.3), blurRadius: 12)]
                        : [],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: atmosColor.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                              border: Border.all(color: atmosColor, width: 1.5),
                            ),
                            child: Icon(Icons.public, size: 13, color: atmosColor),
                          ),
                          if (selected)
                            const Icon(Icons.check_circle, color: Color(0xFF00E676), size: 16),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            theme['label'] as String,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                          Text(
                            theme['desc'] as String,
                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          // App info
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.radio, color: Color(0xFF00E676), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Radiospark', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('Radio Browser API · 30,000+ stations', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
