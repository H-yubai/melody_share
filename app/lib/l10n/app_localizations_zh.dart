// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get homeScan => '扫描本地音乐';

  @override
  String get homeScanning => '正在扫描本地音乐...';

  @override
  String get homePermissionDenied => '存储权限被拒绝';

  @override
  String get homeRetry => '重试';

  @override
  String get homeEmptyTitle => '你的音乐之旅即将开始';

  @override
  String get homeEmptyDesc => '点击扫描按钮，发现设备上的本地音乐';

  @override
  String get homeScanButton => '扫描本地音乐';

  @override
  String get homeAllMusic => '全部音乐';

  @override
  String get unknownArtist => '未知艺术家';

  @override
  String get drawerSubtitle => '你的个人音乐播放器';

  @override
  String get drawerLocalMusic => '本地音乐';

  @override
  String get drawerLocalMusicSub => '扫描设备中的音乐文件';

  @override
  String get drawerUploadMusic => '上传音乐';

  @override
  String get drawerUploadMusicSub => '分享音乐到服务器';

  @override
  String get drawerDataManagement => '数据管理';

  @override
  String get drawerDataManagementSub => '管理你的音乐库';

  @override
  String get drawerMusicSharing => '音乐分享';

  @override
  String get drawerMusicSharingSub => '与好友分享音乐';

  @override
  String get drawerLightMode => '浅色模式';

  @override
  String get drawerDarkMode => '深色模式';

  @override
  String get drawerAbout => '关于';

  @override
  String get drawerLanguage => '语言';

  @override
  String comingSoon(String feature) {
    return '$feature —— 即将推出！';
  }

  @override
  String get playerTitle => '播放器';

  @override
  String get playerNowPlaying => '正在播放';

  @override
  String get playerNoTrack => '未选择曲目';

  @override
  String get uploadTitle => '上传音乐';

  @override
  String get uploadComingSoon => '上传功能即将推出';

  @override
  String get homeMenu => '菜单';

  @override
  String get drawerPlaylists => '播放列表';

  @override
  String get drawerNoPlaylists => '暂无播放列表';

  @override
  String get homeAddToPlaylist => '添加到播放列表';

  @override
  String homeAddedToGroup(String name) {
    return '已添加到「$name」';
  }

  @override
  String get homeNoPlaylists => '暂无播放列表，请在侧边栏创建';

  @override
  String get newPlaylist => '新建播放列表';

  @override
  String get playlistName => '播放列表名称';

  @override
  String get cancel => '取消';

  @override
  String get create => '创建';

  @override
  String get rename => '重命名';

  @override
  String get renamePlaylist => '重命名播放列表';

  @override
  String get delete => '删除';

  @override
  String get deletePlaylist => '删除播放列表';

  @override
  String deleteConfirm(String name) {
    return '确定要删除「$name」及其所有曲目吗？';
  }

  @override
  String get playerQueue => '播放队列';

  @override
  String playerTracksCount(int count) {
    return '$count 首曲目';
  }

  @override
  String get playerClear => '清空';

  @override
  String get playerQueueEmpty => '队列为空';

  @override
  String get groupPlayAll => '播放全部';

  @override
  String get groupEmpty => '分组为空';

  @override
  String get searchGroups => '搜索分组';

  @override
  String get sortByName => '按名称';

  @override
  String get sortByCount => '按数量';

  @override
  String get chinese => '中文';

  @override
  String get english => 'English';
}
