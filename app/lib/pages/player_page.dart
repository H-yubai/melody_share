import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/music_handler.dart';
import '../services/playlist_provider.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  String _formatDuration(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final playlist = context.read<PlaylistProvider>();
    return ListenableBuilder(
      listenable: playlist,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final track = playlist.currentTrack;
        if (track == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.playerTitle)),
            body: Center(child: Text(l10n.playerNoTrack)),
          );
        }

        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.4),
                  colorScheme.surface,
                  colorScheme.surface,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: Text(
                      l10n.playerNowPlaying,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    centerTitle: true,
                    leading: IconButton(
                      icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurface),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Hero(
                          tag: 'album_art_${track.id}',
                          child: Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(alpha: 0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.music_note,
                              size: 80,
                              color: colorScheme.primary.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            track.displayTitle,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            track.displayArtist.isEmpty ? l10n.unknownArtist : track.displayArtist,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 40),
                        StreamBuilder<Duration>(
                          stream: playlist.positionStream,
                          builder: (context, snap) {
                            final pos = snap.data ?? Duration.zero;
                            return StreamBuilder<Duration?>(
                              stream: playlist.durationStream,
                              builder: (context, snap2) {
                                final dur = snap2.data ?? Duration.zero;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Column(
                                    children: [
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 4,
                                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                          activeTrackColor: colorScheme.primary,
                                          inactiveTrackColor: colorScheme.surfaceContainerHighest,
                                          thumbColor: colorScheme.primary,
                                          overlayColor: colorScheme.primary.withValues(alpha: 0.12),
                                        ),
                                        child: Slider(
                                          value: dur.inMilliseconds > 0
                                              ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                                              : 0,
                                          onChanged: (v) {
                                            playlist.player.seek(Duration(
                                              milliseconds: (v * dur.inMilliseconds).round(),
                                            ));
                                          },
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatDuration(pos),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                            Text(
                                              _formatDuration(dur),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              iconSize: 32,
                              icon: const Icon(Icons.skip_previous_rounded),
                              onPressed: () => playlist.previous(),
                              color: colorScheme.onSurface,
                            ),
                            const SizedBox(width: 16),
                            StreamBuilder<PlayerState>(
                              stream: playlist.playerStateStream,
                              builder: (context, snap) {
                                final isPlaying = snap.data?.playing ?? false;
                                return Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colorScheme.primary,
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    iconSize: 36,
                                    padding: const EdgeInsets.all(16),
                                    icon: Icon(
                                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: colorScheme.onPrimary,
                                    ),
                                    onPressed: () => playlist.togglePlayPause(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              iconSize: 32,
                              icon: const Icon(Icons.skip_next_rounded),
                              onPressed: () => playlist.next(),
                              color: colorScheme.onSurface,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ModeButton(playlist: playlist, colorScheme: colorScheme),
                            const SizedBox(width: 48),
                            _RatingButton(playlist: playlist, colorScheme: colorScheme),
                            const SizedBox(width: 48),
                            IconButton(
                              iconSize: 24,
                              icon: Icon(Icons.queue_music_rounded,
                                  color: colorScheme.onSurfaceVariant),
                              onPressed: () => _showQueue(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showQueue(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final playlist = context.read<PlaylistProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (ctx, scrollController) => ListenableBuilder(
          listenable: playlist,
          builder: (ctx, _) {
            final queue = playlist.queueTracks;
            final currentIdx = playlist.currentIndex;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Text(l10n.playerQueue,
                        style: Theme.of(ctx).textTheme.titleMedium),
                      const Spacer(),
                      Text(l10n.playerTracksCount(queue.length),
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant)),
                      if (queue.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => playlist.clearQueue(),
                          child: Text(l10n.playerClear,
                            style: TextStyle(color: colorScheme.error)),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: queue.isEmpty
                      ? Center(
                          child: Text(l10n.playerQueueEmpty,
                            style: TextStyle(color: colorScheme.onSurfaceVariant)))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: queue.length,
                          itemBuilder: (ctx, i) {
                            final t = queue[i];
                            final isCurrent = i == currentIdx;
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                isCurrent ? Icons.music_note : Icons.audiotrack,
                                size: 18,
                                color: isCurrent
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              title: Text(t.displayTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isCurrent ? colorScheme.primary : null,
                                  fontWeight: isCurrent ? FontWeight.w600 : null,
                                ),
                              ),
                              subtitle: Text(t.displayArtist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant)),
                              trailing: IconButton(
                                icon: Icon(Icons.close, size: 18,
                                    color: colorScheme.onSurfaceVariant),
                                onPressed: () => playlist.removeFromQueue(i),
                              ),
                              onTap: () {
                                playlist.playFromQueue(i);
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.playlist, required this.colorScheme});

  final PlaylistProvider playlist;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (playlist.mode) {
      case PlaybackMode.noRepeat:
        icon = PhosphorIconsFill.list;
        color = colorScheme.onSurfaceVariant;
      case PlaybackMode.repeatAll:
        icon = PhosphorIconsFill.repeat;
        color = colorScheme.primary;
      case PlaybackMode.repeatOne:
        icon = PhosphorIconsFill.repeatOnce;
        color = colorScheme.primary;
      case PlaybackMode.shuffle:
        icon = PhosphorIconsFill.shuffle;
        color = colorScheme.primary;
    }
    return IconButton(
      iconSize: 24,
      icon: Icon(icon, color: color),
      onPressed: () => playlist.cyclePlaybackMode(),
    );
  }
}

class _RatingButton extends StatefulWidget {
  const _RatingButton({required this.playlist, required this.colorScheme});

  final PlaylistProvider playlist;
  final ColorScheme colorScheme;

  @override
  State<_RatingButton> createState() => _RatingButtonState();
}

class _RatingButtonState extends State<_RatingButton> {
  int _rating = 0;
  bool _longPressFired = false;

  @override
  void initState() {
    super.initState();
    _sync();
    widget.playlist.addListener(_sync);
  }

  @override
  void dispose() {
    widget.playlist.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    final track = widget.playlist.currentTrack;
    setState(() {
      _rating = track != null ? widget.playlist.getRating(track.id) : 0;
    });
  }

  void _increment() {
    final track = widget.playlist.currentTrack;
    if (track == null) return;
    final next = _rating >= 3 ? 0 : _rating + 1;
    widget.playlist.rateTrack(track.id, next);
  }

  void _setMax() {
    final track = widget.playlist.currentTrack;
    if (track == null) return;
    widget.playlist.rateTrack(track.id, 3);
  }

  @override
  Widget build(BuildContext context) {
    final filled = _rating > 0;
    return GestureDetector(
      onTap: _increment,
      onLongPressStart: (_) {
        _longPressFired = false;
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (_longPressFired) return;
          _longPressFired = true;
          _setMax();
        });
      },
      onLongPressEnd: (_) {
        _longPressFired = true;
      },
      onLongPressCancel: () {
        _longPressFired = true;
      },
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              filled ? Icons.favorite : Icons.favorite_border,
              size: 24,
              color: filled ? Colors.red : widget.colorScheme.onSurfaceVariant,
            ),
            Positioned(
              right: 2,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
                decoration: BoxDecoration(
                  color: widget.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_rating',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: filled ? Colors.red : widget.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
