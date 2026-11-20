import 'package:flutter/material.dart';

import 'eye_presets.dart';
import 'look_assistant.dart';

class EyeDrawer extends CustomPainter {
  EyeDrawer({
    required this.left,
    required this.right,
    required this.lookLeft,
    required this.lookRight,
    required this.blinkFactor,
    this.scanlinePhase = 0,
    this.zProgress = 0,
    super.repaint,
  });

  final EyeConfig left;
  final EyeConfig right;
  final LookTransform lookLeft;
  final LookTransform lookRight;
  final double blinkFactor;
  final double scanlinePhase;
  final double zProgress;

  static const background = Color(0xFF090909);
  static const pink = Color(0xFFC44582);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(background, BlendMode.src);
    final center = Offset(size.width / 2, size.height * 0.46);
    _drawEye(canvas, size, center, left, lookLeft, true);
    _drawEye(canvas, size, center, right, lookRight, false);
    _drawScanlines(canvas, size);
    if (zProgress > 0) _drawZzz(canvas, size, zProgress);
  }

  void _drawEye(Canvas canvas, Size size, Offset center, EyeConfig config, LookTransform look, bool isLeft) {
    final scale = size.height / 64.0;
    final asymmetry = config.isAsymmetric ? (isLeft ? 1.08 : 0.82) : 1.0;
    final width = (config.width * scale).clamp(0.0, size.width * 0.26) * look.scaleX * (config.isAsymmetric && isLeft ? 1.05 : config.isAsymmetric ? 0.88 : 1.0);
    final height = config.height * scale * look.scaleY * asymmetry * blinkFactor;
    if (height <= 1) return;
    final x = center.dx + config.offsetX * scale + look.moveX * size.width + (isLeft ? -width - 10 * scale : 10 * scale);
    final y = center.dy + config.offsetY * scale + look.moveY * size.height - height / 2;
    final radius = (config.borderRadius * scale).clamp(0.0, height / 2);
    final effectiveTopSlope = config.isAsymmetric ? config.topSlope * (isLeft ? 1.15 : 0.75) : (isLeft ? config.topSlope : -config.topSlope);
    final effectiveBottomSlope = config.isAsymmetric ? config.bottomSlope * (isLeft ? 1.15 : 0.75) : (isLeft ? config.bottomSlope : -config.bottomSlope);
    final path = _eyePath(Rect.fromLTWH(x, y, width, height), radius, effectiveTopSlope, effectiveBottomSlope);
    canvas.drawPath(path, Paint()..color = pink);
  }

  Path _eyePath(Rect rect, double radius, double topSlope, double bottomSlope) {
    final topLeft = rect.top + topSlope * rect.height * 0.5;
    final topRight = rect.top - topSlope * rect.height * 0.5;
    final bottomLeft = rect.bottom + bottomSlope * rect.height * 0.5;
    final bottomRight = rect.bottom - bottomSlope * rect.height * 0.5;
    final path = Path()
      ..moveTo(rect.left + radius, topLeft)
      ..quadraticBezierTo(rect.left, topLeft, rect.left, topLeft + radius)
      ..lineTo(rect.left, bottomLeft - radius)
      ..quadraticBezierTo(rect.left, bottomLeft, rect.left + radius, bottomLeft)
      ..lineTo(rect.right - radius, bottomRight)
      ..quadraticBezierTo(rect.right, bottomRight, rect.right, bottomRight - radius)
      ..lineTo(rect.right, topRight + radius)
      ..quadraticBezierTo(rect.right, topRight, rect.right - radius, topRight)
      ..close();
    return path;
  }

  void _drawScanlines(Canvas canvas, Size size) {
    final paint = Paint()..color = pink.withValues(alpha: 0.08);
    final offset = (scanlinePhase * 4) % 4;
    for (double y = offset; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  void _drawZzz(Canvas canvas, Size size, double progress) {
    final paint = Paint()..color = pink.withValues(alpha: 0.7);
    final style = const TextStyle(color: pink, fontSize: 16, fontWeight: FontWeight.w700);
    for (var index = 0; index < 3; index++) {
      final x = size.width * (0.62 + index * 0.05);
      final y = size.height * (0.55 - ((progress + index * 0.2) % 1) * 0.2);
      TextPainter(text: TextSpan(text: 'z', style: style), textDirection: TextDirection.ltr)
        ..layout()
        ..paint(canvas, Offset(x, y));
    }
    paint.color = pink;
  }

  @override
  bool shouldRepaint(covariant EyeDrawer oldDelegate) => true;
}
