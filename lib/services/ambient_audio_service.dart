import 'dart:async';

import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';

class AmbientAudioService {
  final _levels = StreamController<double>.broadcast();
  NoiseMeter? _meter;
  StreamSubscription<NoiseReading>? _subscription;
  double _ambient = 0;
  bool _running = false;

  Stream<double> get levels => _levels.stream;

  Future<void> start() async {
    if (_running) return;
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) return;
    try {
      _meter = NoiseMeter();
      _subscription = _meter!.noise.listen(_onReading, onError: (_) {});
      _running = true;
    } catch (_) {
      await stop();
    }
  }

  void _onReading(NoiseReading reading) {
    final decibels = reading.meanDecibel;
    _ambient = _ambient == 0 ? decibels : (_ambient * 0.96) + (decibels * 0.04);
    final activity = ((decibels - _ambient) / 30).clamp(0.0, 1.0);
    _levels.add(activity);
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _meter = null;
    _running = false;
  }

  Future<void> dispose() async {
    await stop();
    await _levels.close();
  }
}