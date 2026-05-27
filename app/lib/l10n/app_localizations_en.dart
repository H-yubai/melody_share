// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get homeScan => 'Scan local music';

  @override
  String get homeScanning => 'Scanning local music...';

  @override
  String get homePermissionDenied => 'Storage permission denied';

  @override
  String get homeRetry => 'Retry';

  @override
  String get homeEmptyTitle => 'Your Music Awaits';

  @override
  String get homeEmptyDesc =>
      'Tap the scan button to discover\nyour local music collection';

  @override
  String get homeScanButton => 'Scan Local Music';

  @override
  String get homeAllMusic => 'All Music';

  @override
  String get unknownArtist => 'Unknown Artist';

  @override
  String get drawerSubtitle => 'Your personal music player';

  @override
  String get drawerLocalMusic => 'Local Music';

  @override
  String get drawerLocalMusicSub => 'Scan device for music';

  @override
  String get drawerUploadMusic => 'Upload Music';

  @override
  String get drawerUploadMusicSub => 'Share music to server';

  @override
  String get drawerDataManagement => 'Data Management';

  @override
  String get drawerDataManagementSub => 'Manage your music library';

  @override
  String get drawerMusicSharing => 'Music Sharing';

  @override
  String get drawerMusicSharingSub => 'Share with friends';

  @override
  String get drawerLightMode => 'Light Mode';

  @override
  String get drawerDarkMode => 'Dark Mode';

  @override
  String get drawerAbout => 'About';

  @override
  String get drawerLanguage => 'Language';

  @override
  String comingSoon(String feature) {
    return '$feature — coming soon!';
  }

  @override
  String get playerTitle => 'Player';

  @override
  String get playerNowPlaying => 'Now Playing';

  @override
  String get playerNoTrack => 'No track selected';

  @override
  String get uploadTitle => 'Upload Music';

  @override
  String get uploadComingSoon => 'Upload form coming soon';

  @override
  String get homeMenu => 'Menu';

  @override
  String get drawerPlaylists => 'Playlists';

  @override
  String get drawerNoPlaylists => 'No playlists yet';

  @override
  String get homeAddToPlaylist => 'Add to Playlist';

  @override
  String homeAddedToGroup(String name) {
    return 'Added to \"$name\"';
  }

  @override
  String get homeNoPlaylists =>
      'No playlists yet. Create one from the sidebar.';

  @override
  String get newPlaylist => 'New Playlist';

  @override
  String get playlistName => 'Playlist name';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get rename => 'Rename';

  @override
  String get renamePlaylist => 'Rename Playlist';

  @override
  String get delete => 'Delete';

  @override
  String get deletePlaylist => 'Delete Playlist';

  @override
  String deleteConfirm(String name) {
    return 'Delete \"$name\" and all its tracks?';
  }

  @override
  String get playerQueue => 'Play Queue';

  @override
  String playerTracksCount(int count) {
    return '$count tracks';
  }

  @override
  String get playerClear => 'Clear';

  @override
  String get playerQueueEmpty => 'Queue is empty';

  @override
  String get groupPlayAll => 'Play all';

  @override
  String get groupEmpty => 'Group is empty';

  @override
  String get searchGroups => 'Search groups';

  @override
  String get sortByName => 'By name';

  @override
  String get sortByCount => 'By count';

  @override
  String get chinese => 'Chinese';

  @override
  String get english => 'English';
}
