import 'face_behavior.dart';
import 'face_emotions.dart';
import 'eye_presets.dart';
import 'blink_assistant.dart';
import 'look_assistant.dart';

class Face {
  Face({void Function(FaceEmotion emotion)? onEmotionChanged}) {
    behavior = FaceBehavior(onEmotionChanged: (emotion) {
      _targetConfig = EyePresets.forEmotion(emotion);
      onEmotionChanged?.call(emotion);
    });
    look = LookAssistant(onChanged: (left, right) {
      leftLook = left;
      rightLook = right;
    });
    blink = BlinkAssistant();
  }

  late final FaceBehavior behavior;
  late final LookAssistant look;
  late final BlinkAssistant blink;
  EyeConfig _config = EyePresets.normal;
  EyeConfig _targetConfig = EyePresets.normal;
  LookTransform leftLook = const LookTransform();
  LookTransform rightLook = const LookTransform();
  FaceEmotion emotion = FaceEmotion.normal;

  EyeConfig get config => _config;

  void setTargetConfig(EyeConfig target) => _targetConfig = target;

  void goToEmotion(FaceEmotion next) {
    emotion = next;
    _targetConfig = EyePresets.forEmotion(next);
    if (behavior.currentEmotion != next) behavior.goToEmotion(next);
  }

  void update(Duration dt) {
    final now = DateTime.now();
    behavior.update(now);
    look.update(dt);
    blink.update(now);
    _config = _config.lerp(_targetConfig, (dt.inMicroseconds / 16667).clamp(0.08, 0.28));
  }
}
