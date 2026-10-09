import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

class AppCheckBootstrapResult {
  const AppCheckBootstrapResult({required this.active, this.message});

  final bool active;
  final String? message;
}

abstract final class AppCheckBootstrap {
  static const _debugEnabled = bool.fromEnvironment('AXIOS_APP_CHECK_DEBUG');
  static const _debugToken = String.fromEnvironment(
    'AXIOS_APP_CHECK_DEBUG_TOKEN',
  );
  static const _webSiteKey = String.fromEnvironment(
    'AXIOS_APP_CHECK_WEB_SITE_KEY',
  );

  static Future<AppCheckBootstrapResult> initialize() async {
    try {
      if (kIsWeb) {
        if (_debugEnabled && kDebugMode) {
          await FirebaseAppCheck.instance.activate(
            providerWeb: WebDebugProvider(debugToken: _tokenOrNull),
          );
          return const AppCheckBootstrapResult(active: true);
        }
        if (_webSiteKey.isEmpty) {
          return const AppCheckBootstrapResult(
            active: false,
            message:
                'App Check Web aguarda AXIOS_APP_CHECK_WEB_SITE_KEY ou o '
                'provedor de depuração explícito.',
          );
        }
        await FirebaseAppCheck.instance.activate(
          providerWeb: ReCaptchaEnterpriseProvider(_webSiteKey),
        );
        return const AppCheckBootstrapResult(active: true);
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          await FirebaseAppCheck.instance.activate(
            providerAndroid: _debugEnabled && kDebugMode
                ? AndroidDebugProvider(debugToken: _tokenOrNull)
                : const AndroidPlayIntegrityProvider(),
          );
          return const AppCheckBootstrapResult(active: true);
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          await FirebaseAppCheck.instance.activate(
            providerApple: _debugEnabled && kDebugMode
                ? AppleDebugProvider(debugToken: _tokenOrNull)
                : const AppleAppAttestWithDeviceCheckFallbackProvider(),
          );
          return const AppCheckBootstrapResult(active: true);
        case TargetPlatform.windows:
        case TargetPlatform.linux:
        case TargetPlatform.fuchsia:
          return const AppCheckBootstrapResult(
            active: false,
            message: 'App Check não foi configurado para esta plataforma.',
          );
      }
    } catch (_) {
      return const AppCheckBootstrapResult(
        active: false,
        message: 'Não foi possível ativar o App Check neste ambiente.',
      );
    }
  }

  static String? get _tokenOrNull => _debugToken.isEmpty ? null : _debugToken;
}
