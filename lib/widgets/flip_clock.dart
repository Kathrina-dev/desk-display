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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FlipPair(value: hour),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(':', style: TextStyle(fontSize: 64, color: Color(0xFFC44582))),
        ),
        _FlipPair(value: minute),
      ],
    );
  }
}

class _FlipPair extends StatelessWidget {
  const _FlipPair({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FlipDigit(value: value[0]),
        const SizedBox(width: 8),
        _FlipDigit(value: value[1]),
      ],
    );
  }
}

class _FlipDigit extends StatelessWidget {
  const _FlipDigit({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 128,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
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
                  child: Text(value, key: ValueKey(value), style: const TextStyle(
                    color: Color(0xFFF2F2F2), fontSize: 92, fontWeight: FontWeight.w300, height: 1,
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