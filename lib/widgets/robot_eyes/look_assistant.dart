import 'dart:math';

class LookTransform {
  const LookTransform({this.moveX = 0, this.moveY = 0, this.scaleX = 1, this.scaleY = 1});

  final double moveX;
  final double moveY;
  final double scaleX;
  final double scaleY;

  LookTransform lerp(LookTransform other, double amount) => LookTransform(
        moveX: moveX + (other.moveX - moveX) * amount,
        moveY: moveY + (other.moveY - moveY) * amount,
        scaleX: scaleX + (other.scaleX - scaleX) * amount,
        scaleY: scaleY + (other.scaleY - scaleY) * amount,
      );
}

class LookAssistant {
  LookAssistant({this.onChanged});

  final void Function(LookTransform left, LookTransform right)? onChanged;
  bool randomLook = true;
  Duration interval = const Duration(milliseconds: 4000);
  double x = 0;
  double y = 0;
  LookTransform currentLeft = const LookTransform();
  LookTransform currentRight = const LookTransform();
  LookTransform targetLeft = const LookTransform();
  LookTransform targetRight = const LookTransform();
  Duration _sinceLook = Duration.zero;
  Duration _holdTarget = Duration.zero;
  final _random = Random();

  void lookAt(double nextX, double nextY) {
    x = nextX.clamp(-1.0, 1.0);
    y = nextY.clamp(-1.0, 1.0);
    // These are normalized here and scaled to the phone canvas by EyeDrawer.
    final moveX = 0.22 * x;
    final moveY = 0.15 * y;
    final scaleY = 1.0 - y.abs() * 0.4;
    final towardScaleX = 1.0 + x.abs() * 0.05;
    final oppositeScaleX = 1.0 - x.abs() * 0.12;
    final towardScaleY = scaleY * (1.0 + x.abs() * 0.08);
    final oppositeScaleY = scaleY * (1.0 - x.abs() * 0.18);
    targetLeft = x < 0
        ? LookTransform(moveX: moveX, moveY: moveY, scaleX: towardScaleX, scaleY: towardScaleY)
        : LookTransform(moveX: moveX, moveY: moveY, scaleX: oppositeScaleX, scaleY: oppositeScaleY);
    targetRight = x > 0
        ? LookTransform(moveX: moveX, moveY: moveY, scaleX: towardScaleX, scaleY: towardScaleY)
        : LookTransform(moveX: moveX, moveY: moveY, scaleX: oppositeScaleX, scaleY: oppositeScaleY);
  }

  void update(Duration dt) {
    final amount = (dt.inMicroseconds / 250000).clamp(0.0, 1.0);
    currentLeft = currentLeft.lerp(targetLeft, amount);
    currentRight = currentRight.lerp(targetRight, amount);
    onChanged?.call(currentLeft, currentRight);
    if (!randomLook) return;
    _sinceLook += dt;
    if (_holdTarget > Duration.zero) {
      _holdTarget -= dt;
      return;
    }
    if (_sinceLook < interval) return;
    _sinceLook = Duration.zero;
    if (_random.nextDouble() < 0.4) {
      lookAt(_random.nextBool() ? -0.75 : 0.75, -0.65);
      _holdTarget = const Duration(seconds: 5);
    } else {
      lookAt((_random.nextDouble() * 1.2) - 0.6, (_random.nextDouble() * 0.8) - 0.4);
    }
  }
}
