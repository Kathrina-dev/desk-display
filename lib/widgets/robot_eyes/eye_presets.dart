import 'face_emotions.dart';

class EyeConfig {
  const EyeConfig({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.topSlope,
    required this.bottomSlope,
    this.offsetX = 0,
    this.offsetY = 0,
    this.isAsymmetric = false,
  });

  final double width;
  final double height;
  final double borderRadius;
  final double topSlope;
  final double bottomSlope;
  final double offsetX;
  final double offsetY;
  final bool isAsymmetric;

  EyeConfig lerp(EyeConfig other, double t) => EyeConfig(
        width: _lerp(width, other.width, t),
        height: _lerp(height, other.height, t),
        borderRadius: _lerp(borderRadius, other.borderRadius, t),
        topSlope: _lerp(topSlope, other.topSlope, t),
        bottomSlope: _lerp(bottomSlope, other.bottomSlope, t),
        offsetX: _lerp(offsetX, other.offsetX, t),
        offsetY: _lerp(offsetY, other.offsetY, t),
        isAsymmetric: other.isAsymmetric,
      );

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

class EyePresets {
  static const normal = EyeConfig(width: 40, height: 40, borderRadius: 8, topSlope: 0, bottomSlope: 0);
  static const happy = EyeConfig(width: 40, height: 10, borderRadius: 6, topSlope: 0, bottomSlope: 0);
  static const glee = EyeConfig(width: 40, height: 8, borderRadius: 5, topSlope: 0, bottomSlope: 0);
  static const sad = EyeConfig(width: 40, height: 15, borderRadius: 5, topSlope: -0.5, bottomSlope: 0);
  static const worried = EyeConfig(width: 40, height: 25, borderRadius: 8, topSlope: -0.1, bottomSlope: 0);
  static const focused = EyeConfig(width: 40, height: 14, borderRadius: 3, topSlope: 0.2, bottomSlope: 0);
  static const annoyed = EyeConfig(width: 40, height: 12, borderRadius: 5, topSlope: 0, bottomSlope: 0);
  static const surprised = EyeConfig(width: 45, height: 45, borderRadius: 16, topSlope: 0, bottomSlope: 0, offsetX: -2);
  static const skeptic = EyeConfig(width: 40, height: 26, borderRadius: 6, topSlope: 0.3, bottomSlope: 0, offsetY: -6, isAsymmetric: true);
  static const frustrated = EyeConfig(width: 40, height: 12, borderRadius: 5, topSlope: 0, bottomSlope: 0, offsetX: 3, offsetY: -5);
  static const unimpressed = EyeConfig(width: 40, height: 12, borderRadius: 5, topSlope: 0, bottomSlope: 0, offsetX: 3);
  static const sleepy = EyeConfig(width: 40, height: 14, borderRadius: 3, topSlope: -0.5, bottomSlope: -0.5, offsetY: -2, isAsymmetric: true);
  static const suspicious = EyeConfig(width: 40, height: 22, borderRadius: 6, topSlope: 0, bottomSlope: 0, isAsymmetric: true);
  static const squint = EyeConfig(width: 35, height: 35, borderRadius: 8, topSlope: 0, bottomSlope: 0, offsetX: -10, offsetY: -3, isAsymmetric: true);
  static const angry = EyeConfig(width: 40, height: 20, borderRadius: 7, topSlope: 0.45, bottomSlope: 0, offsetX: -3);
  static const furious = EyeConfig(width: 40, height: 30, borderRadius: 5, topSlope: 0.60, bottomSlope: 0, offsetX: -2);
  static const scared = EyeConfig(width: 40, height: 40, borderRadius: 10, topSlope: -0.1, bottomSlope: 0, offsetX: -3);
  static const awe = EyeConfig(width: 45, height: 35, borderRadius: 12, topSlope: -0.1, bottomSlope: 0.1, offsetX: 2);

  static const values = <FaceEmotion, EyeConfig>{
    FaceEmotion.normal: normal,
    FaceEmotion.angry: angry,
    FaceEmotion.glee: glee,
    FaceEmotion.happy: happy,
    FaceEmotion.sad: sad,
    FaceEmotion.worried: worried,
    FaceEmotion.focused: focused,
    FaceEmotion.annoyed: annoyed,
    FaceEmotion.surprised: surprised,
    FaceEmotion.skeptic: skeptic,
    FaceEmotion.frustrated: frustrated,
    FaceEmotion.unimpressed: unimpressed,
    FaceEmotion.sleepy: sleepy,
    FaceEmotion.suspicious: suspicious,
    FaceEmotion.squint: squint,
    FaceEmotion.furious: furious,
    FaceEmotion.scared: scared,
    FaceEmotion.awe: awe,
  };

  static EyeConfig forEmotion(FaceEmotion emotion) => values[emotion]!;
}
