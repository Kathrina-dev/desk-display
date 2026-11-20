import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum RoboEyeState {
  defaultState,
  happy,
  curiosity,
  sleepy,
  asleep,
  angry,
  scare,
  scared,
  tiltedLeft,
  tiltedRight,
}

class RobotEyes extends StatefulWidget {
  const RobotEyes({super.key});

  @override
  State<RobotEyes> createState() => _RobotEyesState();
}

class _RobotEyesState extends State<RobotEyes> with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  StreamSubscription<AccelerometerEvent>? _tiltSubscription;
  Timer? _blinkTimer;
  Timer? _idleTimer;
  Timer? _stateTimer;
  RoboEyeState _state = RoboEyeState.defaultState;
  double _gazeX = 0;
  double _gazeY = 0;
  DateTime _lastInteraction = DateTime.now();
  bool _blinking = false;
  final _roboEyesModel = _RoboEyesModel();

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(() => mounted ? setState(() {}) : null)
      ..repeat();
    _scheduleBlink();
    _scheduleIdle();
    _tiltSubscription = accelerometerEventStream().listen(_onTilt);
  }

  void _scheduleBlink() {
    _blinkTimer?.cancel();
    final seconds = _state == RoboEyeState.sleepy || _state == RoboEyeState.asleep
      ? 8
      : 3 + math.Random().nextInt(4);
    _blinkTimer = Timer(Duration(seconds: seconds), () {
      if (!mounted) return;
      setState(() => _blinking = true);
      Timer(const Duration(milliseconds: 260), () {
        if (mounted) setState(() => _blinking = false);
        _scheduleBlink();
      });
    });
  }

  void _scheduleIdle() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (DateTime.now().difference(_lastInteraction).inSeconds >= 20) {
        _setState(math.Random().nextBool() ? RoboEyeState.sleepy : RoboEyeState.curiosity,
            const Duration(seconds: 10));
      }
      _scheduleIdle();
    });
  }

  void _onTilt(AccelerometerEvent event) {
    final impulse = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    if (impulse < 0.3 || impulse > 1.8) return;
    _lastInteraction = DateTime.now();
    if (!mounted) return;
    setState(() {
      _gazeX = (event.x / 1.8).clamp(-1.0, 1.0);
      _gazeY = (event.y / 1.8).clamp(-0.5, 0.5);
      _state = event.x < 0 ? RoboEyeState.tiltedLeft : RoboEyeState.tiltedRight;
    });
    _stateTimer?.cancel();
    _stateTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) _setState(RoboEyeState.defaultState, Duration.zero);
    });
  }

  void _setState(RoboEyeState state, Duration duration) {
    _stateTimer?.cancel();
    _lastInteraction = DateTime.now();
    if (mounted) setState(() => _state = state);
    if (duration > Duration.zero) {
      _stateTimer = Timer(duration, () {
        if (!mounted) return;
        _setState(
          state == RoboEyeState.sleepy ? RoboEyeState.asleep : RoboEyeState.defaultState,
          Duration.zero,
        );
      });
    }
  }

  void _pet() {
    if (_state == RoboEyeState.sleepy || _state == RoboEyeState.asleep) {
      _setState(RoboEyeState.angry, const Duration(seconds: 5));
    } else {
      _setState(math.Random().nextInt(4) == 0 ? RoboEyeState.angry : RoboEyeState.happy,
          const Duration(milliseconds: 500));
    }
  }

  void _poke() => _setState(RoboEyeState.scared, const Duration(seconds: 2));

  void _onPointerMove(PointerMoveEvent event, BoxConstraints size) {
    if (event.position.dy > size.maxHeight * 0.52) return;
    _lastInteraction = DateTime.now();
    if (event.delta.distance > 3) _pet();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Listener(
        onPointerMove: (event) => _onPointerMove(event, constraints),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _pet,
          onDoubleTap: _poke,
          child: ColoredBox(
            color: const Color(0xFF090909),
            child: CustomPaint(
              painter: _RobotEyesPainter(
                state: _state,
                blink: _blinking,
                gazeX: _gazeX,
                gazeY: _gazeY,
                model: _roboEyesModel,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animation.dispose();
    _blinkTimer?.cancel();
    _idleTimer?.cancel();
    _stateTimer?.cancel();
    _tiltSubscription?.cancel();
    super.dispose();
  }
}

/// Parametric eye geometry adapted from the RoboEyes display model.
/// Current values ease toward next values every paint frame.
class _RoboEyesModel {
  double screenWidth = 0;
  double screenHeight = 0;

  double eyeLwidthDefault = 0;
  double eyeLheightDefault = 0;
  double eyeLwidthCurrent = 0;
  double eyeLheightCurrent = 0;
  double eyeLwidthNext = 0;
  double eyeLheightNext = 0;
  double eyeLborderRadiusDefault = 0;
  double eyeLborderRadiusCurrent = 0;
  double eyeLborderRadiusNext = 0;

  double eyeRwidthDefault = 0;
  double eyeRheightDefault = 0;
  double eyeRwidthCurrent = 0;
  double eyeRheightCurrent = 0;
  double eyeRwidthNext = 0;
  double eyeRheightNext = 0;
  double eyeRborderRadiusDefault = 0;
  double eyeRborderRadiusCurrent = 0;
  double eyeRborderRadiusNext = 0;

  double eyeLx = 0;
  double eyeLy = 0;
  double eyeLxNext = 0;
  double eyeLyNext = 0;
  double eyeRx = 0;
  double eyeRy = 0;
  double eyeRxNext = 0;
  double eyeRyNext = 0;
  double spaceBetweenDefault = 0;
  double spaceBetweenCurrent = 0;
  double spaceBetweenNext = 0;
  double eyelidsTiredHeight = 0;
  double eyelidsTiredHeightNext = 0;
  double eyelidsHappyBottomOffset = 0;
  double eyelidsHappyBottomOffsetNext = 0;
  bool _configured = false;

  void update(Size size, RoboEyeState state, bool blink, double gazeX, double gazeY) {
    final width = math.min(size.width * 0.27, (size.width * 0.86 - size.width * 0.06) / 2);
    final height = size.height * 0.34;
    final gap = size.width * 0.06;
    if (!_configured) {
      screenWidth = size.width;
      screenHeight = size.height;
      eyeLwidthDefault = width;
      eyeLheightDefault = height;
      eyeRwidthDefault = width;
      eyeRheightDefault = height;
      eyeLwidthCurrent = width;
      eyeRwidthCurrent = width;
      eyeLheightCurrent = height;
      eyeRheightCurrent = height;
      eyeLwidthNext = width;
      eyeRwidthNext = width;
      eyeLheightNext = height;
      eyeRheightNext = height;
      eyeLborderRadiusDefault = width * 0.12;
      eyeRborderRadiusDefault = width * 0.12;
      eyeLborderRadiusCurrent = eyeLborderRadiusDefault;
      eyeRborderRadiusCurrent = eyeRborderRadiusDefault;
      eyeLborderRadiusNext = eyeLborderRadiusDefault;
      eyeRborderRadiusNext = eyeRborderRadiusDefault;
      spaceBetweenDefault = gap;
      spaceBetweenCurrent = gap;
      spaceBetweenNext = gap;
      _configured = true;
    }

    final sleepy = state == RoboEyeState.sleepy;
    final asleep = state == RoboEyeState.asleep;
    final closed = blink;
    final targetHeight = closed ? 1.0 : (asleep ? 3.0 : (sleepy ? height * 0.52 : height));
    eyeLheightNext = targetHeight;
    eyeRheightNext = targetHeight;
    eyelidsTiredHeightNext = sleepy ? targetHeight * 0.12 : 0;
    eyelidsHappyBottomOffsetNext = state == RoboEyeState.happy ? targetHeight * 0.42 : 0;
    final center = size.width / 2;
    final y = size.height * 0.45 + gazeY * size.height * 0.04;
    eyeLxNext = center - gap / 2 - width + gazeX * size.width * 0.025;
    eyeLyNext = y - targetHeight / 2;
    eyeRxNext = eyeLxNext + width + gap;
    eyeRyNext = eyeLyNext;

    eyeLwidthCurrent = _ease(eyeLwidthCurrent, eyeLwidthNext);
    eyeRwidthCurrent = _ease(eyeRwidthCurrent, eyeRwidthNext);
    eyeLheightCurrent = _ease(eyeLheightCurrent, eyeLheightNext);
    eyeRheightCurrent = _ease(eyeRheightCurrent, eyeRheightNext);
    eyeLx = _ease(eyeLx, eyeLxNext);
    eyeLy = _ease(eyeLy, eyeLyNext);
    eyeRx = _ease(eyeRx, eyeRxNext);
    eyeRy = _ease(eyeRy, eyeRyNext);
    eyeLborderRadiusCurrent = _ease(eyeLborderRadiusCurrent, eyeLborderRadiusNext);
    eyeRborderRadiusCurrent = _ease(eyeRborderRadiusCurrent, eyeRborderRadiusNext);
    spaceBetweenCurrent = _ease(spaceBetweenCurrent, spaceBetweenNext);
    eyelidsTiredHeight = _ease(eyelidsTiredHeight, eyelidsTiredHeightNext);
    eyelidsHappyBottomOffset = _ease(eyelidsHappyBottomOffset, eyelidsHappyBottomOffsetNext);
  }

  double _ease(double current, double next) => current + (next - current) * 0.18;
}

class _RobotEyesPainter extends CustomPainter {
  const _RobotEyesPainter({required this.state, required this.blink,
    required this.gazeX, required this.gazeY, required this.model});

  final RoboEyeState state;
  final bool blink;
  final double gazeX;
  final double gazeY;
  final _RoboEyesModel model;

  @override
  void paint(Canvas canvas, Size size) {
    model.update(size, state, blink, gazeX, gazeY);
    final center = Offset(size.width / 2, size.height * 0.45);
    final eyeWidth = model.eyeLwidthCurrent;
    final eyeHeight = model.eyeLheightCurrent;
    final left = Offset(model.eyeLx, model.eyeLy);
    final right = Offset(model.eyeRx, model.eyeRy);
    final blue = const Color(0xFF42A5F5);
    final highlight = const Color(0xFF9DDBFF);
    final paint = Paint()..color = blue;

    if (state == RoboEyeState.happy) {
      _drawHappy(canvas, left, right, eyeWidth, eyeHeight, paint);
    } else if (state == RoboEyeState.scared || state == RoboEyeState.scare) {
      _drawChevrons(canvas, center, eyeWidth, eyeHeight, paint);
    } else {
      final lid = blink ? 0.95 : (state == RoboEyeState.sleepy ? 0.48 : 0.06);
      _drawEye(canvas, left, model.eyeLwidthCurrent, eyeHeight * (1 - lid), model.eyeLborderRadiusCurrent, paint, highlight);
      _drawEye(canvas, right, model.eyeRwidthCurrent, model.eyeRheightCurrent * (1 - lid), model.eyeRborderRadiusCurrent, paint, highlight);
    }
  }

  void _drawEye(Canvas canvas, Offset topLeft, double width, double height, double radius, Paint paint, Color highlight) {
    final rect = RRect.fromRectAndRadius(Rect.fromLTWH(topLeft.dx, topLeft.dy, width, height), Radius.circular(radius));
    canvas.drawRRect(rect, paint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect.outerRect.deflate(width * 0.07), const Radius.circular(22)), Paint()..color = highlight.withValues(alpha: 0.28));
  }

  void _drawHappy(Canvas canvas, Offset left, Offset right, double width, double height, Paint paint) {
    final path = Path();
    final strokeWidth = (width * 0.055).clamp(6.0, 14.0);
    for (final x in [left.dx, right.dx]) {
      path.reset();
      path.moveTo(x, left.dy + height * 0.55);
      path.quadraticBezierTo(x + width / 2, left.dy + height * 0.08, x + width, left.dy + height * 0.55);
      canvas.drawPath(path, paint..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round);
    }
    paint.style = PaintingStyle.fill;
  }

  void _drawChevrons(Canvas canvas, Offset center, double width, double height, Paint paint) {
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = (width * 0.055).clamp(6.0, 14.0);
    paint.strokeCap = StrokeCap.round;
    for (final sign in [-1, 1]) {
      final x = center.dx + sign * width * 0.55;
      final path = Path()..moveTo(x - sign * width * 0.25, center.dy - height * 0.25)
        ..lineTo(x + sign * width * 0.15, center.dy)
        ..lineTo(x - sign * width * 0.25, center.dy + height * 0.25);
      canvas.drawPath(path, paint);
    }
    paint.style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(covariant _RobotEyesPainter oldDelegate) => true;
}