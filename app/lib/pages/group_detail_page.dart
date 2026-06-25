import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../l10n/app_localizations.dart';
import '../models/local_track.dart';
import '../provider/group_provider.dart';
import '../provider/playlist_provider.dart';
import 'package:lottie/lottie.dart';

class GroupDetailPage extends StatefulWidget {
  final int groupId;
  const GroupDetailPage({super.key, required this.groupId});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  List<LocalTrack>? _tracks;
  String _groupName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final groupProv = context.read<GroupProvider>();
    final group = groupProv.groups.firstWhere((g) => g.id == widget.groupId);
    final tracks = await groupProv.getTracks(widget.groupId);
    if (!mounted) return;
    setState(() {
      _groupName = group.name;
      _tracks = tracks;
    });
  }

  Future<void> _confirmRemoveTrack(LocalTrack track) async {
    final l10n = AppLocalizations.of(context)!;
    final groupProv = context.read<GroupProvider>();
    final playlist = context.read<PlaylistProvider>();
    final groupName = groupProv.groups
        .firstWhere((g) => g.id == widget.groupId)
        .name;
    var deleteFile = false;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.delete),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.homeRemoveTrackFromGroup(groupName)),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: deleteFile,
                onChanged: (v) => setDialogState(() => deleteFile = v ?? false),
                title: Text(l10n.alsoDeleteFile),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
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
      ),
    );
    if (result != true) return;
    if (deleteFile) {
      try {
        final file = File(track.filePath);
        if (await file.exists()) await file.delete();
      } catch (_) {}
      await playlist.removeTrackFromMaster(track.id);
      await groupProv.load();
    } else {
      await groupProv.removeTrack(widget.groupId, track.id);
    }
    await _load();
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

  Future<void> _showEditTrackDialog(LocalTrack track) async {
    final l10n = AppLocalizations.of(context)!;
    final titleCtl = TextEditingController(text: track.title);
    final artistCtl = TextEditingController(text: track.artist);
    final albumCtl = TextEditingController(text: track.album);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editMetadata),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtl,
              decoration: InputDecoration(
                labelText: l10n.editTrackTitle,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: artistCtl,
              decoration: InputDecoration(
                labelText: l10n.editTrackArtist,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: albumCtl,
              decoration: InputDecoration(
                labelText: l10n.editTrackAlbum,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final title = titleCtl.text.trim();
              if (title.isEmpty) return;
              try {
                await context.read<PlaylistProvider>().editTrackMetadata(
                  track,
                  title: title,
                  artist: artistCtl.text.trim(),
                  album: albumCtl.text.trim(),
                );
                await _load();
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                toastification.show(
                  context: context,
                  title: Text(l10n.editSuccess),
                  type: ToastificationType.success,
                  autoCloseDuration: const Duration(seconds: 2),
                );
              } catch (_) {
                if (!ctx.mounted) return;
                toastification.show(
                  context: context,
                  title: Text(l10n.editFailed),
                  type: ToastificationType.error,
                  autoCloseDuration: const Duration(seconds: 3),
                );
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_groupName),
        actions: [
          if (_tracks != null && _tracks!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_arrow_rounded),
              tooltip: l10n.groupPlayAll,
              onPressed: () {
                context.read<PlaylistProvider>().playTracks(_tracks!);
                context.push('/player');
              },
            ),
        ],
      ),
      body: _tracks == null
          ? const Center(child: CircularProgressIndicator())
          : _tracks!.isEmpty
          ? Center(
              child: Text(
                l10n.groupEmpty,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                itemCount: _tracks!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final track = _tracks![index];
                  final playlist = context.watch<PlaylistProvider>();
                  final isCurrent = playlist.currentTrack?.id == track.id;
                  final l10n = AppLocalizations.of(context)!;
                  final artist = track.displayArtist.isEmpty
                      ? l10n.unknownArtist
                      : track.displayArtist;

                  final tile = ListTile(
                    leading: isCurrent
                        ? SizedBox(
                            width: 36,
                            height: 36,
                            child: Lottie.asset(
                              'assets/animations/lottie/Play dvd, disk.json',
                              fit: BoxFit.contain,
                              animate: playlist.isPlaying,
                            ),
                          )
                        : CircleAvatar(
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.audiotrack,
                              color: colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                    title: Text(
                      track.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                        if (track.displayDuration.isNotEmpty)
                          Text(
                            ' ${track.displayDuration}',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      context.read<PlaylistProvider>().playTracks(
                        _tracks!,
                        startIndex: index,
                      );
                    },
                  );
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
                          onPressed: (_) => _showEditTrackDialog(track),
                          backgroundColor: colorScheme.tertiary,
                          foregroundColor: colorScheme.onTertiary,
                          icon: Icons.edit,
                          label: l10n.edit,
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
                      color: colorScheme.surface,
                      clipBehavior: Clip.antiAlias,
                      child: isCurrent
                          ? Stack(
                              children: [
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: 0.2,
                                    child: Lottie.asset(
                                      'assets/animations/lottie/Music Notes.json',
                                      fit: BoxFit.contain,
                                      repeat: true,
                                    ),
                                  ),
                                ),
                                tile,
                              ],
                            )
                          : tile,
                    ),
                  );
                },
              ),
            ),
    );
  }
}
