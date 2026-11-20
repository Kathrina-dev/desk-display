import 'dart:async';

import 'package:flutter/material.dart';

class FlipClock extends StatefulWidget {
  const FlipClock({super.key});

  @override
  State<FlipClock> createState() => _FlipClockState();
}

class _FlipClockState extends State<FlipClock> {
  late DateTime _now;
  Timer? _ticker;

  static const _litWhite = Color(0xFFF8FAFC);
  static const _unlitGhost = Color(0xFF141518);

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hour = _now.hour.toString().padLeft(2, '0');
    final minute = _now.minute.toString().padLeft(2, '0');
    final colonLit = _now.second.isEven;

    return LayoutBuilder(
      builder: (context, constraints) {
        final digitWidth = ((constraints.maxWidth - 110) / 4).clamp(48.0, 190.0);
        final digitHeight = (constraints.maxHeight * 0.72).clamp(88.0, digitWidth * 1.72);

        return Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SevenSegmentDigit(
                  digit: int.parse(hour[0]),
                  width: digitWidth,
                  height: digitHeight,
                  litColor: _litWhite,
                  unlitColor: _unlitGhost,
                ),
                SizedBox(width: digitWidth * 0.22),
                _SevenSegmentDigit(
                  digit: int.parse(hour[1]),
                  width: digitWidth,
                  height: digitHeight,
                  litColor: _litWhite,
                  unlitColor: _unlitGhost,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: digitWidth * 0.24),
                  child: _SegmentColon(
                    height: digitHeight,
                    litColor: _litWhite,
                    unlitColor: _unlitGhost,
                    lit: colonLit,
                  ),
                ),
                _SevenSegmentDigit(
                  digit: int.parse(minute[0]),
                  width: digitWidth,
                  height: digitHeight,
                  litColor: _litWhite,
                  unlitColor: _unlitGhost,
                ),
                SizedBox(width: digitWidth * 0.22),
                _SevenSegmentDigit(
                  digit: int.parse(minute[1]),
                  width: digitWidth,
                  height: digitHeight,
                  litColor: _litWhite,
                  unlitColor: _unlitGhost,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SegmentColon extends StatelessWidget {
  const _SegmentColon({
    required this.height,
    required this.litColor,
    required this.unlitColor,
    required this.lit,
  });

  final double height;
  final Color litColor;
  final Color unlitColor;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final size = (height * 0.08).clamp(7.0, 16.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(size),
        SizedBox(height: height * 0.24),
        _dot(size),
      ],
    );
  }

  Widget _dot(double size) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: lit ? litColor : unlitColor,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: lit
            ? [
                BoxShadow(
                  color: litColor.withValues(alpha: 0.45),
                  blurRadius: size * 1.2,
                  spreadRadius: 0.5,
                ),
              ]
            : const [],
      ),
    );
  }
}

class _SevenSegmentDigit extends StatelessWidget {
  const _SevenSegmentDigit({
    required this.digit,
    required this.width,
    required this.height,
    required this.litColor,
    required this.unlitColor,
  });

  final int digit;
  final double width;
  final double height;
  final Color litColor;
  final Color unlitColor;

  // Bitmask for segments [a, b, c, d, e, f, g]
  //   a
  // f   b
  //   g
  // e   c
  //   d
  static const _digitMasks = <int, List<bool>>{
    0: [true, true, true, true, true, true, false],
    1: [false, true, true, false, false, false, false],
    2: [true, true, false, true, true, false, true],
    3: [true, true, true, true, false, false, true],
    4: [false, true, true, false, false, true, true],
    5: [true, false, true, true, false, true, true],
    6: [true, false, true, true, true, true, true],
    7: [true, true, true, false, false, false, false],
    8: [true, true, true, true, true, true, true],
    9: [true, true, true, true, false, true, true],
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SevenSegmentPainter(
          activeSegments: _digitMasks[digit] ?? _digitMasks[8]!,
          litColor: litColor,
          unlitColor: unlitColor,
        ),
      ),
    );
  }
}

class _SevenSegmentPainter extends CustomPainter {
  const _SevenSegmentPainter({
    required this.activeSegments,
    required this.litColor,
    required this.unlitColor,
  });

  final List<bool> activeSegments;
  final Color litColor;
  final Color unlitColor;

  @override
  void paint(Canvas canvas, Size size) {
    final t = (size.width * 0.145).clamp(6.0, 22.0); // Segment thickness
    final halfT = t / 2;
    final gap = (t * 0.24).clamp(1.8, 5.0); // Clean miter spacing between segments
    final midY = size.height / 2;

    final segments = <Path>[
      // a: top horizontal
      _horizontalSegment(
        left: halfT + gap,
        right: size.width - halfT - gap,
        centerY: halfT,
        thickness: t,
      ),
      // b: top-right vertical
      _verticalSegment(
        top: halfT + gap,
        bottom: midY - gap,
        centerX: size.width - halfT,
        thickness: t,
      ),
      // c: bottom-right vertical
      _verticalSegment(
        top: midY + gap,
        bottom: size.height - halfT - gap,
        centerX: size.width - halfT,
        thickness: t,
      ),
      // d: bottom horizontal
      _horizontalSegment(
        left: halfT + gap,
        right: size.width - halfT - gap,
        centerY: size.height - halfT,
        thickness: t,
      ),
      // e: bottom-left vertical
      _verticalSegment(
        top: midY + gap,
        bottom: size.height - halfT - gap,
        centerX: halfT,
        thickness: t,
      ),
      // f: top-left vertical
      _verticalSegment(
        top: halfT + gap,
        bottom: midY - gap,
        centerX: halfT,
        thickness: t,
      ),
      // g: middle horizontal
      _horizontalSegment(
        left: halfT + gap,
        right: size.width - halfT - gap,
        centerY: midY,
        thickness: t,
      ),
    ];

    final unlitPaint = Paint()
      ..color = unlitColor
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = litColor.withValues(alpha: 0.24)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, t * 0.85);

    final litPaint = Paint()
      ..color = litColor
      ..style = PaintingStyle.fill;

    // Pass 1: Draw subtle unlit ghost segments
    for (var i = 0; i < 7; i++) {
      if (!activeSegments[i]) {
        canvas.drawPath(segments[i], unlitPaint);
      }
    }

    // Pass 2: Draw active white segments with soft OLED bloom
    for (var i = 0; i < 7; i++) {
      if (activeSegments[i]) {
        canvas.drawPath(segments[i], glowPaint);
        canvas.drawPath(segments[i], litPaint);
      }
    }
  }

  /// Beveled hexagonal horizontal bar
  Path _horizontalSegment({
    required double left,
    required double right,
    required double centerY,
    required double thickness,
  }) {
    final h = thickness / 2;
    return Path()
      ..moveTo(left, centerY)
      ..lineTo(left + h, centerY - h)
      ..lineTo(right - h, centerY - h)
      ..lineTo(right, centerY)
      ..lineTo(right - h, centerY + h)
      ..lineTo(left + h, centerY + h)
      ..close();
  }

  /// Beveled hexagonal vertical bar
  Path _verticalSegment({
    required double top,
    required double bottom,
    required double centerX,
    required double thickness,
  }) {
    final h = thickness / 2;
    return Path()
      ..moveTo(centerX, top)
      ..lineTo(centerX + h, top + h)
      ..lineTo(centerX + h, bottom - h)
      ..lineTo(centerX, bottom)
      ..lineTo(centerX - h, bottom - h)
      ..lineTo(centerX - h, top + h)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _SevenSegmentPainter oldDelegate) =>
      oldDelegate.activeSegments != activeSegments ||
      oldDelegate.litColor != litColor ||
      oldDelegate.unlitColor != unlitColor;
}