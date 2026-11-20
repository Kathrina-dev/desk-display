import 'package:flutter/material.dart';

import 'eye_presets.dart';
import 'look_assistant.dart';

enum IdleAction {
  none,
  visorScan,
  coffeeGlance,
  sparkleBurst,
}

class EyeDrawer extends CustomPainter {
  EyeDrawer({
    required this.left,
    required this.right,
    required this.lookLeft,
    required this.lookRight,
    required this.blinkFactor,
    this.scanlinePhase = 0,
    this.zProgress = 0,
    this.idleAction = IdleAction.none,
    this.idleProgress = 0,
    super.repaint,
  });

  final EyeConfig left;
  final EyeConfig right;
  final LookTransform lookLeft;
  final LookTransform lookRight;
  final double blinkFactor;
  final double scanlinePhase;
  final double zProgress;
  final IdleAction idleAction;
  final double idleProgress;

  static const background = Color(0xFF090909);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(background, BlendMode.src);
    final center = Offset(size.width / 2, size.height * 0.42);
    final activeColor = left.color;

    Rect? leftRect;
    Rect? rightRect;
    _drawEye(canvas, size, center, left, lookLeft, true, (r) => leftRect = r);
    _drawEye(canvas, size, center, right, lookRight, false, (r) => rightRect = r);

    _drawMouth(canvas, size, center, left, lookLeft, lookRight);
    _drawScanlines(canvas, size, activeColor);

    if (idleAction == IdleAction.visorScan && leftRect != null && rightRect != null) {
      _drawVisorBeam(canvas, leftRect!, rightRect!, activeColor, idleProgress);
    } else if (idleAction == IdleAction.coffeeGlance) {
      _drawHologramMug(canvas, size, activeColor, idleProgress);
    } else if (idleAction == IdleAction.sparkleBurst) {
      _drawSparkles(canvas, size, center, activeColor, idleProgress);
    }

    if (zProgress > 0) {
      final anchor = rightRect?.topRight ?? Offset(size.width * 0.65, size.height * 0.28);
      _drawZzz(canvas, size, anchor, activeColor, zProgress);
    }
  }

  void _drawEye(
    Canvas canvas,
    Size size,
    Offset center,
    EyeConfig config,
    LookTransform look,
    bool isLeft,
    void Function(Rect) onRect,
  ) {
    final scale = size.height / 64.0;
    final asymmetryY = config.isAsymmetric ? (isLeft ? 1.06 : 0.78) : 1.0;
    final asymmetryX = config.isAsymmetric ? (isLeft ? 1.04 : 0.90) : 1.0;

    final width = (config.width * scale).clamp(0.0, size.width * 0.26) * look.scaleX * asymmetryX;
    final height = (config.height * scale * look.scaleY * asymmetryY * blinkFactor).clamp(3.0, size.height * 0.65);

    final x = center.dx +
        config.offsetX * scale +
        look.moveX * size.width +
        (isLeft ? -width - 12 * scale : 12 * scale);
    final y = center.dy + config.offsetY * scale + look.moveY * size.height - height / 2;
    final radius = (config.borderRadius * scale).clamp(0.0, height / 2);

    final effectiveTopSlope = isLeft
        ? -config.topSlope
        : (config.isAsymmetric ? config.topSlope * 0.4 : config.topSlope);
    final effectiveBottomSlope = isLeft ? -config.bottomSlope : config.bottomSlope;

    final rect = Rect.fromLTWH(x, y, width, height);
    onRect(rect);
    final path = _eyePath(rect, radius, effectiveTopSlope, effectiveBottomSlope);

    canvas.drawPath(
      path,
      Paint()
        ..color = config.color.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawPath(path, Paint()..color = config.color);
  }

  void _drawMouth(
    Canvas canvas,
    Size size,
    Offset center,
    EyeConfig config,
    LookTransform leftLook,
    LookTransform rightLook,
  ) {
    final scale = size.height / 64.0;
    final avgMoveX = (leftLook.moveX + rightLook.moveX) * 0.5 * size.width;
    final avgMoveY = (leftLook.moveY + rightLook.moveY) * 0.5 * size.height;

    final mouthWidth = (config.mouthWidth * scale * 0.72).clamp(36.0, 110.0);
    final mouthHeight = (6.2 * scale).clamp(24.0, 48.0);
    final mouthCenter = Offset(
      center.dx + avgMoveX * 0.75,
      center.dy + 22 * scale + avgMoveY * 0.65,
    );

    final glowPaint = Paint()
      ..color = config.color.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final fillPaint = Paint()
      ..color = config.color
      ..style = PaintingStyle.fill;

    if (config.mouthShape == MouthShape.line) {
      final barHeight = (2.2 * scale).clamp(6.0, 11.0);
      final barRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: mouthCenter,
          width: config.mouthWidth * scale,
          height: barHeight,
        ),
        Radius.circular(barHeight / 2),
      );
      canvas.drawRRect(barRect, glowPaint);
      canvas.drawRRect(barRect, fillPaint);
      return;
    }

    final path = Path();
    if (config.mouthShape == MouthShape.uprightTriangle) {
      // △ Upright solid triangle (happy / glee / awe)
      path
        ..moveTo(mouthCenter.dx, mouthCenter.dy - mouthHeight * 0.55)
        ..lineTo(mouthCenter.dx + mouthWidth * 0.5, mouthCenter.dy + mouthHeight * 0.45)
        ..lineTo(mouthCenter.dx - mouthWidth * 0.5, mouthCenter.dy + mouthHeight * 0.45)
        ..close();
    } else {
      // ▽ Inverted solid triangle (angry / furious / annoyed / frustrated)
      path
        ..moveTo(mouthCenter.dx - mouthWidth * 0.5, mouthCenter.dy - mouthHeight * 0.45)
        ..lineTo(mouthCenter.dx + mouthWidth * 0.5, mouthCenter.dy - mouthHeight * 0.45)
        ..lineTo(mouthCenter.dx, mouthCenter.dy + mouthHeight * 0.55)
        ..close();
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, fillPaint);
  }

  void _drawVisorBeam(Canvas canvas, Rect leftRect, Rect rightRect, Color color, double progress) {
    final sweep = (progress * 2) <= 1 ? (progress * 2) : (2 - progress * 2);
    final scanX = leftRect.left + (rightRect.right - leftRect.left) * sweep;
    final top = (leftRect.top < rightRect.top ? leftRect.top : rightRect.top) - 8;
    final bottom = (leftRect.bottom > rightRect.bottom ? leftRect.bottom : rightRect.bottom) + 8;

    canvas.drawLine(
      Offset(scanX, top),
      Offset(scanX, bottom),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _drawHologramMug(Canvas canvas, Size size, Color color, double progress) {
    final alpha = progress < 0.15
        ? progress / 0.15
        : (progress > 0.85 ? (1.0 - progress) / 0.15 : 1.0);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.75 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final cx = size.width * 0.76;
    final cy = size.height * 0.76;
    // Mug body
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 28, height: 24), const Radius.circular(4)),
      paint,
    );
    // Mug handle
    canvas.drawArc(Rect.fromCenter(center: Offset(cx + 15, cy), width: 12, height: 14), -1.5, 3.1, false, paint);
    // Rising steam lines
    final steamOffset = (progress * 12) % 8;
    for (final dx in [-6.0, 2.0]) {
      canvas.drawLine(Offset(cx + dx, cy - 18 - steamOffset), Offset(cx + dx + 3, cy - 26 - steamOffset), paint);
    }
  }

  void _drawSparkles(Canvas canvas, Size size, Offset center, Color color, double progress) {
    final alpha = (1.0 - progress).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final offsets = [
      Offset(-size.width * 0.28, -size.height * 0.22 - progress * 24),
      Offset(size.width * 0.28, -size.height * 0.20 - progress * 28),
      Offset(0, -size.height * 0.30 - progress * 20),
    ];
    for (final off in offsets) {
      final p = center + off;
      canvas.drawLine(Offset(p.dx - 7, p.dy), Offset(p.dx + 7, p.dy), paint);
      canvas.drawLine(Offset(p.dx, p.dy - 7), Offset(p.dx, p.dy + 7), paint);
    }
  }

  Path _eyePath(Rect rect, double radius, double topSlope, double bottomSlope) {
    final topLeft = rect.top + topSlope * rect.height * 0.5;
    final topRight = rect.top - topSlope * rect.height * 0.5;
    final bottomLeft = rect.bottom + bottomSlope * rect.height * 0.5;
    final bottomRight = rect.bottom - bottomSlope * rect.height * 0.5;

    return Path()
      ..moveTo(rect.left + radius, topLeft)
      ..quadraticBezierTo(rect.left, topLeft, rect.left, topLeft + radius)
      ..lineTo(rect.left, bottomLeft - radius)
      ..quadraticBezierTo(rect.left, bottomLeft, rect.left + radius, bottomLeft)
      ..lineTo(rect.right - radius, bottomRight)
      ..quadraticBezierTo(rect.right, bottomRight, rect.right, bottomRight - radius)
      ..lineTo(rect.right, topRight + radius)
      ..quadraticBezierTo(rect.right, topRight, rect.right - radius, topRight)
      ..close();
  }

  void _drawScanlines(Canvas canvas, Size size, Color activeColor) {
    final paint = Paint()..color = activeColor.withValues(alpha: 0.06);
    final offset = (scanlinePhase * 4) % 4;
    for (double y = offset; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  void _drawZzz(Canvas canvas, Size size, Offset eyeTopRight, Color color, double progress) {
    final baseFontSize = (size.height * 0.075).clamp(22.0, 36.0);
    for (var index = 0; index < 3; index++) {
      final cycle = (progress + index * 0.33) % 1.0;
      final alpha = (1.0 - cycle).clamp(0.15, 0.95);
      final fontSize = baseFontSize * (0.75 + index * 0.22);

      final x = (eyeTopRight.dx + 12 + index * (baseFontSize * 0.85) + cycle * 14)
          .clamp(0.0, size.width - fontSize * 1.5);
      final y = (eyeTopRight.dy - baseFontSize * 0.6 - cycle * (size.height * 0.22))
          .clamp(12.0, size.height * 0.45);

      final style = TextStyle(
        color: color.withValues(alpha: alpha),
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      );
      TextPainter(
        text: TextSpan(text: 'Z', style: style),
        textDirection: TextDirection.ltr,
      )
        ..layout()
        ..paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant EyeDrawer oldDelegate) => true;
}
