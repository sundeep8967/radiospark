import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../stations/station_api.dart';

enum AudioStatus { initial, loading, playing, paused, error }

class AudioState {
  final AudioStatus status;
  final Station? currentStation;
  final String? errorMessage;

  const AudioState({
    this.status = AudioStatus.initial,
    this.currentStation,
    this.errorMessage,
  });

  AudioState copyWith({
    AudioStatus? status,
    Station? currentStation,
    String? errorMessage,
  }) {
    return AudioState(
      status: status ?? this.status,
      currentStation: currentStation ?? this.currentStation,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(() {
    player.dispose();
  });
  return player;
});

class AudioController extends Notifier<AudioState> {
  late final AudioPlayer _player;

  @override
  AudioState build() {
    _player = ref.watch(audioPlayerProvider);

    _player.playerStateStream.listen((state) {
      if (state.playing) {
        this.state = this.state.copyWith(status: AudioStatus.playing);
      } else if (state.processingState != ProcessingState.loading && state.processingState != ProcessingState.buffering) {
        this.state = this.state.copyWith(status: AudioStatus.paused);
      }
    });

    _player.playbackEventStream.listen((event) {}, onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
      this.state = this.state.copyWith(
        status: AudioStatus.error, 
        errorMessage: 'Stream failed: $e'
      );
      _autoSkip();
    });

    return const AudioState();
  }

  void _autoSkip() {
    final list = ref.read(currentStationsProvider);
    final index = ref.read(currentStationIndexProvider);
    if (list.isNotEmpty) {
      final nextIndex = (index + 1) % list.length;
      ref.read(currentStationIndexProvider.notifier).state = nextIndex;
      final nextStation = list[nextIndex];
      ref.read(nearestStationProvider.notifier).state = nextStation;
      playStream(nextStation);
    }
  }

  Future<void> playStream(Station station) async {
    state = state.copyWith(status: AudioStatus.loading, currentStation: station, errorMessage: null);
    try {
      final audioSource = AudioSource.uri(
        Uri.parse(station.urlResolved),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
          'Origin': 'https://radio.garden',
          'Referer': 'https://radio.garden/',
        },
        tag: MediaItem(
          id: station.urlResolved,
          title: station.name,
          artist: station.country.isNotEmpty ? station.country : 'Unknown Location',
          artUri: Uri.parse('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c4/Globe_icon.svg/1024px-Globe_icon.svg.png'),
        ),
      );

      await _player.setAudioSource(audioSource);
      await _player.play();
      state = state.copyWith(status: AudioStatus.playing, errorMessage: null);
    } catch (e) {
      print("Error loading audio source: $e");
      state = state.copyWith(status: AudioStatus.error, errorMessage: 'Failed to connect to station.');
      _autoSkip();
    }
  }

  Future<void> pause() async {
    await _player.pause();
    state = state.copyWith(status: AudioStatus.paused);
  }

  /// Called when station is tuning/loading
  void setLoading([Station? station]) {
    state = state.copyWith(status: AudioStatus.loading, currentStation: station, errorMessage: null);
  }

  /// Called when WebView audio starts playing (no just_audio needed)
  void setPlaying(Station station) {
    state = state.copyWith(status: AudioStatus.playing, currentStation: station, errorMessage: null);
  }

  /// Called when WebView audio is paused
  void setPaused() {
    state = state.copyWith(status: AudioStatus.paused);
  }

  /// Called when WebView audio errors
  void setError() {
    state = state.copyWith(status: AudioStatus.error);
  }
}

final audioControllerProvider = NotifierProvider<AudioController, AudioState>(() {
  return AudioController();
});
