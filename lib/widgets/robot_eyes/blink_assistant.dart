import 'dart:math';

class BlinkAssistant {
  BlinkAssistant({this.onChanged});

  final void Function(double factor)? onChanged;
  bool randomBlink = true;
  Duration interval = const Duration(milliseconds: 4000);
  DateTime _nextBlink = DateTime.now();
  DateTime? _blinkStarted;
  int _blinkCount = 0;
  double factor = 1;
  final _random = Random();

  void doBlink() {
    _blinkStarted = DateTime.now();
    _blinkCount = _random.nextInt(4) == 0 ? 2 : 1;
    _nextBlink = DateTime.now().add(interval);
  }

  void update(DateTime now) {
    if (randomBlink && now.isAfter(_nextBlink) && _blinkStarted == null) doBlink();
    final started = _blinkStarted;
    if (started == null) return;
    final elapsed = now.difference(started).inMilliseconds;
    const half = 180;
    final cycle = half * 2;
    final total = cycle * _blinkCount;
    if (elapsed >= total) {
      factor = 1;
      _blinkStarted = null;
      onChanged?.call(factor);
      return;
    }
    final phase = elapsed % cycle;
    factor = phase < half ? 1 - (phase / half) : (phase - half) / half;
    onChanged?.call(factor.clamp(0.0, 1.0));
  }
}
