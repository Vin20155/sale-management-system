import 'package:flutter/foundation.dart';

class AppUrl {
  static const String webApiBaseUrl = 'http://127.0.0.1:8000/api';
  static const String androidEmulatorApiBaseUrl = 'http://10.0.2.2:8000/api';
  static const String apiBaseUrlPreferenceKey = 'MART_API_URL';
  static const String authTokenPreferenceKey = 'MART_AUTH_TOKEN';

  static bool get isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  static String get defaultApiBaseUrl {
    if (kIsWeb || isDesktop || defaultTargetPlatform == TargetPlatform.iOS) {
      return webApiBaseUrl;
    }
    return androidEmulatorApiBaseUrl;
  }
}
