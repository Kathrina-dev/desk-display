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
  double _sleepProgress = 0;
  Offset? _pointerDown;
  Offset? _lastPointer;
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
    final nocturnal = _isNocturnal;
    final idle = now.difference(_lastInteraction).inSeconds;
    _sleepProgress = nocturnal && idle >= 90 ? (_sleepProgress + 0.003).clamp(0.0, 1.0) : 0;
    if (_sleepProgress > 0) {
      _emotion = FaceEmotion.sleepy;
      _face.setTargetConfig(EyePresets.sleepy.lerp(const EyeConfig(width: 40, height: 4, borderRadius: 2, topSlope: 0, bottomSlope: 0), _sleepProgress));
    }
    setState(() {});
  }

  DateTime _lastFrame = DateTime.now();

  bool get _isNocturnal {
    final hour = DateTime.now().hour;
    final minute = DateTime.now().minute;
    final value = hour * 60 + minute;
    return value >= 22 * 60 + 30 || value < 6 * 60 + 30;
  }

  void _applyCircadianProfile() {
    final nocturnal = _isNocturnal;
    _face.behavior.interval = nocturnal ? const Duration(seconds: 5) : const Duration(seconds: 10);
    _face.look.interval = nocturnal ? const Duration(seconds: 10) : const Duration(milliseconds: 6500);
    _face.blink.interval = nocturnal ? const Duration(seconds: 12) : const Duration(seconds: 4);
    _face.behavior.clear();
    if (nocturnal) {
      _face.behavior.setEmotion(FaceEmotion.sleepy, 0.55);
      _face.behavior.setEmotion(FaceEmotion.frustrated, 0.20);
      _face.behavior.setEmotion(FaceEmotion.squint, 0.15);
      _face.behavior.setEmotion(FaceEmotion.normal, 0.10);
    } else {
      _face.behavior.setEmotion(FaceEmotion.normal, 0.65);
      _face.behavior.setEmotion(FaceEmotion.focused, 0.15);
      _face.behavior.setEmotion(FaceEmotion.skeptic, 0.08);
      _face.behavior.setEmotion(FaceEmotion.happy, 0.10);
      _face.behavior.setEmotion(FaceEmotion.awe, 0.08);
      _face.behavior.setEmotion(FaceEmotion.unimpressed, 0.07);
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
    _lastInteraction = DateTime.now();
    final x = ((details.localPosition.dx / size.maxWidth) * 2 - 1).clamp(-1.0, 1.0);
    final y = ((details.localPosition.dy / size.maxHeight) * 2 - 1).clamp(-1.0, 1.0);
    _face.look.lookAt(x, y);
    _temporaryEmotion(_random.nextBool() ? FaceEmotion.surprised : FaceEmotion.skeptic, const Duration(milliseconds: 2200));
  }

  void _onDoubleTap() {
    _lastInteraction = DateTime.now();
    final emotion = _isNocturnal && (_emotion == FaceEmotion.sleepy || _sleepProgress > 0)
        ? (_random.nextDouble() < 0.5 ? FaceEmotion.furious : FaceEmotion.angry)
        : (_random.nextDouble() < 0.3 ? FaceEmotion.scared : FaceEmotion.annoyed);
    _temporaryEmotion(emotion, const Duration(seconds: 3));
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerDown = event.localPosition;
    _lastPointer = event.localPosition;
    _rubTriggered = false;
  }

  void _onPointerMove(PointerMoveEvent event, BoxConstraints size) {
    final start = _pointerDown;
    final previous = _lastPointer;
    _lastPointer = event.localPosition;
    if (start == null || previous == null || _rubTriggered) return;
    final distance = (event.localPosition - start).distance;
    final isEdgeSwipe = start.dx < size.maxWidth * 0.12 || start.dx > size.maxWidth * 0.88;
    if (!isEdgeSwipe && distance > 12 && distance < size.maxWidth * 0.35) {
      _rubTriggered = true;
      _lastInteraction = DateTime.now();
      _temporaryEmotion(FaceEmotion.glee, const Duration(seconds: 2));
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _pointerDown = null;
    _lastPointer = null;
  }

  void _onTilt(AccelerometerEvent event) {
    final impulse = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    if (impulse < 0.3 || impulse > 1.8) return;
    _lastInteraction = DateTime.now();
    _face.look.lookAt(event.x < 0 ? -0.85 : 0.85, 0);
    _temporaryEmotion(_random.nextBool() ? FaceEmotion.suspicious : FaceEmotion.skeptic, const Duration(seconds: 3));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, size) {
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
                zProgress: _sleepProgress,
                repaint: _frame,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _frame.dispose();
    _tilt?.cancel();
    super.dispose();
  }
}
