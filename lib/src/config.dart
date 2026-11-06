import 'package:flutter/services.dart' show appFlavor;

/// Where the app finds MASARAT. The screens themselves are the web portals (parent: /masarat_portal,
/// teacher: /teacher-portal), so a change on the server reaches the app without a new release.
///
/// Build for another server (e.g. a local bench) with:
///   flutter run --dart-define=MASARAT_URL=http://10.0.2.2:8000
class AppConfig {
  static const String baseUrl = String.fromEnvironment('MASARAT_URL', defaultValue: 'https://marhaba-edu.com');

  /// The login page sends a signed-in user straight to their portal (masarat.portal_router).
  static const String startPath = '/login';

  /// Added to the WebView user agent, so the server can tell the app from a browser if it ever needs to.
  static const String userAgentTag = 'MasaratApp/1.0';

  static Uri get baseUri => Uri.parse(baseUrl);
  static Uri get startUri => baseUri.replace(path: startPath);

  /// Pages of our own server open inside the app; everything else (other sites, tel:, mailto:, WhatsApp)
  /// opens in the phone's own apps.
  static bool isOwn(Uri uri) =>
      (uri.scheme == 'https' || uri.scheme == 'http') && uri.host == baseUri.host && uri.port == baseUri.port;

  /// Two apps from one code base: `family` (guardians and teachers) and `admin` (school administration, the
  /// desk). Both sign in on the same login page; the server sends each account to its own home.
  static bool get isAdmin => appFlavor == 'admin';

  static String get appName => isAdmin ? 'مسارات الإدارة' : 'مسارات';

  /// The desk has wide tables; let the administration zoom. The portals are made for phones.
  static bool get allowZoom => isAdmin;
}
