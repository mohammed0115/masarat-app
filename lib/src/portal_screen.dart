import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';
import 'downloader.dart';
import 'offline_view.dart';
import 'theme.dart';

/// The whole app: one WebView on the MASARAT server. The server decides what each account sees after
/// login (guardian → /masarat_portal, teacher → /teacher-portal), exactly as on the web.
class PortalScreen extends StatefulWidget {
  const PortalScreen({super.key});

  @override
  State<PortalScreen> createState() => _PortalScreenState();
}

class _PortalScreenState extends State<PortalScreen> {
  InAppWebViewController? _web;
  PullToRefreshController? _pull;
  double _progress = 0;
  bool _offline = false;
  String? _errorDetail;
  bool _firstLoadDone = false;

  final _settings = InAppWebViewSettings(
    applicationNameForUserAgent: AppConfig.userAgentTag,
    javaScriptEnabled: true,
    // Session cookie (sid) must survive app restarts so the guardian stays signed in.
    thirdPartyCookiesEnabled: false,
    sharedCookiesEnabled: true,
    // The portals are designed for phones; the desk (admin app) has wide tables.
    supportZoom: AppConfig.allowZoom,
    builtInZoomControls: AppConfig.allowZoom,
    displayZoomControls: false,
    // iOS: let the page use the safe area itself, and allow swipe-back like Safari.
    allowsBackForwardNavigationGestures: true,
    allowsInlineMediaPlayback: true,
    useShouldOverrideUrlLoading: true,
    useOnDownloadStart: true,
    // Android file input (student photo, CV) and camera.
    allowFileAccess: false,
    allowContentAccess: true,
    mediaPlaybackRequiresUserGesture: true,
    transparentBackground: false,
    disableDefaultErrorPage: true,
  );

  @override
  void initState() {
    super.initState();
    _pull = PullToRefreshController(
      settings: PullToRefreshSettings(color: Brand.navy),
      onRefresh: () async {
        if (_offline) {
          _retry();
        } else {
          await _web?.reload();
        }
      },
    );
  }

  Future<void> _retry() async {
    setState(() {
      _offline = false;
      _errorDetail = null;
    });
    final current = await _web?.getUrl();
    await _web?.loadUrl(urlRequest: URLRequest(url: WebUri.uri(current ?? AppConfig.startUri)));
  }

  Future<void> _openOutside(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر فتح الرابط على هذا الجهاز')));
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// Files (PDF prints, report exports, receipts): our server's files are fetched with the session and opened in
  /// the phone's viewer; other sites' files open in the browser.
  Future<void> _download(Uri url, String? suggestedName) async {
    if (!AppConfig.isOwn(url)) {
      await _openOutside(url);
      return;
    }
    _toast('جارٍ تنزيل الملف…');
    try {
      final ua = await _web?.evaluateJavascript(source: 'navigator.userAgent');
      final path = await Downloader.fetch(url, suggestedName: suggestedName, userAgent: ua?.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (!await Downloader.open(path)) _toast('تم التنزيل، لكن لا يوجد على الجهاز تطبيق يفتح هذا النوع من الملفات');
    } catch (_) {
      _toast('تعذّر تنزيل الملف. حاول مرة أخرى.');
    }
  }

  Future<NavigationActionPolicy> _route(InAppWebViewController c, NavigationAction action) async {
    final url = action.request.url;
    if (url == null) return NavigationActionPolicy.ALLOW;
    final uri = Uri.parse(url.toString());
    if (uri.scheme == 'about' || uri.scheme == 'data' || uri.scheme == 'blob' || uri.scheme == 'javascript') {
      return NavigationActionPolicy.ALLOW;
    }
    if (AppConfig.isOwn(uri)) return NavigationActionPolicy.ALLOW;
    // Only links the user follows go outside; ignore iframes and scripted redirects of sub-frames.
    if (action.isForMainFrame) {
      unawaited(_openOutside(uri));
    }
    return NavigationActionPolicy.CANCEL;
  }

  Future<void> _back() async {
    final web = _web;
    if (web != null && await web.canGoBack()) {
      await web.goBack();
    } else {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Brand.navy,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: Scaffold(
          backgroundColor: Brand.navy,
          body: SafeArea(
            bottom: false,
            child: Container(
              color: Colors.white,
              child: Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri.uri(AppConfig.startUri)),
                    initialSettings: _settings,
                    pullToRefreshController: _pull,
                    onWebViewCreated: (c) => _web = c,
                    shouldOverrideUrlLoading: _route,
                    onCreateWindow: (c, req) async {
                      // target="_blank" / window.open: own pages in the same view, others outside.
                      final url = req.request.url;
                      if (url != null) {
                        final uri = Uri.parse(url.toString());
                        if (AppConfig.isOwn(uri)) {
                          await c.loadUrl(urlRequest: URLRequest(url: url));
                        } else {
                          unawaited(_openOutside(uri));
                        }
                      }
                      return false;
                    },
                    onDownloadStarting: (c, req) async {
                      unawaited(_download(Uri.parse(req.url.toString()), req.suggestedFilename));
                      return DownloadStartResponse(handled: true, action: DownloadStartResponseAction.CANCEL);
                    },
                    onProgressChanged: (c, p) {
                      setState(() => _progress = p / 100);
                      if (p == 100) _pull?.endRefreshing();
                    },
                    onLoadStop: (c, url) {
                      _pull?.endRefreshing();
                      if (!_firstLoadDone) setState(() => _firstLoadDone = true);
                    },
                    onReceivedError: (c, req, err) {
                      if (req.isForMainFrame != true) return;
                      if (err.type == WebResourceErrorType.CANCELLED) return;
                      _pull?.endRefreshing();
                      setState(() {
                        _offline = true;
                        _errorDetail = err.description;
                        _firstLoadDone = true;
                      });
                    },
                    onPermissionRequest: (c, req) async {
                      // Camera for the photo field: only our own server may ask.
                      final origin = Uri.parse(req.origin.toString());
                      return PermissionResponse(
                        resources: req.resources,
                        action: AppConfig.isOwn(origin)
                            ? PermissionResponseAction.GRANT
                            : PermissionResponseAction.DENY,
                      );
                    },
                  ),
                  if (_progress < 1 && !_offline)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: _progress == 0 ? null : _progress,
                        minHeight: 3,
                        color: Brand.blue,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  if (!_firstLoadDone) const _Splash(),
                  if (_offline)
                    Positioned.fill(
                      child: OfflineView(onRetry: _retry, detail: _errorDetail),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Covers the white WebView until the first page has painted, continuing the native splash.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: AppConfig.isAdmin ? Brand.cream : Brand.navy,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                AppConfig.isAdmin ? 'assets/icon/admin/splash.png' : 'assets/icon/splash.png',
                width: 96,
                height: 96,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppConfig.appName,
              style: TextStyle(
                color: AppConfig.isAdmin ? Brand.navy : Brand.cream,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppConfig.isAdmin ? Brand.navy : Brand.cream),
            ),
          ],
        ),
      ),
    );
  }
}
