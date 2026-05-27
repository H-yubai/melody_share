import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/local_track.dart';
import '../services/group_provider.dart';
import '../services/playlist_provider.dart';

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
    final groupName =
        groupProv.groups.firstWhere((g) => g.id == widget.groupId).name;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.homeRemoveTrackFromGroup(groupName)),
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
    await groupProv.removeTrack(widget.groupId, track.id);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.homeTrackRemoved),
        behavior: SnackBarBehavior.floating,
      ),
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
              child: Text(l10n.homeAddToPlaylist,
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            const Divider(),
            ...groupProv.groups.map((g) => ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(g.name),
                  onTap: () {
                    groupProv.addTrack(g.id, track);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.homeAddedToGroup(g.name)),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                )),
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
                context
                    .read<PlaylistProvider>()
                    .playTracks(_tracks!);
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
                              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                              : colorScheme.surface,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isCurrent
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHighest,
                              child: Icon(
                                isCurrent ? Icons.music_note : Icons.audiotrack,
                                color: isCurrent
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                            title: Text(track.displayTitle,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: Text(artist,
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                                if (track.displayDuration.isNotEmpty)
                                  Text(' ${track.displayDuration}',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant)),
                              ],
                            ),
                            onTap: () {
                              context
                                  .read<PlaylistProvider>()
                                  .playTracks(_tracks!, startIndex: index);
                              context.push('/player');
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
