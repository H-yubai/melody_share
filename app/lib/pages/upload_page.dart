import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../l10n/app_localizations.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.drawerUploadMusic)),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri('https://higequ.com/'),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
            ),
            onLoadStart: (controller, url) {
              if (mounted) setState(() => _isLoading = true);
            },
            onLoadStop: (controller, url) {
              if (mounted) setState(() => _isLoading = false);
            },
          ),
          if (_isLoading)
            const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
