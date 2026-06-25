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
  String get drawerUploadMusic => 'Hi 歌曲';

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

  @override
  String get edit => 'Edit';

  @override
  String get editMetadata => 'Edit Metadata';

  @override
  String get editTrackTitle => 'Title';

  @override
  String get editTrackArtist => 'Artist';

  @override
  String get editTrackAlbum => 'Album';

  @override
  String get save => 'Save';

  @override
  String get editSuccess => 'Metadata updated';

  @override
  String get editFailed => 'Failed to update metadata';

  @override
  String get homeAddToGroup => 'Add to Group';

  @override
  String get homeRemoveTrackConfirmAll => 'Remove this track from all groups?';

  @override
  String homeRemoveTrackFromGroup(String name) {
    return 'Remove this track from \"$name\"?';
  }

  @override
  String get alsoDeleteFile => 'Also delete local file';

  @override
  String get homeTrackRemoved => 'Track removed';

  @override
  String get homeCreateFailed => 'Create failed';

  @override
  String get homeCreateSuccess => 'Playlist created';

  @override
  String get homeRenameSuccess => 'Playlist renamed';

  @override
  String get homeRenameFailed => 'Rename failed';

  @override
  String get homeDeleteSuccess => 'Playlist deleted';

  @override
  String get homeDeleteFailed => 'Delete failed';

  @override
  String get webviewAudio => 'Audio';

  @override
  String get webviewResources => 'Resources';

  @override
  String get webviewShowAll => 'Show all';

  @override
  String get webviewAudioOnly => 'Audio only';

  @override
  String get webviewDownloadAll => 'Download All';

  @override
  String webviewDownloading(String name) {
    return 'Downloading: $name';
  }

  @override
  String webviewDownloaded(String name) {
    return 'Downloaded: $name';
  }

  @override
  String webviewDownloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String get webviewNoResources =>
      'No resources detected yet.\nBrowse the page and try again.';

  @override
  String get webviewNoAudio => 'No audio files found.';
}
