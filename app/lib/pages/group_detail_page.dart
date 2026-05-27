import 'package:flutter/material.dart';
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

                      return Card(
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
                          subtitle: Text(artist,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            icon: Icon(Icons.remove_circle_outline,
                                color: colorScheme.error),
                            onPressed: () async {
                              await context
                                  .read<GroupProvider>()
                                  .removeTrack(widget.groupId, track.id);
                              await _load();
                            },
                          ),
                          onTap: () {
                            context
                                .read<PlaylistProvider>()
                                .playTracks(_tracks!, startIndex: index);
                            context.push('/player');
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
