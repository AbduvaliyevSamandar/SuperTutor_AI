import 'package:audioplayers/audioplayers.dart';

class SoundEffects {
  SoundEffects._();
  static final _correct = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  static final _wrong = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  static Future<void> correct() async {
    try {
      await _correct.stop();
      await _correct.play(AssetSource('sounds/correct.wav'));
    } catch (_) {}
  }

  static Future<void> wrong() async {
    try {
      await _wrong.stop();
      await _wrong.play(AssetSource('sounds/wrong.wav'));
    } catch (_) {}
  }
}
