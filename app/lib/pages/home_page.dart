import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../l10n/app_localizations.dart';
import '../models/group.dart';
import '../models/local_track.dart';
import '../services/database_service.dart';
import 'animation_picker_page.dart';
import '../services/group_provider.dart';
import '../services/local_music_service.dart';
import '../services/locale_provider.dart';
import '../services/playlist_provider.dart';
import '../theme/theme_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isScanning = false;
  String _scanDir = '';
  int _scanCount = 0;
  String? _error;
  int? _selectedGroupId;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = value;
        });
      }
    });
  }

  Future<void> _startScan() => _runScan(isQuick: true);

  Future<void> _startFullScan() => _runScan(isQuick: false);

  Future<void> _runScan({required bool isQuick, String? customPath}) async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _scanDir = customPath ?? '';
      _scanCount = 0;
      _error = null;
    });

    try {
      final hasPermission = await LocalMusicService.requestPermission();
      if (!hasPermission) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _error = l10n.homePermissionDenied;
          _isScanning = false;
        });
        return;
      }

      final tracks = customPath != null
          ? await LocalMusicService.scanDirectory(
              customPath,
              onProgress: (dir, count) {
                if (!mounted) return;
                setState(() {
                  _scanDir = dir;
                  _scanCount = count;
                });
              },
            )
          : isQuick
          ? await LocalMusicService.quickScan(
              onProgress: (dir, count) {
                if (!mounted) return;
                setState(() {
                  _scanDir = dir;
                  _scanCount = count;
                });
              },
            )
          : await LocalMusicService.fullScan(
              onProgress: (dir, count) {
                if (!mounted) return;
                setState(() {
                  _scanDir = dir;
                  _scanCount = count;
                });
              },
            );

      if (!mounted) return;
      context.read<PlaylistProvider>().setAllTracks(tracks);
      try {
        await DatabaseService.saveScannedTracks(tracks);
      } catch (e) {
        debugPrint('saveScannedTracks failed: $e');
      }
      setState(() {
        _isScanning = false;
      });
      if (mounted) {
        final msg = customPath != null
            ? '扫描完成，共 ${tracks.length} 首歌曲'
            : isQuick
            ? '快速扫描完成，共 ${tracks.length} 首歌曲'
            : '完整扫描完成，共 ${tracks.length} 首歌曲';
        toastification.show(
          context: context,
          title: Text(msg),
          type: ToastificationType.success,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '扫描失败: ${e.toString()}';
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) {
            final l10n = AppLocalizations.of(ctx)!;
            return IconButton(
              icon: const Icon(Icons.menu),
              tooltip: l10n.homeMenu,
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            );
          },
        ),
        title: const Text('MelodyShare'),
        actions: [
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Builder(
              builder: (ctx) {
                final l10n = AppLocalizations.of(ctx)!;
                return IconButton(
                  icon: const Icon(Icons.library_music),
                  tooltip: l10n.homeScan,
                  onPressed: _startScan,
                );
              },
            ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: const _MiniPlayer(),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.onPrimary.withValues(
                      alpha: 0.2,
                    ),
                    child: Icon(
                      Icons.person,
                      color: colorScheme.onPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'MelodyShare',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.drawerSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.library_music,
                    title: l10n.drawerLocalMusic,
                    subtitle: l10n.drawerLocalMusicSub,
                    onTap: () {
                      Navigator.pop(context);
                      _startScan();
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.manage_search,
                    title: '完整扫描',
                    subtitle: '深度扫描所有存储目录',
                    onTap: () {
                      Navigator.pop(context);
                      _startFullScan();
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.folder_open,
                    title: '自定义路径',
                    subtitle: '扫描指定目录',
                    onTap: () {
                      Navigator.pop(context);
                      _showCustomPathDialog();
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.upload,
                    title: l10n.drawerUploadMusic,
                    subtitle: l10n.drawerUploadMusicSub,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/upload');
                    },
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  Builder(
                    builder: (ctx) {
                      final groupProv = ctx.watch<GroupProvider>();
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.folder,
                                  size: 20,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.drawerPlaylists,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _showCreateGroupDialog();
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (groupProv.groups.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: Text(
                                l10n.drawerNoPlaylists,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          else
                            ...groupProv.groups.map(
                              (g) => ListTile(
                                dense: true,
                                leading: Icon(Icons.folder_outlined, size: 20),
                                title: Text(
                                  g.name,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                trailing: Text(
                                  '${g.trackCount}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  context.push('/group/${g.id}');
                                },
                                onLongPress: () {
                                  Navigator.pop(ctx);
                                  _showRenameDeleteGroupSheet(g);
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  Builder(
                    builder: (ctx) {
                      final theme = ctx.watch<ThemeProvider>();
                      return _DrawerItem(
                        icon: theme.isDark ? Icons.light_mode : Icons.dark_mode,
                        title: theme.isDark
                            ? l10n.drawerLightMode
                            : l10n.drawerDarkMode,
                        onTap: () {
                          Navigator.pop(ctx);
                          ctx.read<ThemeProvider>().toggle();
                        },
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.language,
                    title: l10n.drawerLanguage,
                    onTap: () {
                      Navigator.pop(context);
                      _showLanguageSheet();
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.waves,
                    title: '更改外观',
                    onTap: () {
                      Navigator.pop(context);
                      _showAppearanceSheet();
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline,
                    title: l10n.drawerAbout,
                    onTap: () {
                      Navigator.pop(context);
                      showAboutDialog(
                        context: context,
                        applicationName: 'MelodyShare',
                        applicationVersion: '1.0.0',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                l10n.drawerLanguage,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.check),
              title: Text(l10n.chinese),
              onTap: () {
                ctx.read<LocaleProvider>().setLocale(const Locale('zh'));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check),
              title: Text(l10n.english),
              onTap: () {
                ctx.read<LocaleProvider>().setLocale(const Locale('en'));
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAppearanceSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnimationPickerPage()),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final playlist = context.read<PlaylistProvider>();
    final groupProv = context.read<GroupProvider>();

    return ListenableBuilder(
      listenable: Listenable.merge([playlist, groupProv]),
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final allTracks = playlist.allTracks;
        final filteredTracks = _selectedGroupId != null
            ? allTracks
                  .where(
                    (t) =>
                        groupProv.getTrackIds(_selectedGroupId!).contains(t.id),
                  )
                  .toList()
            : allTracks;
        final searchedTracks = _searchQuery.isEmpty
            ? filteredTracks
            : filteredTracks
                  .where(
                    (t) =>
                        t.title.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        t.artist.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                  )
                  .toList();

        if (_isScanning) {
          final scanPath = _scanDir;
          final dirName = scanPath.isNotEmpty ? scanPath.split('/').last : '';
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(l10n.homeScanning),
                const SizedBox(height: 8),
                Text(
                  _scanCount > 0 ? '已找到 $_scanCount 首' : '',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colorScheme.primary),
                ),
                if (dirName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    dirName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          );
        }

        if (_error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(_error!, style: TextStyle(color: colorScheme.error)),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: _startScan,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.homeRetry),
                  ),
                ],
              ),
            ),
          );
        }

        if (allTracks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primaryContainer,
                    ),
                    child: Icon(
                      Icons.music_note,
                      size: 44,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(l10n.homeEmptyTitle, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    l10n.homeEmptyDesc,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _startScan,
                    icon: const Icon(Icons.library_music),
                    label: Text(l10n.homeScanButton),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            _buildSearchBar(),
            _buildGroupFilter(),
            Expanded(
              child: searchedTracks.isEmpty
                  ? Center(
                      child: Text(
                        l10n.homeEmptyTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _startScan,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        itemCount: searchedTracks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final track = searchedTracks[index];
                          final isCurrent = playlist.currentIndex == index;
                          final artist = track.displayArtist.isEmpty
                              ? l10n.unknownArtist
                              : track.displayArtist;
                          return Slidable(
                            key: ValueKey(track.id),
                            endActionPane: ActionPane(
                              motion: const BehindMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (_) => _showAddToGroupSheet(track),
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  icon: Icons.playlist_add,
                                  label: l10n.homeAddToGroup,
                                ),
                                SlidableAction(
                                  onPressed: (_) => _confirmRemoveTrack(track),
                                  backgroundColor: colorScheme.error,
                                  foregroundColor: colorScheme.onError,
                                  icon: Icons.delete_outline,
                                  label: l10n.delete,
                                ),
                              ],
                            ),
                            child: Card(
                              elevation: isCurrent ? 2 : 0,
                              color: isCurrent
                                  ? colorScheme.primaryContainer.withValues(
                                      alpha: 0.3,
                                    )
                                  : colorScheme.surface,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isCurrent
                                      ? colorScheme.primary
                                      : colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    isCurrent
                                        ? Icons.music_note
                                        : Icons.audiotrack,
                                    color: isCurrent
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  track.displayTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: isCurrent
                                        ? FontWeight.w600
                                        : null,
                                    color: isCurrent
                                        ? colorScheme.primary
                                        : null,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isCurrent) ...[
                                      Icon(
                                        Icons.equalizer,
                                        color: colorScheme.primary,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    if (track.displayDuration.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        track.displayDuration,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                                onTap: () {
                                  playlist.playTracks(
                                    searchedTracks,
                                    startIndex: index,
                                  );
                                  context.push('/player');
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索',
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 12,
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildGroupFilter() {
    final l10n = AppLocalizations.of(context)!;
    final groupProv = context.read<GroupProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    String selectedGroupName = l10n.homeAllMusic;
    if (_selectedGroupId != null) {
      final idx = groupProv.groups.indexWhere((g) => g.id == _selectedGroupId);
      if (idx >= 0) selectedGroupName = groupProv.groups[idx].name;
    }

    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _showGroupSelector,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_drop_down,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        selectedGroupName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.play_arrow_rounded, color: colorScheme.primary),
            tooltip: l10n.groupPlayAll,
            onPressed: () {
              final playlist = context.read<PlaylistProvider>();
              final allTracks = playlist.allTracks;
              final tracks = _selectedGroupId != null
                  ? allTracks
                        .where(
                          (t) => groupProv
                              .getTrackIds(_selectedGroupId!)
                              .contains(t.id),
                        )
                        .toList()
                  : allTracks;
              if (tracks.isNotEmpty) {
                playlist.playTracks(tracks);
                context.push('/player');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showGroupSelector() {
    final l10n = AppLocalizations.of(context)!;
    final groupProv = context.read<GroupProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final allTracksCount = context.read<PlaylistProvider>().allTracks.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        var searchQuery = '';
        var sortMode = 0;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            var groups = groupProv.groups.where((g) {
              if (searchQuery.isEmpty) return true;
              return g.name.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            if (sortMode == 0) {
              groups.sort((a, b) => a.name.compareTo(b.name));
            } else {
              groups.sort((a, b) => b.trackCount.compareTo(a.trackCount));
            }

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: l10n.searchGroups,
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                      ),
                      onChanged: (v) => setSheetState(() => searchQuery = v),
                    ),
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: Icon(
                          sortMode == 0
                              ? Icons.sort_by_alpha
                              : Icons.music_note,
                          size: 18,
                        ),
                        label: Text(
                          sortMode == 0 ? l10n.sortByName : l10n.sortByCount,
                        ),
                        onPressed: () => setSheetState(() {
                          sortMode = sortMode == 0 ? 1 : 0;
                        }),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      _selectedGroupId == null ? Icons.check : null,
                      color: colorScheme.primary,
                    ),
                    title: Text(l10n.homeAllMusic),
                    subtitle: Text(l10n.playerTracksCount(allTracksCount)),
                    onTap: () {
                      setState(() => _selectedGroupId = null);
                      Navigator.pop(ctx);
                    },
                  ),
                  ...groups.map(
                    (g) => ListTile(
                      leading: Icon(
                        _selectedGroupId == g.id ? Icons.check : null,
                        color: colorScheme.primary,
                      ),
                      title: Text(g.name),
                      subtitle: Text(l10n.playerTracksCount(g.trackCount)),
                      onTap: () {
                        setState(() => _selectedGroupId = g.id);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateGroupDialog() {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.newPlaylist),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.playlistName,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (v) async {
            if (v.trim().isEmpty) return;
            final provider = context.read<GroupProvider>();
            try {
              await provider.create(v.trim());
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              toastification.show(
                context: ctx,
                title: Text(l10n.homeCreateSuccess),
                type: ToastificationType.success,
                autoCloseDuration: const Duration(seconds: 2),
              );
            } catch (_) {
              if (!ctx.mounted) return;
              toastification.show(
                context: ctx,
                title: Text(l10n.homeCreateFailed),
                type: ToastificationType.error,
                autoCloseDuration: const Duration(seconds: 3),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final provider = context.read<GroupProvider>();
              try {
                await provider.create(controller.text.trim());
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                toastification.show(
                  context: ctx,
                  title: Text(l10n.homeCreateSuccess),
                  type: ToastificationType.success,
                  autoCloseDuration: const Duration(seconds: 2),
                );
              } catch (_) {
                if (!ctx.mounted) return;
                toastification.show(
                  context: ctx,
                  title: Text(l10n.homeCreateFailed),
                  type: ToastificationType.error,
                  autoCloseDuration: const Duration(seconds: 3),
                );
              }
            },
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }

  void _showRenameDeleteGroupSheet(Group group) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: group.name);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(l10n.rename),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (ctx2) => AlertDialog(
                      title: Text(l10n.renamePlaylist),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (v) async {
                          if (v.trim().isEmpty) return;
                          final provider = context.read<GroupProvider>();
                          try {
                            await provider.rename(group.id, v.trim());
                            if (!ctx2.mounted) return;
                            Navigator.pop(ctx2);
                            toastification.show(
                              context: ctx2,
                              title: Text(l10n.homeRenameSuccess),
                              type: ToastificationType.success,
                              autoCloseDuration: const Duration(seconds: 2),
                            );
                          } catch (_) {
                            if (!ctx2.mounted) return;
                            toastification.show(
                              context: ctx2,
                              title: Text(l10n.homeRenameFailed),
                              type: ToastificationType.error,
                              autoCloseDuration: const Duration(seconds: 3),
                            );
                          }
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx2),
                          child: Text(l10n.cancel),
                        ),
                        FilledButton(
                          onPressed: () async {
                            if (controller.text.trim().isEmpty) return;
                            final provider = context.read<GroupProvider>();
                            try {
                              await provider.rename(
                                group.id,
                                controller.text.trim(),
                              );
                              if (!ctx2.mounted) return;
                              Navigator.pop(ctx2);
                              toastification.show(
                                context: ctx2,
                                title: Text(l10n.homeRenameSuccess),
                                type: ToastificationType.success,
                                autoCloseDuration: const Duration(seconds: 2),
                              );
                            } catch (_) {
                              if (!ctx2.mounted) return;
                              toastification.show(
                                context: ctx2,
                                title: Text(l10n.homeRenameFailed),
                                type: ToastificationType.error,
                                autoCloseDuration: const Duration(seconds: 3),
                              );
                            }
                          },
                          child: Text(l10n.rename),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  l10n.delete,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (ctx2) => AlertDialog(
                      title: Text(l10n.deletePlaylist),
                      content: Text(l10n.deleteConfirm(group.name)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx2),
                          child: Text(l10n.cancel),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                          onPressed: () async {
                            final provider = context.read<GroupProvider>();
                            try {
                              await provider.delete(group.id);
                              if (!ctx2.mounted) return;
                              Navigator.pop(ctx2);
                              toastification.show(
                                context: ctx2,
                                title: Text(l10n.homeDeleteSuccess),
                                type: ToastificationType.success,
                                autoCloseDuration: const Duration(seconds: 2),
                              );
                            } catch (_) {
                              if (!ctx2.mounted) return;
                              toastification.show(
                                context: ctx2,
                                title: Text(l10n.homeDeleteFailed),
                                type: ToastificationType.error,
                                autoCloseDuration: const Duration(seconds: 3),
                              );
                            }
                          },
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemoveTrack(LocalTrack track) async {
    final l10n = AppLocalizations.of(context)!;
    final groupProv = context.read<GroupProvider>();
    final playlist = context.read<PlaylistProvider>();
    final groupName = _selectedGroupId != null
        ? groupProv.groups.firstWhere((g) => g.id == _selectedGroupId).name
        : null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(
          groupName != null
              ? l10n.homeRemoveTrackFromGroup(groupName)
              : l10n.homeRemoveTrackConfirmAll,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (_selectedGroupId != null) {
      await groupProv.removeTrack(_selectedGroupId!, track.id);
    } else {
      await playlist.removeTrackFromMaster(track.id);
      await groupProv.load();
    }
    if (!mounted) return;
    toastification.show(
      context: context,
      title: Text(l10n.homeTrackRemoved),
      type: ToastificationType.success,
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  void _showAddToGroupSheet(LocalTrack track) {
    final l10n = AppLocalizations.of(context)!;
    final groupProv = context.read<GroupProvider>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                l10n.homeAddToPlaylist,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            const Divider(),
            ...groupProv.groups.map(
              (g) => ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(g.name),
                onTap: () {
                  groupProv.addTrack(g.id, track);
                  Navigator.pop(ctx);
                  toastification.show(
                    context: context,
                    title: Text(l10n.homeAddedToGroup(g.name)),
                    type: ToastificationType.success,
                    autoCloseDuration: const Duration(seconds: 2),
                  );
                },
              ),
            ),
            if (groupProv.groups.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.homeNoPlaylists),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showCustomPathDialog() {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('扫描自定义目录'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('输入要扫描的文件夹路径：'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: r'D:\Download\Music',
                  border: const OutlineInputBorder(),
                  errorText: error,
                ),
                autofocus: true,
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    Navigator.pop(ctx);
                    _runScan(isQuick: false, customPath: v.trim());
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final path = controller.text.trim();
                if (path.isEmpty) {
                  setDialogState(() => error = '请输入路径');
                  return;
                }
                Navigator.pop(ctx);
                _runScan(isQuick: false, customPath: path);
              },
              child: const Text('扫描'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      onTap: onTap,
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer();

  @override
  Widget build(BuildContext context) {
    final playlist = context.watch<PlaylistProvider>();
    final track = playlist.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => context.push('/player'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<Duration>(
            stream: playlist.positionStream,
            builder: (context, snap) {
              final pos = snap.data ?? Duration.zero;
              return StreamBuilder<Duration>(
                stream: playlist.durationStream,
                builder: (context, snap2) {
                  final dur = snap2.data ?? Duration.zero;
                  final ratio = dur.inMilliseconds > 0
                      ? (pos.inMilliseconds / dur.inMilliseconds).clamp(
                          0.0,
                          1.0,
                        )
                      : 0.0;
                  return LinearProgressIndicator(
                    value: ratio,
                    minHeight: 2,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  );
                },
              );
            },
          ),
          Container(
            padding: const EdgeInsets.only(
              left: 16,
              right: 4,
              top: 8,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: colorScheme.primaryContainer,
                  ),
                  child: Icon(
                    Icons.music_note,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        track.displayArtist.isEmpty
                            ? l10n.unknownArtist
                            : track.displayArtist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.skip_previous_rounded,
                    color: colorScheme.primary,
                  ),
                  onPressed: () => playlist.previous(),
                ),
                StreamBuilder<bool>(
                  stream: playlist.playingStream,
                  builder: (context, snap) {
                    final playing = snap.data ?? false;
                    return IconButton(
                      icon: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: colorScheme.primary,
                      ),
                      onPressed: () => playlist.togglePlayPause(),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.skip_next_rounded,
                    color: colorScheme.primary,
                  ),
                  onPressed: () => playlist.next(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
