import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toastification/toastification.dart';
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
  final List<String> _resources = [];
  bool _sniffingEnabled = false;
  bool _audioOnly = true;

  static const _audioExts = <String>{
    '.mp3',
    '.wav',
    '.flac',
    '.aac',
    '.ogg',
    '.m4a',
    '.wma',
  };

  List<String> get _displayResources {
    if (!_audioOnly) return _resources;
    return _resources.where(_isAudioUrl).toList();
  }

  static bool _isAudioUrl(String url) {
    final lower = url.toLowerCase();
    try {
      final path = Uri.parse(lower).path;
      return _audioExts.any((ext) => path.endsWith(ext));
    } catch (_) {
      return _audioExts.any((ext) => lower.contains(ext));
    }
  }

  Future<void> _goBack() async {
    if (_canGoBack) {
      await _controller?.goBack();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _onSniffTap() async {
    if (!_sniffingEnabled) {
      await _enableSniffing();
    }
    await _collectResources();
    if (!mounted) return;
    _showResourceSheet();
  }

  Future<void> _enableSniffing() async {
    await _injectSniffer();
    setState(() => _sniffingEnabled = true);
  }

  Future<void> _injectSniffer() async {
    await _controller?.evaluateJavascript(source: r'''
(function() {
  if (window.__gs_sniff) return;
  window.__gs_sniff = new Set();
  var add = function(u) { if (u && u.startsWith('http')) window.__gs_sniff.add(u); };
  var origFetch = window.fetch;
  window.fetch = function(input, init) {
    var url = typeof input === 'string' ? input : (input.url || input);
    add(url);
    return origFetch.call(this, input, init);
  };
  var origOpen = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function(method, url) {
    add(url);
    return origOpen.call(this, method, url);
  };
  document.querySelectorAll('[src]').forEach(function(el) { if (el.src) add(el.src); });
  document.querySelectorAll('a[href]').forEach(function(el) {
    var h = el.href;
    if (/\.(mp3|wav|flac|aac|ogg|m4a|wma)(\?|#|$)/i.test(h)) add(h);
  });
})();
''');
  }

  Future<void> _collectResources() async {
    final result = await _controller?.evaluateJavascript(source: r'''
Array.from(window.__gs_sniff || []).join('\n')
''');
    if (result is String && result.isNotEmpty) {
      for (final url in result.split('\n')) {
        if (url.isNotEmpty && !_resources.contains(url)) {
          _resources.add(url);
        }
      }
    }
  }

  void _showResourceSheet() {
    final l10n = AppLocalizations.of(context)!;
    final display = _displayResources;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_audioOnly ? l10n.webviewAudio : l10n.webviewResources} (${display.length}${_audioOnly && _resources.length > display.length ? "/${_resources.length}" : ""})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _audioOnly = !_audioOnly);
                      Navigator.pop(ctx);
                      _showResourceSheet();
                    },
                    icon: Icon(
                      _audioOnly ? Icons.filter_list : Icons.music_note,
                      size: 18,
                    ),
                    label: Text(_audioOnly ? l10n.webviewShowAll : l10n.webviewAudioOnly),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed:
                        display.isEmpty ? null : () => _downloadAll(ctx),
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(l10n.webviewDownloadAll),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: display.isEmpty
                  ? Center(
                      child: Text(
                        _resources.isEmpty
                            ? l10n.webviewNoResources
                            : l10n.webviewNoAudio,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: display.length,
                      itemBuilder: (ctx, i) {
                        final url = display[i];
                        return ListTile(
                          dense: true,
                          title: Text(
                            url.split('/').last.split('?').first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.download, size: 20),
                            onPressed: () => _downloadResource(url),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<String> _downloadDir() async {
    if (Platform.isAndroid) {
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        final root = ext.path.split('/Android/').first;
        return '$root/Music/melody_share';
      }
    }
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/downloads';
  }

  Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;
    if (await Permission.audio.request().isGranted) return true;
    if (await Permission.storage.request().isGranted) return true;
    if (await Permission.manageExternalStorage.request().isGranted) return true;
    return false;
  }

  Future<void> _downloadResource(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (!await _ensureStoragePermission()) {
      if (!mounted) return;
      toastification.show(
        context: context,
        title: Text(l10n.homePermissionDenied),
        type: ToastificationType.warning,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    String rawName = url.split('/').last.split('?').first;
    if (rawName.isEmpty) rawName = 'download';
    final safeName = rawName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

    final cancel = CancelToken();
    final progressNotifier = ValueNotifier<double>(0);

    final dialog = AlertDialog(
      title: Text(l10n.webviewDownloading(safeName)),
      content: ValueListenableBuilder<double>(
        valueListenable: progressNotifier,
        builder: (ctx, value, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: value),
              const SizedBox(height: 8),
              Text('${(value * 100).toStringAsFixed(0)}%'),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => cancel.cancel('Cancelled'),
          child: Text(l10n.cancel),
        ),
      ],
    );

    if (!mounted) return;
    navigator.push(
      DialogRoute(
        context: context,
        barrierDismissible: false,
        builder: (_) => dialog,
      ),
    );

    try {
      final dir = Directory(await _downloadDir());
      if (!await dir.exists()) await dir.create(recursive: true);
      final savePath = '${dir.path}/$safeName';

      final dio = Dio(BaseOptions(
        followRedirects: true,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          HttpHeaders.userAgentHeader:
              'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36',
        },
      ));

      await dio.download(
        url,
        savePath,
        cancelToken: cancel,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          progressNotifier.value = received / total;
        },
      );

      navigator.pop();
      if (!mounted) return;
      toastification.show(
        context: context,
        title: Text(l10n.webviewDownloaded(safeName)),
        type: ToastificationType.success,
        autoCloseDuration: const Duration(seconds: 3),
      );
    } catch (e) {
      navigator.pop();
      if (!mounted || cancel.isCancelled) return;
      toastification.show(
        context: context,
        title: Text(l10n.webviewDownloadFailed('$e')),
        type: ToastificationType.error,
        autoCloseDuration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _downloadAll(BuildContext ctx) async {
    Navigator.pop(ctx);
    final display = _displayResources;
    for (final url in display) {
      if (!mounted) break;
      await _downloadResource(url);
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
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.radar),
              color: _sniffingEnabled ? Colors.blue : null,
              tooltip: 'Sniff & download resources',
              onPressed: _onSniffTap,
            ),
          ],
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
                if (_sniffingEnabled) {
                  await _injectSniffer();
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
