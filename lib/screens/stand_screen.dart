import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../services/desk_timer_service.dart';
import '../services/lift_detector.dart';
import '../services/lock_service.dart';
import '../widgets/flip_clock.dart';
import '../widgets/robot_eyes/robot_eyes.dart';

class StandScreen extends StatefulWidget {
  const StandScreen({super.key});

  @override
  State<StandScreen> createState() => _StandScreenState();
}

class _StandScreenState extends State<StandScreen> {
  final _timer = DeskTimerService();
  late final LiftDetector _liftDetector;

  @override
  void initState() {
    super.initState();
    _liftDetector = LiftDetector(onLift: _exitStand);
    _timer.addListener(_onTimerChanged);
    _initializeStand();
  }

  Future<void> _initializeStand() async {
    await WakelockPlus.enable();
    await _timer.initialize();
    if (!mounted) return;
    _timer.start();
    _liftDetector.start();
    await LockService.startLock();
  }

  void _onTimerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _exitStand() async {
    await _timer.pause();
    await LockService.stopLock();
  }

  @override
  void dispose() {
    _liftDetector.dispose();
    _timer.removeListener(_onTimerChanged);
    _timer.pause();
    _timer.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        body: PageView(
          scrollDirection: Axis.vertical,
          children: [
            _ClockPage(seconds: _timer.elapsedSeconds, onEmergencyExit: _exitStand),
            const RobotEyes(),
          ],
        ),
      ),
    );
  }
}

class _ClockPage extends StatelessWidget {
  const _ClockPage({required this.seconds, required this.onEmergencyExit});

  final int seconds;
  final Future<void> Function() onEmergencyExit;

  @override
  Widget build(BuildContext context) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return Stack(
      children: [
        const Center(child: FlipClock()),
        Positioned(
          right: 24,
          bottom: 18,
          child: _EmergencyUnlock(
            onUnlock: onEmergencyExit,
            child: Text(
              'DESK ${hours}h ${minutes.toString().padLeft(2, '0')}m',
              style: const TextStyle(color: Color(0x66F2F2F2), fontSize: 12, letterSpacing: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmergencyUnlock extends StatefulWidget {
  const _EmergencyUnlock({required this.onUnlock, required this.child});

  final Future<void> Function() onUnlock;
  final Widget child;

  @override
  State<_EmergencyUnlock> createState() => _EmergencyUnlockState();
}

class _EmergencyUnlockState extends State<_EmergencyUnlock> {
  Timer? _holdTimer;

  void _startHold(LongPressStartDetails details) {
    _holdTimer = Timer(const Duration(seconds: 4), widget.onUnlock);
  }

  void _cancelHold([LongPressEndDetails? details]) {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  @override
  void dispose() {
    _cancelHold();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _startHold,
      onLongPressEnd: _cancelHold,
      onLongPressCancel: _cancelHold,
      child: widget.child,
    );
  }
}