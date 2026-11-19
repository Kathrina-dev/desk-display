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
    return LayoutBuilder(
      builder: (context, constraints) {
        final digitWidth = ((constraints.maxWidth - 80) / 4).clamp(54.0, 220.0);
        final digitHeight = (constraints.maxHeight * 0.82)
            .clamp(92.0, digitWidth / 0.72);
        final separatorSize = digitHeight * 0.54;
        return Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FlipPair(value: hour, width: digitWidth, height: digitHeight),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: digitWidth * 0.08),
                  child: Text(':', style: TextStyle(
                    fontSize: separatorSize,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFC44582),
                    height: 1,
                  )),
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

class _FlipPair extends StatelessWidget {
  const _FlipPair({required this.value, required this.width, required this.height});

  final String value;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FlipDigit(value: value[0], width: width, height: height),
        SizedBox(width: width * 0.08),
        _FlipDigit(value: value[1], width: width, height: height),
      ],
    );
  }
}

class _FlipDigit extends StatelessWidget {
  const _FlipDigit({required this.value, required this.width, required this.height});

  final String value;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * 0.08),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF141414)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 520),
                  transitionBuilder: (child, animation) => AnimatedBuilder(
                    animation: animation,
                    child: child,
                    builder: (context, child) {
                      final transform = Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX((1 - animation.value) * mathPi);
                      return Transform(alignment: Alignment.center, transform: transform, child: child);
                    },
                  ),
                  child: Text(value, key: ValueKey(value), style: TextStyle(
                    color: Color(0xFFF2F2F2), fontSize: height * 0.72,
                    fontWeight: FontWeight.w900, height: 1,
                  )),
                ),
              ),
              const Align(alignment: Alignment.center, child: Divider(height: 1, color: Color(0x66202020))),
            ],
          ),
        ),
      ),
    );
  }
}

const mathPi = 3.141592653589793;