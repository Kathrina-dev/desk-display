import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class FlipClock extends StatefulWidget {
  const FlipClock({super.key});

  @override
  State<FlipClock> createState() => _FlipClockState();
}

class _FlipClockState extends State<FlipClock> {
  late DateTime _now;
  Timer? _ticker;

  static const _accentBlue = Color(0xFF42A5F5);

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
    final colonVisible = _now.second.isEven;

    return LayoutBuilder(
      builder: (context, constraints) {
        final digitWidth = ((constraints.maxWidth - 96) / 4).clamp(56.0, 210.0);
        final digitHeight = (constraints.maxHeight * 0.78).clamp(96.0, digitWidth * 1.38);

        return Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FlipPair(value: hour, width: digitWidth, height: digitHeight),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: digitWidth * 0.14),
                  child: _ColonDots(
                    height: digitHeight,
                    color: _accentBlue,
                    active: colonVisible,
                  ),
                ),
                _FlipPair(value: minute, width: digitWidth, height: digitHeight),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ColonDots extends StatelessWidget {
  const _ColonDots({
    required this.height,
    required this.color,
    required this.active,
  });

  final double height;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final dotSize = (height * 0.085).clamp(8.0, 18.0);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      opacity: active ? 1.0 : 0.28,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dot(dotSize),
          SizedBox(height: height * 0.22),
          _dot(dotSize),
        ],
      ),
    );
  }

  Widget _dot(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.55),
            blurRadius: size * 1.1,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _FlipPair extends StatelessWidget {
  const _FlipPair({
    required this.value,
    required this.width,
    required this.height,
  });

  final String value;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AppleFlipDigit(value: value[0], width: width, height: height),
        SizedBox(width: width * 0.08),
        _AppleFlipDigit(value: value[1], width: width, height: height),
      ],
    );
  }
}

class _AppleFlipDigit extends StatefulWidget {
  const _AppleFlipDigit({
    required this.value,
    required this.width,
    required this.height,
  });

  final String value;
  final double width;
  final double height;

  @override
  State<_AppleFlipDigit> createState() => _AppleFlipDigitState();
}

class _AppleFlipDigitState extends State<_AppleFlipDigit>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late String _currentValue;
  late String _previousValue;

  static const _digitBlue = Color(0xFF64B5F6);
  static const _digitTint = Color(0xFFE3F2FD);

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _previousValue = widget.value;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..value = 1.0;
  }

  @override
  void didUpdateWidget(covariant _AppleFlipDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _currentValue) {
      _previousValue = _currentValue;
      _currentValue = widget.value;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildHalfCard(String digit, {required bool isTop, double shade = 0.0}) {
    final radius = Radius.circular(widget.width * 0.14);
    final borderRadius = isTop
        ? BorderRadius.vertical(top: radius)
        : BorderRadius.vertical(bottom: radius);

    return Container(
      width: widget.width,
      height: widget.height / 2,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isTop
              ? const [Color(0xFF191C22), Color(0xFF121419)]
              : const [Color(0xFF101217), Color(0xFF0C0D11)],
        ),
        border: Border.all(
          color: const Color(0xFF42A5F5).withValues(alpha: 0.14),
          width: 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            OverflowBox(
              maxHeight: widget.height,
              minHeight: widget.height,
              alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
              child: Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_digitTint, _digitBlue],
                    stops: [0.15, 0.92],
                  ).createShader(bounds),
                  child: Text(
                    digit,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: widget.height * 0.72,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -2,
                      height: 1.0,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
            if (shade > 0)
              Container(color: Colors.black.withValues(alpha: shade.clamp(0.0, 0.55))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.width * 0.14;
    final notchWidth = (widget.width * 0.025).clamp(2.5, 5.0);
    final notchHeight = (widget.height * 0.07).clamp(8.0, 16.0);

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.75),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFF42A5F5).withValues(alpha: 0.06),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_controller.value);
          final isFirstHalf = t < 0.5;
          final angle = isFirstHalf
              ? (t * math.pi) // 0 -> pi/2 (top flap folds down)
              : ((1.0 - t) * math.pi); // pi/2 -> 0 (bottom flap unfolds)

          return Stack(
            children: [
              // Static background halves
              Column(
                children: [
                  _buildHalfCard(_currentValue, isTop: true),
                  _buildHalfCard(
                    isFirstHalf ? _previousValue : _currentValue,
                    isTop: false,
                    shade: isFirstHalf ? t * 0.45 : (1.0 - t) * 0.35,
                  ),
                ],
              ),

              // Active folding flap
              if (t < 1.0)
                Align(
                  alignment: isFirstHalf ? Alignment.topCenter : Alignment.bottomCenter,
                  child: Transform(
                    alignment: isFirstHalf ? Alignment.bottomCenter : Alignment.topCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0018)
                      ..rotateX(isFirstHalf ? angle : -angle),
                    child: _buildHalfCard(
                      isFirstHalf ? _previousValue : _currentValue,
                      isTop: isFirstHalf,
                      shade: isFirstHalf ? t * 0.6 : (1.0 - t) * 0.5,
                    ),
                  ),
                ),

              // Hairline split seam
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 1.5,
                  color: const Color(0xFF060709),
                ),
              ),

              // Subtle Apple-style side hinge notches
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: notchWidth,
                  height: notchHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF060709),
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(notchWidth)),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: notchWidth,
                  height: notchHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF060709),
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(notchWidth)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}