import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../network/api_client.dart';

/// Tanıtım/politika sitesinin adresi. Verilmezse API adresinden türetilir:
/// http://127.0.0.1:8000/api/v1 → http://127.0.0.1:8000
/// Yayında: --dart-define=WEB_URL=https://kaloritakip.app
const _webUrlOverride = String.fromEnvironment('WEB_URL');

const androidPackage = 'com.kaloritakip.kaloritakip';

abstract final class AppLinks {
  static String get web => _webUrlOverride.isNotEmpty
      ? _webUrlOverride
      : apiBaseUrl.replaceFirst(RegExp(r'/api/v\d+/?$'), '');

  static String get privacy => '$web/gizlilik';
  static String get terms => '$web/kullanim-kosullari';
  static String get subscriptionTerms => '$web/abonelik-kosullari';
  static String get kvkk => '$web/kvkk';
  static String get deletion => '$web/hesap-silme';
  static String get support => '$web/destek';

  /// Mağazanın kendi abonelik yönetim sayfası (iptal, plan değiştirme).
  static String get manageSubscription => !kIsWeb && Platform.isIOS
      ? 'https://apps.apple.com/account/subscriptions'
      : 'https://play.google.com/store/account/subscriptions?package=$androidPackage';

  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Mağaza adı metinlerde kullanılır.
  static String get storeName => isIOS ? 'App Store' : 'Google Play';
  static String get accountName => isIOS ? 'Apple Kimliği' : 'Google Play';
}

/// Politika sayfalarını uygulama içi tarayıcıda (iOS: SFSafariViewController, Android: Custom Tabs),
/// mağaza sayfalarını dış uygulamada açar.
Future<bool> openLink(String url, {bool external = false}) => launchUrl(
  Uri.parse(url),
  mode: external ? LaunchMode.externalApplication : LaunchMode.inAppBrowserView,
);
