import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mapThemeProvider = StateProvider<String>((ref) => 'satellite');

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
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Map Style',
            style: TextStyle(
              color: Color(0xFF00E676),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Satellite', style: TextStyle(color: Colors.white)),
                  trailing: Radio<String>(
                    value: 'satellite',
                    groupValue: currentTheme,
                    activeColor: const Color(0xFF00E676),
                    onChanged: (value) {
                      if (value != null) ref.read(mapThemeProvider.notifier).state = value;
                    },
                  ),
                  onTap: () => ref.read(mapThemeProvider.notifier).state = 'satellite',
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                ListTile(
                  title: const Text('Graphic (Dark)', style: TextStyle(color: Colors.white)),
                  trailing: Radio<String>(
                    value: 'graphic',
                    groupValue: currentTheme,
                    activeColor: const Color(0xFF00E676),
                    onChanged: (value) {
                      if (value != null) ref.read(mapThemeProvider.notifier).state = value;
                    },
                  ),
                  onTap: () => ref.read(mapThemeProvider.notifier).state = 'graphic',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
