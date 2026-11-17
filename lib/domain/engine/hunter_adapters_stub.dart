import 'package:networking/domain/engine/hunter_interfaces.dart';

HunterBrowserController? createPlatformBrowserController() => null;
HunterSoundPlayer createPlatformSoundPlayer() => const StubSoundPlayer();
HunterUnbanHandler createPlatformUnbanHandler() => const StubUnbanHandler();

class StubSoundPlayer implements HunterSoundPlayer {
  const StubSoundPlayer();

  @override
  Future<void> playAlert({bool isError = false}) async {}
}

class StubUnbanHandler implements HunterUnbanHandler {
  const StubUnbanHandler();

  @override
  Future<Map<String, dynamic>> performUnban({void Function(String)? log}) async {
    log?.call('⚠️ مشغل فك الحظر الافتراضي (Stub)');
    return {'success': false, 'reason': 'Stub platform'};
  }
}
