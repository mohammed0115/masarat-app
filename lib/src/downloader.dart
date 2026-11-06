import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'config.dart';

/// Downloads a file of our own server with the WebView's session and opens it in the phone's viewer.
///
/// The WebView cannot save files itself, and the phone's browser has no session, so a PDF, a report export
/// or a receipt opened outside would land on the login page. Only our own server gets the session cookie.
class Downloader {
  static Future<String> fetch(Uri url, {String? suggestedName, String? userAgent}) async {
    if (!AppConfig.isOwn(url)) throw ArgumentError('not our server');
    final cookies = await CookieManager.instance().getCookies(url: WebUri.uri(url));
    final client = HttpClient();
    try {
      final req = await client.getUrl(url);
      if (cookies.isNotEmpty) {
        req.headers.set(HttpHeaders.cookieHeader, cookies.map((c) => '${c.name}=${c.value}').join('; '));
      }
      if (userAgent != null) req.headers.set(HttpHeaders.userAgentHeader, userAgent);
      final res = await req.close();
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}', uri: url);
      final name = safeName(
        fromDisposition(res.headers.value('content-disposition')) ??
            suggestedName ??
            (url.pathSegments.isNotEmpty ? url.pathSegments.last : null) ??
            'file',
      );
      final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/downloads');
      await dir.create(recursive: true);
      final file = File('${dir.path}/$name');
      await res.pipe(file.openWrite());
      return file.path;
    } finally {
      client.close();
    }
  }

  static Future<bool> open(String path) async => (await OpenFilex.open(path)).type == ResultType.done;

  /// filename / filename* of a Content-Disposition header.
  static String? fromDisposition(String? header) {
    if (header == null) return null;
    final star = RegExp(r"filename\*\s*=\s*[^']*''([^;]+)", caseSensitive: false).firstMatch(header);
    if (star != null) return Uri.decodeComponent(star.group(1)!.trim());
    final plain = RegExp(r'filename\s*=\s*"?([^";]+)"?', caseSensitive: false).firstMatch(header);
    return plain?.group(1)?.trim();
  }

  /// No folders, no hidden files: the name comes from the server.
  static String safeName(String name) {
    var n = name.split(RegExp(r'[/\\]')).last.replaceAll(RegExp(r'[\x00-\x1f:*?"<>|]'), '_').trim();
    while (n.startsWith('.')) {
      n = n.substring(1);
    }
    return n.isEmpty ? 'file' : n;
  }
}
