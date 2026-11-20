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
  Duration interval = const Duration(milliseconds: 6500);
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

    final moveX = 0.20 * x;
    final moveY = 0.14 * y;
    final verticalScale = 1.0 - y.abs() * 0.18;

    // 3D perspective head-turn scaling: near eye grows slightly, opposite eye shrinks
    final towardScaleX = 1.0 + x.abs() * 0.06;
    final oppositeScaleX = 1.0 - x.abs() * 0.14;
    final towardScaleY = verticalScale * (1.0 + x.abs() * 0.08);
    final oppositeScaleY = verticalScale * (1.0 - x.abs() * 0.20);

    targetLeft = x <= 0
        ? LookTransform(moveX: moveX, moveY: moveY, scaleX: towardScaleX, scaleY: towardScaleY)
        : LookTransform(moveX: moveX, moveY: moveY, scaleX: oppositeScaleX, scaleY: oppositeScaleY);
    targetRight = x >= 0
        ? LookTransform(moveX: moveX, moveY: moveY, scaleX: towardScaleX, scaleY: towardScaleY)
        : LookTransform(moveX: moveX, moveY: moveY, scaleX: oppositeScaleX, scaleY: oppositeScaleY);
  }

  void update(Duration dt) {
    final amount = (dt.inMicroseconds / 280000).clamp(0.0, 1.0);
    currentLeft = currentLeft.lerp(targetLeft, amount);
    currentRight = currentRight.lerp(targetRight, amount);
    onChanged?.call(currentLeft, currentRight);

    if (!randomLook) return;
    if (_holdTarget > Duration.zero) {
      _holdTarget -= dt;
      return;
    }
    _sinceLook += dt;
    if (_sinceLook < interval) return;
    _sinceLook = Duration.zero;

    if (_random.nextDouble() < 0.40) {
      // Glance toward top-left or top-right keyboard corner and hold for 5 seconds
      lookAt(_random.nextBool() ? -0.78 : 0.78, -0.65);
      _holdTarget = const Duration(seconds: 5);
    } else {
      lookAt((_random.nextDouble() * 1.1) - 0.55, (_random.nextDouble() * 0.7) - 0.35);
    }
  }
}
