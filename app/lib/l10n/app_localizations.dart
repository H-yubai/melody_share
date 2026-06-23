import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// Tooltip for the scan button in app bar
  ///
  /// In en, this message translates to:
  /// **'Scan local music'**
  String get homeScan;

  /// No description provided for @homeScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning local music...'**
  String get homeScanning;

  /// No description provided for @homePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Storage permission denied'**
  String get homePermissionDenied;

  /// No description provided for @homeRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get homeRetry;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Music Awaits'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap the scan button to discover\nyour local music collection'**
  String get homeEmptyDesc;

  /// No description provided for @homeScanButton.
  ///
  /// In en, this message translates to:
  /// **'Scan Local Music'**
  String get homeScanButton;

  /// No description provided for @homeAllMusic.
  ///
  /// In en, this message translates to:
  /// **'All Music'**
  String get homeAllMusic;

  /// No description provided for @unknownArtist.
  ///
  /// In en, this message translates to:
  /// **'Unknown Artist'**
  String get unknownArtist;

  /// No description provided for @drawerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your personal music player'**
  String get drawerSubtitle;

  /// No description provided for @drawerLocalMusic.
  ///
  /// In en, this message translates to:
  /// **'Local Music'**
  String get drawerLocalMusic;

  /// No description provided for @drawerLocalMusicSub.
  ///
  /// In en, this message translates to:
  /// **'Scan device for music'**
  String get drawerLocalMusicSub;

  /// No description provided for @drawerUploadMusic.
  ///
  /// In en, this message translates to:
  /// **'Hi 歌曲'**
  String get drawerUploadMusic;

  /// No description provided for @drawerUploadMusicSub.
  ///
  /// In en, this message translates to:
  /// **'Share music to server'**
  String get drawerUploadMusicSub;

  /// No description provided for @drawerDataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get drawerDataManagement;

  /// No description provided for @drawerDataManagementSub.
  ///
  /// In en, this message translates to:
  /// **'Manage your music library'**
  String get drawerDataManagementSub;

  /// No description provided for @drawerMusicSharing.
  ///
  /// In en, this message translates to:
  /// **'Music Sharing'**
  String get drawerMusicSharing;

  /// No description provided for @drawerMusicSharingSub.
  ///
  /// In en, this message translates to:
  /// **'Share with friends'**
  String get drawerMusicSharingSub;

  /// No description provided for @drawerLightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get drawerLightMode;

  /// No description provided for @drawerDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get drawerDarkMode;

  /// No description provided for @drawerAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get drawerAbout;

  /// No description provided for @drawerLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get drawerLanguage;

  /// Placeholder message for unimplemented features
  ///
  /// In en, this message translates to:
  /// **'{feature} — coming soon!'**
  String comingSoon(String feature);

  /// No description provided for @playerTitle.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get playerTitle;

  /// No description provided for @playerNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get playerNowPlaying;

  /// No description provided for @playerNoTrack.
  ///
  /// In en, this message translates to:
  /// **'No track selected'**
  String get playerNoTrack;

  /// No description provided for @uploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload Music'**
  String get uploadTitle;

  /// No description provided for @uploadComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Upload form coming soon'**
  String get uploadComingSoon;

  /// No description provided for @homeMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get homeMenu;

  /// No description provided for @drawerPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get drawerPlaylists;

  /// No description provided for @drawerNoPlaylists.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get drawerNoPlaylists;

  /// No description provided for @homeAddToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to Playlist'**
  String get homeAddToPlaylist;

  /// No description provided for @homeAddedToGroup.
  ///
  /// In en, this message translates to:
  /// **'Added to \"{name}\"'**
  String homeAddedToGroup(String name);

  /// No description provided for @homeNoPlaylists.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet. Create one from the sidebar.'**
  String get homeNoPlaylists;

  /// No description provided for @newPlaylist.
  ///
  /// In en, this message translates to:
  /// **'New Playlist'**
  String get newPlaylist;

  /// No description provided for @playlistName.
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get playlistName;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @renamePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Rename Playlist'**
  String get renamePlaylist;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Delete Playlist'**
  String get deletePlaylist;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" and all its tracks?'**
  String deleteConfirm(String name);

  /// No description provided for @playerQueue.
  ///
  /// In en, this message translates to:
  /// **'Play Queue'**
  String get playerQueue;

  /// No description provided for @playerTracksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tracks'**
  String playerTracksCount(int count);

  /// No description provided for @playerClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get playerClear;

  /// No description provided for @playerQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Queue is empty'**
  String get playerQueueEmpty;

  /// No description provided for @groupPlayAll.
  ///
  /// In en, this message translates to:
  /// **'Play all'**
  String get groupPlayAll;

  /// No description provided for @groupEmpty.
  ///
  /// In en, this message translates to:
  /// **'Group is empty'**
  String get groupEmpty;

  /// No description provided for @searchGroups.
  ///
  /// In en, this message translates to:
  /// **'Search groups'**
  String get searchGroups;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'By name'**
  String get sortByName;

  /// No description provided for @sortByCount.
  ///
  /// In en, this message translates to:
  /// **'By count'**
  String get sortByCount;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get chinese;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @homeAddToGroup.
  ///
  /// In en, this message translates to:
  /// **'Add to Group'**
  String get homeAddToGroup;

  /// No description provided for @homeRemoveTrackConfirmAll.
  ///
  /// In en, this message translates to:
  /// **'Remove this track from all groups?'**
  String get homeRemoveTrackConfirmAll;

  /// No description provided for @homeRemoveTrackFromGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove this track from \"{name}\"?'**
  String homeRemoveTrackFromGroup(String name);

  /// No description provided for @homeTrackRemoved.
  ///
  /// In en, this message translates to:
  /// **'Track removed'**
  String get homeTrackRemoved;

  /// No description provided for @homeCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Create failed'**
  String get homeCreateFailed;

  /// No description provided for @homeCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Playlist created'**
  String get homeCreateSuccess;

  /// No description provided for @homeRenameSuccess.
  ///
  /// In en, this message translates to:
  /// **'Playlist renamed'**
  String get homeRenameSuccess;

  /// No description provided for @homeRenameFailed.
  ///
  /// In en, this message translates to:
  /// **'Rename failed'**
  String get homeRenameFailed;

  /// No description provided for @homeDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Playlist deleted'**
  String get homeDeleteSuccess;

  /// No description provided for @homeDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get homeDeleteFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
