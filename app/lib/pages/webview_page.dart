import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  InAppWebViewController? _controller;
  bool _isLoading = true;
  bool _canGoBack = false;

  Future<void> _goBack() async {
    if (_canGoBack) {
      await _controller?.goBack();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.drawerUploadMusic),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack,
          ),
        ),
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri('https://higequ.com/'),
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
              ),
              onWebViewCreated: (controller) {
                _controller = controller;
              },
              shouldOverrideUrlLoading:
                  (controller, navigationAction) async {
                final uri = navigationAction.request.url;
                if (uri != null) {
                  final scheme = uri.scheme;
                  if (scheme != 'http' && scheme != 'https') {
                    try {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                      return NavigationActionPolicy.CANCEL;
                    } catch (_) {
                      try {
                        await launchUrl(uri);
                        return NavigationActionPolicy.CANCEL;
                      } catch (_) {
                        return NavigationActionPolicy.ALLOW;
                      }
                    }
                  }
                }
                return NavigationActionPolicy.ALLOW;
              },
              onLoadStart: (controller, url) {
                if (mounted) setState(() => _isLoading = true);
              },
              onLoadStop: (controller, url) async {
                if (mounted) {
                  final canGoBack = await controller.canGoBack();
                  setState(() {
                    _isLoading = false;
                    _canGoBack = canGoBack;
                  });
                }
              },
            ),
            if (_isLoading)
              const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
