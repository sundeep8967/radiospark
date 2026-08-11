import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/map/globe_view.dart';
import 'features/map/map_controller.dart';
import 'features/map/crosshair.dart';
import 'features/ui/now_playing_bar.dart';

import 'package:just_audio_background/just_audio_background.dart';

Future<void> main() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ravana.onlineradiostation.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(
    const ProviderScope(
      child: RadioParkApp(),
    ),
  );
}

class RadioParkApp extends StatelessWidget {
  const RadioParkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radiospark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(mapControllerInitProvider);

    return const Scaffold(
      body: Stack(
        children: [
          GlobeView(),
          Crosshair(),
          NowPlayingBar(),
        ],
      ),
    );
  }
}
