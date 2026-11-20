import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'eye_drawer.dart';
import 'eye_presets.dart';
import 'face_emotions.dart';
import 'face.dart';

class RobotEyes extends StatefulWidget {
  const RobotEyes({super.key});

  @override
  State<RobotEyes> createState() => _RobotEyesState();
}

class _RobotEyesState extends State<RobotEyes> with SingleTickerProviderStateMixin {
  late final AnimationController _frame;
  late final Face _face;
  final _random = Random();
  StreamSubscription<AccelerometerEvent>? _tilt;
  FaceEmotion _emotion = FaceEmotion.normal;
  DateTime _overrideUntil = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastInteraction = DateTime.now();
  DateTime _lastFrame = DateTime.now();
  DateTime _nextIdleAction = DateTime.now().add(const Duration(seconds: 12));

  double _sleepProgress = 0;
  double _zAnimation = 0;
  IdleAction _idleAction = IdleAction.none;
  double _idleActionProgress = 0;
  Duration _idleActionDuration = Duration.zero;
  DateTime? _idleActionStarted;

  Offset? _pointerDown;
  bool _rubTriggered = false;

  @override
  void initState() {
    super.initState();
    _frame = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(_tick)
      ..repeat();
    _face = Face(onEmotionChanged: (emotion) => _emotion = emotion);
    _face.behavior.randomBehavior = true;
    _face.look.randomLook = true;
    _face.blink.randomBlink = true;
    _applyCircadianProfile();
    _tilt = accelerometerEventStream().listen(_onTilt);
  }

  void _tick() {
    if (!mounted) return;
    final now = DateTime.now();
    final dt = now.difference(_lastFrame);
    _lastFrame = now;

    if (now.isAfter(_overrideUntil)) {
      _applyCircadianProfile();
    }
    _face.update(dt);

    // Update active idle prop/animation (visor scan, coffee mug, sparkles)
    if (_idleAction != IdleAction.none && _idleActionStarted != null) {
      final elapsed = now.difference(_idleActionStarted!).inMilliseconds;
      final total = _idleActionDuration.inMilliseconds;
      if (elapsed >= total) {
        _idleAction = IdleAction.none;
        _idleActionProgress = 0;
        _idleActionStarted = null;
      } else {
        _idleActionProgress = (elapsed / total).clamp(0.0, 1.0);
      }
    }

    // Trigger varied idle actions every 14–22 seconds so it does more than just look/sleep
    if (now.isAfter(_nextIdleAction) && now.isAfter(_overrideUntil) && _sleepProgress == 0) {
      _scheduleNextIdleAction(now);
      _triggerRandomIdleRoutine();
    }

    // Brief periodic naps after 90s idle (wakes back up after 15s instead of sleeping forever)
    final idleSeconds = now.difference(_lastInteraction).inSeconds;
    final inNapCycle = idleSeconds >= 90 && ((idleSeconds - 90) % 60) < 18;
    if (inNapCycle && now.isAfter(_overrideUntil)) {
      _sleepProgress = (_sleepProgress + 0.015).clamp(0.0, 1.0);
      _zAnimation = (_zAnimation + dt.inMilliseconds / 3000.0) % 1.0;
      _emotion = FaceEmotion.sleepy;
      _face.look.lookAt(0, 0.15);
      _face.setTargetConfig(
        EyePresets.sleepy.lerp(
          const EyeConfig(
            width: 40,
            height: 4,
            borderRadius: 2,
            topSlope: 0,
            bottomSlope: 0,
            color: Color(0xFF7986CB),
            mouthWidth: 26,
            mouthShape: MouthShape.line,
          ),
          _sleepProgress,
        ),
      );
    } else {
      _sleepProgress = 0;
      _zAnimation = 0;
    }

    setState(() {});
  }

  void _scheduleNextIdleAction(DateTime now) {
    _nextIdleAction = now.add(Duration(seconds: 14 + _random.nextInt(9)));
  }

  void _triggerRandomIdleRoutine() {
    final choice = _random.nextInt(5);
    switch (choice) {
      case 0:
        // Visor room scan
        _startIdleProp(IdleAction.visorScan, const Duration(milliseconds: 2800));
        _temporaryEmotion(FaceEmotion.focused, const Duration(milliseconds: 2800));
        break;
      case 1:
        // Glance down at holographic coffee mug
        _startIdleProp(IdleAction.coffeeGlance, const Duration(milliseconds: 3500));
        _face.look.lookAt(0.65, 0.55);
        _temporaryEmotion(FaceEmotion.happy, const Duration(milliseconds: 3500));
        break;
      case 2:
        // Mini sneeze sequence (scrunch -> surprised -> blink)
        _temporaryEmotion(FaceEmotion.annoyed, const Duration(milliseconds: 700));
        Timer(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          _face.blink.doBlink();
          _temporaryEmotion(FaceEmotion.surprised, const Duration(milliseconds: 1400));
        });
        break;
      case 3:
        // Curious double-take
        _face.look.lookAt(-0.7, -0.3);
        _temporaryEmotion(FaceEmotion.skeptic, const Duration(milliseconds: 2200));
        break;
      case 4:
        // Cheerful sparkle stretch
        _startIdleProp(IdleAction.sparkleBurst, const Duration(milliseconds: 2000));
        _temporaryEmotion(FaceEmotion.glee, const Duration(milliseconds: 2000));
        break;
    }
  }

  void _startIdleProp(IdleAction action, Duration duration) {
    _idleAction = action;
    _idleActionDuration = duration;
    _idleActionStarted = DateTime.now();
    _idleActionProgress = 0;
  }

  bool get _isNocturnal {
    final value = DateTime.now().hour * 60 + DateTime.now().minute;
    return value >= 23 * 60 || value < 6 * 60;
  }

  void _applyCircadianProfile() {
    final nocturnal = _isNocturnal;
    _face.behavior.interval = const Duration(seconds: 9);
    _face.look.interval = const Duration(milliseconds: 6500);
    _face.blink.interval = nocturnal ? const Duration(seconds: 7) : const Duration(milliseconds: 4500);
    _face.behavior.clear();

    if (nocturnal) {
      // Late night: mix of chill, focused, and occasional drowsy instead of 100% sleeping
      _face.behavior.setEmotion(FaceEmotion.normal, 0.35);
      _face.behavior.setEmotion(FaceEmotion.sleepy, 0.25);
      _face.behavior.setEmotion(FaceEmotion.focused, 0.20);
      _face.behavior.setEmotion(FaceEmotion.skeptic, 0.10);
      _face.behavior.setEmotion(FaceEmotion.happy, 0.10);
    } else {
      _face.behavior.setEmotion(FaceEmotion.normal, 0.52);
      _face.behavior.setEmotion(FaceEmotion.focused, 0.14);
      _face.behavior.setEmotion(FaceEmotion.happy, 0.12);
      _face.behavior.setEmotion(FaceEmotion.skeptic, 0.10);
      _face.behavior.setEmotion(FaceEmotion.awe, 0.06);
      _face.behavior.setEmotion(FaceEmotion.sleepy, 0.06);
    }
  }

  void _goToEmotion(FaceEmotion emotion) {
    _face.goToEmotion(emotion);
    _emotion = emotion;
  }

  void _temporaryEmotion(FaceEmotion emotion, Duration duration) {
    _overrideUntil = DateTime.now().add(duration);
    _face.behavior.randomBehavior = false;
    _face.look.randomLook = false;
    _goToEmotion(emotion);
    Timer(duration, () {
      if (!mounted) return;
      _face.behavior.randomBehavior = true;
      _face.look.randomLook = true;
      _applyCircadianProfile();
    });
  }

  void _onTap(TapUpDetails details, BoxConstraints size) {
    final wasSleeping = _emotion == FaceEmotion.sleepy || _sleepProgress > 0;
    _lastInteraction = DateTime.now();
    _sleepProgress = 0;

    final x = ((details.localPosition.dx / size.maxWidth) * 2 - 1).clamp(-1.0, 1.0);
    final y = ((details.localPosition.dy / size.maxHeight) * 2 - 1).clamp(-1.0, 1.0);
    _face.look.lookAt(x, y);

    if (wasSleeping) {
      _temporaryEmotion(FaceEmotion.angry, const Duration(milliseconds: 2500));
    } else {
      _temporaryEmotion(
        _random.nextBool() ? FaceEmotion.surprised : FaceEmotion.skeptic,
        const Duration(milliseconds: 2200),
      );
    }
  }

  void _onDoubleTap() {
    final wasSleeping = _emotion == FaceEmotion.sleepy || _sleepProgress > 0;
    _lastInteraction = DateTime.now();
    _sleepProgress = 0;

    final emotion = wasSleeping ? FaceEmotion.furious : FaceEmotion.angry;
    _temporaryEmotion(emotion, const Duration(seconds: 3));
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerDown = event.localPosition;
    _rubTriggered = false;
  }

  void _onPointerMove(PointerMoveEvent event, BoxConstraints size) {
    final start = _pointerDown;
    if (start == null || _rubTriggered) return;
    final distance = (event.localPosition - start).distance;
    final isEdgeSwipe = start.dx < size.maxWidth * 0.12 || start.dx > size.maxWidth * 0.88;
    if (!isEdgeSwipe && distance > 14 && distance < size.maxWidth * 0.35) {
      _rubTriggered = true;
      _lastInteraction = DateTime.now();
      _sleepProgress = 0;
      _startIdleProp(IdleAction.sparkleBurst, const Duration(seconds: 2));
      _temporaryEmotion(FaceEmotion.glee, const Duration(seconds: 2));
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _pointerDown = null;
  }

  void _onTilt(AccelerometerEvent event) {
    final impulse = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    if (impulse < 0.3 || impulse > 1.8) return;
    _lastInteraction = DateTime.now();
    _sleepProgress = 0;
    _face.look.lookAt(event.x < 0 ? -0.85 : 0.85, 0);
    _temporaryEmotion(
      _random.nextBool() ? FaceEmotion.suspicious : FaceEmotion.skeptic,
      const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, size) {
        return Listener(
          onPointerDown: _onPointerDown,
          onPointerMove: (event) => _onPointerMove(event, size),
          onPointerUp: _onPointerUp,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (details) => _onTap(details, size),
            onDoubleTap: _onDoubleTap,
            child: ColoredBox(
              color: const Color(0xFF090909),
              child: CustomPaint(
                painter: EyeDrawer(
                  left: _face.config,
                  right: _face.config,
                  lookLeft: _face.leftLook,
                  lookRight: _face.rightLook,
                  blinkFactor: _face.blink.factor,
                  scanlinePhase: _frame.value,
                  zProgress: _sleepProgress > 0 ? _zAnimation : 0,
                  idleAction: _idleAction,
                  idleProgress: _idleActionProgress,
                  repaint: _frame,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _frame.dispose();
    _tilt?.cancel();
    super.dispose();
  }
}