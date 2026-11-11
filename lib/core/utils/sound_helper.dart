import 'package:audioplayers/audioplayers.dart';

class SoundHelper {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playAlert({bool isError = false}) async {
    try {
      final fileName = isError ? 'sounds/alert_error.mp3' : 'sounds/alert.mp3';
      await _player.stop();
      await _player.play(AssetSource(fileName));
    } catch (_) {
      // Ignore audio playback errors if sound device is not ready
    }
  }

  static void dispose() {
    _player.dispose();
  }
}
