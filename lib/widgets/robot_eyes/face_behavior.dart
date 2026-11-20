import 'dart:math';

import 'face_emotions.dart';

typedef EmotionChanged = void Function(FaceEmotion emotion);

class FaceBehavior {
  FaceBehavior({this.onEmotionChanged});

  final EmotionChanged? onEmotionChanged;
  final _random = Random();
  final Map<FaceEmotion, double> weights = {
    for (final emotion in FaceEmotion.values) emotion: 0,
  };
  FaceEmotion currentEmotion = FaceEmotion.normal;
  bool randomBehavior = true;
  Duration interval = const Duration(seconds: 10);
  DateTime _nextDecision = DateTime.now();

  void setEmotion(FaceEmotion emotion, double weight) => weights[emotion] = weight;

  void clear() {
    for (final emotion in FaceEmotion.values) {
      weights[emotion] = 0;
    }
  }

  void goToEmotion(FaceEmotion emotion) {
    currentEmotion = emotion;
    onEmotionChanged?.call(emotion);
  }

  FaceEmotion getRandomEmotion() {
    final total = weights.values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) return FaceEmotion.normal;
    var cursor = _random.nextDouble() * total;
    for (final entry in weights.entries) {
      cursor -= entry.value;
      if (cursor <= 0) return entry.key;
    }
    return FaceEmotion.normal;
  }

  void update(DateTime now) {
    if (!randomBehavior || now.isBefore(_nextDecision)) return;
    _nextDecision = now.add(interval);
    final emotion = getRandomEmotion();
    if (emotion != currentEmotion) goToEmotion(emotion);
  }
}
