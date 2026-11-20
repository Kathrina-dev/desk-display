import 'package:flutter/material.dart';
import 'face_emotions.dart';

enum MouthShape {
  line,
  uprightTriangle,
  invertedTriangle,
}

class EyeConfig {
  const EyeConfig({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.topSlope,
    required this.bottomSlope,
    required this.color,
    this.mouthWidth = 42,
    this.mouthShape = MouthShape.line,
    this.offsetX = 0,
    this.offsetY = 0,
    this.isAsymmetric = false,
  });

  final double width;
  final double height;
  final double borderRadius;
  final double topSlope;
  final double bottomSlope;
  final Color color;
  final double mouthWidth;
  final MouthShape mouthShape;
  final double offsetX;
  final double offsetY;
  final bool isAsymmetric;

  EyeConfig lerp(EyeConfig other, double t) => EyeConfig(
        width: _lerp(width, other.width, t),
        height: _lerp(height, other.height, t),
        borderRadius: _lerp(borderRadius, other.borderRadius, t),
        topSlope: _lerp(topSlope, other.topSlope, t),
        bottomSlope: _lerp(bottomSlope, other.bottomSlope, t),
        color: Color.lerp(color, other.color, t) ?? other.color,
        mouthWidth: _lerp(mouthWidth, other.mouthWidth, t),
        mouthShape: t > 0.01 ? other.mouthShape : mouthShape,
        offsetX: _lerp(offsetX, other.offsetX, t),
        offsetY: _lerp(offsetY, other.offsetY, t),
        isAsymmetric: other.isAsymmetric,
      );

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

class EyePresets {
  static const _blue = Color(0xFF42A5F5);
  static const _cyan = Color(0xFF26C6DA);
  static const _pink = Color(0xFFC44582);
  static const _crimson = Color(0xFFFF2E63);
  static const _amber = Color(0xFFFFB74D);
  static const _indigo = Color(0xFF7986CB);

  static const normal = EyeConfig(
    width: 40,
    height: 40,
    borderRadius: 9,
    topSlope: 0,
    bottomSlope: 0,
    color: _blue,
    mouthWidth: 42,
    mouthShape: MouthShape.line,
  );

  static const happy = EyeConfig(
    width: 40,
    height: 11,
    borderRadius: 6,
    topSlope: 0,
    bottomSlope: 0,
    color: _cyan,
    mouthWidth: 34,
    mouthShape: MouthShape.invertedTriangle, // ▽
  );

  static const glee = EyeConfig(
    width: 42,
    height: 8,
    borderRadius: 5,
    topSlope: 0,
    bottomSlope: 0,
    color: _cyan,
    mouthWidth: 38,
    mouthShape: MouthShape.invertedTriangle, // ▽
  );

  static const sad = EyeConfig(
    width: 40,
    height: 18,
    borderRadius: 6,
    topSlope: -0.45,
    bottomSlope: 0,
    color: _indigo,
    mouthWidth: 32,
    mouthShape: MouthShape.uprightTriangle, // △
  );

  static const worried = EyeConfig(
    width: 40,
    height: 26,
    borderRadius: 8,
    topSlope: -0.25,
    bottomSlope: 0,
    color: _amber,
    mouthWidth: 30,
    mouthShape: MouthShape.uprightTriangle, // △
  );

  static const focused = EyeConfig(
    width: 40,
    height: 16,
    borderRadius: 4,
    topSlope: 0.30,
    bottomSlope: 0,
    color: _blue,
    mouthWidth: 36,
    mouthShape: MouthShape.line,
  );

  static const annoyed = EyeConfig(
    width: 40,
    height: 13,
    borderRadius: 5,
    topSlope: 0.25,
    bottomSlope: 0,
    color: _pink,
    mouthWidth: 34,
    mouthShape: MouthShape.uprightTriangle,
  );

  static const surprised = EyeConfig(
    width: 46,
    height: 46,
    borderRadius: 16,
    topSlope: 0,
    bottomSlope: 0,
    color: _cyan,
    mouthWidth: 26,
    mouthShape: MouthShape.line,
    offsetY: -2,
  );

  static const skeptic = EyeConfig(
    width: 40,
    height: 28,
    borderRadius: 6,
    topSlope: 0.35,
    bottomSlope: 0,
    color: _amber,
    mouthWidth: 38,
    mouthShape: MouthShape.line,
    offsetY: -3,
    isAsymmetric: true,
  );

  static const frustrated = EyeConfig(
    width: 40,
    height: 13,
    borderRadius: 5,
    topSlope: 0.20,
    bottomSlope: 0,
    color: _pink,
    mouthWidth: 34,
    mouthShape: MouthShape.uprightTriangle,
    offsetY: -3,
  );

  static const unimpressed = EyeConfig(
    width: 40,
    height: 12,
    borderRadius: 5,
    topSlope: 0,
    bottomSlope: 0,
    color: _blue,
    mouthWidth: 46,
    mouthShape: MouthShape.line,
  );

  static const sleepy = EyeConfig(
    width: 40,
    height: 13,
    borderRadius: 4,
    topSlope: 0,
    bottomSlope: 0,
    color: _indigo,
    mouthWidth: 30,
    mouthShape: MouthShape.line,
    offsetY: 2,
  );

  static const suspicious = EyeConfig(
    width: 40,
    height: 22,
    borderRadius: 6,
    topSlope: 0.22,
    bottomSlope: 0,
    color: _amber,
    mouthWidth: 36,
    mouthShape: MouthShape.line,
    isAsymmetric: true,
  );

  static const squint = EyeConfig(
    width: 38,
    height: 22,
    borderRadius: 7,
    topSlope: 0.15,
    bottomSlope: 0,
    color: _blue,
    mouthWidth: 34,
    mouthShape: MouthShape.line,
    isAsymmetric: true,
  );

  static const angry = EyeConfig(
    width: 40,
    height: 22,
    borderRadius: 6,
    topSlope: 0.55,
    bottomSlope: 0,
    color: _pink,
    mouthWidth: 36,
    mouthShape: MouthShape.uprightTriangle,
  );

  static const furious = EyeConfig(
    width: 42,
    height: 28,
    borderRadius: 5,
    topSlope: 0.72,
    bottomSlope: 0,
    color: _crimson,
    mouthWidth: 40,
    mouthShape: MouthShape.uprightTriangle,
  );

  static const awe = EyeConfig(
    width: 46,
    height: 38,
    borderRadius: 13,
    topSlope: -0.10,
    bottomSlope: 0.10,
    color: _cyan,
    mouthWidth: 30,
    mouthShape: MouthShape.invertedTriangle,
  );

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
    FaceEmotion.awe: awe,
  };

  static EyeConfig forEmotion(FaceEmotion emotion) => values[emotion]!;
}