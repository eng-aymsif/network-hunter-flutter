import 'package:audioplayers/audioplayers.dart';
import 'native_bridge.dart';

class SoundHelper {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playAlert({bool isError = false}) async {
    try {
      // تشغيل الصوت عبر خدمة أندرويد الأصلية في الخلفية من المسار:
      // assets/sounds/alert.mp3 أو assets/sounds/alert_error.mp3
      await NativeBridge.playCustomAlertSound(isError: isError);

      final fileName = isError ? 'sounds/alert_error.mp3' : 'sounds/alert.mp3';
      await _player.stop();
      await _player.setVolume(1.0);
      await _player.play(AssetSource(fileName));
    } catch (_) {
      // Ignore audio playback errors if sound device is not ready
    }
  }

  static void dispose() {
    _player.dispose();
  }
}
