import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'globe_view.dart';
import '../stations/station_api.dart';
import '../audio/audio_provider.dart';

final mapInteractionControllerProvider = Provider((ref) => MapInteractionController(ref));

class MapInteractionController {
  final Ref _ref;

  MapInteractionController(this._ref);
}

final mapControllerInitProvider = Provider((ref) {
  ref.watch(mapInteractionControllerProvider);
});
