import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'services/animation_provider.dart';
import 'services/developer_settings.dart';
import 'services/group_provider.dart';
import 'services/locale_provider.dart';
import 'services/music_handler.dart';
import 'services/playlist_provider.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

class MelodyShareApp extends StatelessWidget {
  final MusicHandler handler;

  const MelodyShareApp({super.key, required this.handler});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AnimationProvider()),
        ChangeNotifierProvider(create: (_) => DeveloperSettings()),
        ChangeNotifierProvider(
          create: (_) => PlaylistProvider(handler)
            ..loadCachedTracks()
            ..loadRatings(),
        ),
        ChangeNotifierProvider(create: (_) => GroupProvider()..load()),
      ],
      child: Builder(
        builder: (context) {
          final theme = context.watch<ThemeProvider>();
          final locale = context.watch<LocaleProvider>();
          return MaterialApp.router(
            title: 'MelodyShare',
            debugShowCheckedModeBanner: false,
            locale: locale.locale,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: theme.mode,
            builder: (context, child) => ToastificationWrapper(child: child!),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
