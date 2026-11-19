import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

class LiftDetector {
  LiftDetector({required this.onLift});

  final Future<void> Function() onLift;
  StreamSubscription<AccelerometerEvent>? _subscription;
  Timer? _settleTimer;
  DateTime? _deltaStartedAt;
  AccelerometerEvent? _baseline;
  bool _triggered = false;

  void start() {
    _subscription = accelerometerEventStream().listen(_onEvent);
    _settleTimer = Timer(const Duration(milliseconds: 800), () {});
  }

  void _onEvent(AccelerometerEvent event) {
    if (_triggered) return;
    if (_settleTimer?.isActive ?? false) return;
    _baseline ??= event;
    final baseline = _baseline!;
    final delta = math.sqrt(
      math.pow(event.x - baseline.x, 2) +
          math.pow(event.y - baseline.y, 2) +
          math.pow(event.z - baseline.z, 2),
    );
    if (delta <= 2.5) {
      _deltaStartedAt = null;
      return;
    }
    _deltaStartedAt ??= DateTime.now();
    if (DateTime.now().difference(_deltaStartedAt!).inMilliseconds >= 1500) {
      _triggered = true;
      unawaited(onLift());
    }
  }

  void dispose() {
    _settleTimer?.cancel();
    _subscription?.cancel();
  }
}