export 'platform_env_stub.dart'
    if (dart.library.io) 'platform_env_io.dart'
    if (dart.library.js_interop) 'platform_env_web.dart';
