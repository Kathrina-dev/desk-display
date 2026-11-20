import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../services/ambient_audio_service.dart';

enum RobotMood { alert, sleepy }
enum RobotExpression { baseline, happy, startled, scan, sneeze, hologram }

class RobotEyes extends StatefulWidget {
  const RobotEyes({super.key});

  @override
  State<RobotEyes> createState() => _RobotEyesState();
}

class _RobotEyesState extends State<RobotEyes> with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  final _audio = AmbientAudioService();
  StreamSubscription<AccelerometerEvent>? _tiltSubscription;
  StreamSubscription<double>? _audioSubscription;
  Timer? _blinkTimer;
  Timer? _idleTimer;
  Timer? _expressionTimer;
  final _particles = <_Particle>[];
  RobotExpression _expression = RobotExpression.baseline;
  double _gazeX = 0;
  double _gazeY = 0;
  double _audioLevel = 0;
  DateTime _lastInteraction = DateTime.now();
  bool _blinking = false;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(() => mounted ? setState(() {}) : null)
      ..repeat();
    _scheduleBlink();
    _scheduleIdle();
    _tiltSubscription = accelerometerEventStream().listen(_onTilt);
    _audioSubscription = _audio.levels.listen((level) {
      if (mounted) setState(() => _audioLevel = (_audioLevel * 0.7) + (level * 0.3));
    });
    unawaited(_audio.start());
  }

  void _scheduleBlink() {
    _blinkTimer?.cancel();
    final seconds = _currentMood == RobotMood.sleepy ? 8 : 3 + math.Random().nextInt(4);
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
    _idleTimer = Timer(const Duration(seconds: 25), () {
      if (!mounted) return;
      if (DateTime.now().difference(_lastInteraction).inSeconds >= 20) {
        final idle = RobotExpression.values[2 + math.Random().nextInt(4)];
        _setExpression(idle, const Duration(seconds: 4));
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
    });
  }

  void _setExpression(RobotExpression expression, Duration duration) {
    _expressionTimer?.cancel();
    _lastInteraction = DateTime.now();
    setState(() => _expression = expression);
    _expressionTimer = Timer(duration, () {
      if (mounted) setState(() => _expression = RobotExpression.baseline);
    });
  }

  void _pet() {
    _setExpression(RobotExpression.happy, const Duration(seconds: 2));
    setState(() {
      _particles.addAll(List.generate(5, (index) => _Particle(
        x: 0.2 + math.Random().nextDouble() * 0.6,
        y: 0.55 + math.Random().nextDouble() * 0.2,
        symbol: index.isEven ? '*' : '+',
      )));
    });
  }

  void _poke() => _setExpression(RobotExpression.startled, const Duration(seconds: 2));

  void _onPointerMove(PointerMoveEvent event, BoxConstraints size) {
    if (event.position.dy > size.maxHeight * 0.52) return;
    _lastInteraction = DateTime.now();
    if (event.delta.distance > 3) _pet();
  }

  RobotMood get _currentMood {
    final hour = DateTime.now().hour;
    return hour >= 23 || hour < 6 ? RobotMood.sleepy : RobotMood.alert;
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
                mood: _currentMood,
                expression: _expression,
                blink: _blinking,
                gazeX: _gazeX,
                gazeY: _gazeY,
                audioLevel: _audioLevel,
                animation: _animation.value,
                particles: _particles,
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
    _expressionTimer?.cancel();
    _tiltSubscription?.cancel();
    _audioSubscription?.cancel();
    unawaited(_audio.dispose());
    super.dispose();
  }
}

class _Particle {
  const _Particle({required this.x, required this.y, required this.symbol});
  final double x;
  final double y;
  final String symbol;
}

class _RobotEyesPainter extends CustomPainter {
  const _RobotEyesPainter({required this.mood, required this.expression, required this.blink,
    required this.gazeX, required this.gazeY, required this.audioLevel, required this.animation,
    required this.particles});

  final RobotMood mood;
  final RobotExpression expression;
  final bool blink;
  final double gazeX;
  final double gazeY;
  final double audioLevel;
  final double animation;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    final gap = size.width * 0.06;
    final eyeWidth = math.min(size.width * 0.27, (size.width * 0.86 - gap) / 2);
    final eyeHeight = size.height * 0.34 * (1 + audioLevel * 0.05);
    final y = center.dy + gazeY * size.height * 0.04;
    final gazeOffset = gazeX * size.width * 0.025;
    final left = Offset(center.dx - gap / 2 - eyeWidth + gazeOffset, y - eyeHeight / 2);
    final right = Offset(center.dx + gap / 2 + gazeOffset, y - eyeHeight / 2);
    final pink = const Color(0xFFC44582);
    final highlight = const Color(0xFFFF79B0);
    final paint = Paint()..color = pink;

    if (expression == RobotExpression.happy) {
      _drawHappy(canvas, left, right, eyeWidth, eyeHeight, paint);
    } else if (expression == RobotExpression.startled || expression == RobotExpression.sneeze) {
      _drawChevrons(canvas, center, eyeWidth, eyeHeight, paint);
    } else {
      final lid = blink ? 0.95 : (mood == RobotMood.sleepy ? 0.48 : 0.06);
      _drawEye(canvas, left, eyeWidth, eyeHeight * (1 - lid), paint, highlight);
      _drawEye(canvas, right, eyeWidth, eyeHeight * (1 - lid), paint, highlight);
    }
    if (expression == RobotExpression.scan) {
      final scanX = size.width * (0.25 + animation * 0.5);
      canvas.drawRect(Rect.fromLTWH(scanX, center.dy - eyeHeight / 2, 2, eyeHeight), Paint()..color = highlight.withValues(alpha: 0.8));
    }
    if (expression == RobotExpression.hologram) _drawHologram(canvas, center.translate(0, eyeHeight * 0.9), size);
    for (final particle in particles) {
      final offset = Offset(particle.x * size.width, particle.y * size.height - animation * 12);
      canvas.drawCircle(offset, 2.5, Paint()..color = pink.withValues(alpha: 0.7));
    }
  }

  void _drawEye(Canvas canvas, Offset topLeft, double width, double height, Paint paint, Color highlight) {
    final rect = RRect.fromRectAndRadius(Rect.fromLTWH(topLeft.dx, topLeft.dy + (height * 0.34), width, height), const Radius.circular(28));
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

  void _drawHologram(Canvas canvas, Offset center, Size size) {
    final paint = Paint()..color = const Color(0xCCF2F2F2)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final rect = Rect.fromCenter(center: center, width: size.width * 0.08, height: size.height * 0.045);
    canvas.drawRect(rect, paint);
    canvas.drawLine(rect.topLeft, rect.bottomLeft.translate(0, -rect.height * 0.8), paint);
    canvas.drawLine(rect.topRight, rect.bottomRight.translate(0, -rect.height * 0.8), paint);
  }

  @override
  bool shouldRepaint(covariant _RobotEyesPainter oldDelegate) => true;
}