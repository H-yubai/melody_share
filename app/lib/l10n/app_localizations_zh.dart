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
  String get drawerUploadMusic => 'Hi 歌曲';

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

  @override
  String get edit => '编辑';

  @override
  String get editMetadata => '编辑元数据';

  @override
  String get editTrackTitle => '标题';

  @override
  String get editTrackArtist => '艺术家';

  @override
  String get editTrackAlbum => '专辑';

  @override
  String get save => '保存';

  @override
  String get editSuccess => '元数据已更新';

  @override
  String get editFailed => '元数据更新失败';

  @override
  String get homeAddToGroup => '添加到分组';

  @override
  String get homeRemoveTrackConfirmAll => '确定从所有分组中移除此曲目？';

  @override
  String homeRemoveTrackFromGroup(String name) {
    return '确定从「$name」中移除此曲目？';
  }

  @override
  String get alsoDeleteFile => '同时删除本地文件';

  @override
  String get homeTrackRemoved => '已移出曲目';

  @override
  String get homeCreateFailed => '创建失败';

  @override
  String get homeCreateSuccess => '歌单创建成功';

  @override
  String get homeRenameSuccess => '重命名成功';

  @override
  String get homeRenameFailed => '重命名失败';

  @override
  String get homeDeleteSuccess => '删除成功';

  @override
  String get homeDeleteFailed => '删除失败';

  @override
  String get webviewAudio => '音频';

  @override
  String get webviewResources => '资源';

  @override
  String get webviewShowAll => '显示全部';

  @override
  String get webviewAudioOnly => '仅音频';

  @override
  String get webviewDownloadAll => '全部下载';

  @override
  String webviewDownloading(String name) {
    return '正在下载：$name';
  }

  @override
  String webviewDownloaded(String name) {
    return '已下载：$name';
  }

  @override
  String webviewDownloadFailed(String error) {
    return '下载失败：$error';
  }

  @override
  String get webviewNoResources => '尚未检测到资源。\n浏览页面后重试。';

  @override
  String get webviewNoAudio => '未找到音频文件。';

  @override
  String get fullScan => '完整扫描';

  @override
  String get fullScanSubtitle => '深度扫描所有存储目录';

  @override
  String get changeAppearance => '更改外观';

  @override
  String get scanCustomDirectory => '扫描自定义目录';

  @override
  String scanComplete(int count) {
    return '扫描完成，共 $count 首歌曲';
  }

  @override
  String quickScanComplete(int count) {
    return '快速扫描完成，共 $count 首歌曲';
  }

  @override
  String fullScanComplete(int count) {
    return '完整扫描完成，共 $count 首歌曲';
  }

  @override
  String get enterDirectoryPath => '输入要扫描的文件夹路径：';

  @override
  String get done => '完成';

  @override
  String get homeScanConfirmTitle => '开始扫描';

  @override
  String homeScanConfirmCustomPath(String path) {
    return '确定要扫描自定义路径吗？\n当前路径为：$path。\n这可能需要很长时间。';
  }

  @override
  String get homeScanConfirmQuick => '确定要执行快速扫描吗？\n这可能需要很长时间。';

  @override
  String get confirm => '确认';
}
