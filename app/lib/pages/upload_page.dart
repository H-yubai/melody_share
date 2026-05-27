import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.uploadTitle)),
      body: Center(child: Text(l10n.uploadComingSoon)),
    );
  }
}
