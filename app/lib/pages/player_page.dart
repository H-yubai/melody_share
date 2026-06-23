import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/local_track.dart';
import '../provider/animation_provider.dart';
import '../provider/playlist_provider.dart';
import '../services/music_handler.dart';
import '../services/lyrics_service.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  bool _showLyrics = false;
  bool _isLoadingLyrics = false;
  final LyricController _lyricController = LyricController();
  String? _lyricsText;
  String? _lastLyricsId;
  StreamSubscription<Duration>? _positionSub;
  PlaylistProvider? _playlist;
  String? _trackId;
  bool _noLyrics = false;
  static bool _lyricsPersist = false;

  String _formatDuration(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  double _lyricsMaxWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = 48.0;
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return math.min(screenWidth - horizontalPadding, 640);
    }
    return screenWidth - horizontalPadding;
  }

  void _toggleLyrics(LocalTrack track) {
    if (_showLyrics) {
      setState(() {
        _showLyrics = false;
        _noLyrics = false;
      });
      _lyricsPersist = false;
    } else if (_lyricsText != null && _lastLyricsId == track.id) {
      setState(() => _showLyrics = true);
      _lyricsPersist = true;
    } else {
      _fetchLyrics(track);
    }
  }

  Future<void> _fetchLyrics(LocalTrack track) async {
    setState(() {
      _isLoadingLyrics = true;
      _noLyrics = false;
    });
    final lrc = await LyricsService.fetchLyrics(track);
    if (!mounted) return;
    if (track.id != _trackId) return;
    if (lrc != null) {
      _lyricController.loadLyric(lrc);
      _lyricController.setOnTapLineCallback((pos) {
        context.read<PlaylistProvider>().seek(pos);
      });
      _lyricsPersist = true;
      setState(() {
        _lyricsText = lrc;
        _lastLyricsId = track.id;
        _showLyrics = true;
        _isLoadingLyrics = false;
      });
    } else {
      _lyricsPersist = true;
      setState(() {
        _showLyrics = true;
        _isLoadingLyrics = false;
        _noLyrics = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPositionListener();
      if (_lyricsPersist) {
        final track = context.read<PlaylistProvider>().currentTrack;
        if (track != null) _fetchLyrics(track);
      }
    });
  }

  void _startPositionListener() {
    _positionSub?.cancel();
    try {
      _playlist = context.read<PlaylistProvider>();
      _trackId = _playlist!.currentTrack?.id;
      _playlist!.addListener(_onPlaylistChanged);
      _positionSub = _playlist!.positionStream.listen((pos) {
        if (_lyricsText != null) _lyricController.setProgress(pos);
      });
    } catch (_) {}
  }

  void _onPlaylistChanged() {
    if (!mounted) return;
    final track = _playlist?.currentTrack;
    final newId = track?.id;
    if (newId != _trackId) {
      _trackId = newId;
      if (_lyricsText != null ||
          _lastLyricsId != null ||
          _showLyrics ||
          _isLoadingLyrics ||
          _noLyrics) {
        final stayLyrics = _showLyrics;
        setState(() {
          _lyricsText = null;
          _lastLyricsId = null;
          _showLyrics = stayLyrics;
          _isLoadingLyrics = stayLyrics && track != null;
          _noLyrics = false;
        });
        if (stayLyrics && track != null) {
          _fetchLyrics(track);
        }
      }
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _playlist?.removeListener(_onPlaylistChanged);
    _lyricController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlist = context.read<PlaylistProvider>();
    final animProv = context.read<AnimationProvider>();
    return ListenableBuilder(
      listenable: Listenable.merge([playlist, animProv]),
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
        final isPlaying = playlist.isPlaying;

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
                    title: _showLyrics
                        ? Column(
                            children: [
                              Text(
                                track.displayTitle,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                track.displayArtist.isEmpty
                                    ? l10n.unknownArtist
                                    : track.displayArtist,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                    centerTitle: true,
                    leading: IconButton(
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: colorScheme.onSurface,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _toggleLyrics(track),
                            child: _showLyrics && _lyricsText != null
                                ? Center(
                                    child: SizedBox(
                                      width: _lyricsMaxWidth(context),
                                      child: LyricView(
                                        controller: _lyricController,
                                        key: ValueKey('lyric_${track.id}'),
                                        style: LyricStyle(
                                          textStyle: TextStyle(
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                            fontSize: 15,
                                          ),
                                          activeStyle: TextStyle(
                                            color: colorScheme.primary,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          translationStyle: TextStyle(
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                            fontSize: 13,
                                          ),
                                          lineTextAlign: TextAlign.center,
                                          lineGap: 12,
                                          contentAlignment:
                                              CrossAxisAlignment.center,
                                          translationLineGap: 8,
                                          selectionAnchorPosition: 0.48,
                                          selectionAlignment:
                                              MainAxisAlignment.center,
                                          selectedColor: colorScheme.primary,
                                          selectedTranslationColor:
                                              colorScheme.onSurface,
                                          scrollDuration: const Duration(
                                            milliseconds: 240,
                                          ),
                                          selectionAutoResumeDuration:
                                              const Duration(milliseconds: 320),
                                          activeAutoResumeDuration:
                                              const Duration(
                                                milliseconds: 3000,
                                              ),
                                        ),
                                      ),
                                    ),
                                  )
                                : _showLyrics && _noLyrics
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          PhosphorIconsRegular.fileText,
                                          size: 48,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          '暂无歌词',
                                          style: TextStyle(
                                            color: colorScheme.onSurfaceVariant,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Center(
                                    child: _isLoadingLyrics
                                        ? const CircularProgressIndicator()
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Hero(
                                                tag: 'album_art_${track.id}',
                                                child: Container(
                                                  width: 260,
                                                  height: 260,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    color: colorScheme
                                                        .primaryContainer
                                                        .withValues(alpha: 0.5),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: colorScheme
                                                            .primary
                                                            .withValues(
                                                              alpha: 0.2,
                                                            ),
                                                        blurRadius: 30,
                                                        offset: const Offset(
                                                          0,
                                                          10,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    child: Lottie.asset(
                                                      animProv.assetPath,
                                                      animate: isPlaying,
                                                      repeat: true,
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 40),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 32,
                                                    ),
                                                child: Text(
                                                  track.displayTitle,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 32,
                                                    ),
                                                child: Text(
                                                  track.displayArtist.isEmpty
                                                      ? l10n.unknownArtist
                                                      : track.displayArtist,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        color: colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<Duration>(
                          stream: playlist.positionStream,
                          initialData: playlist.position,
                          builder: (context, snap) {
                            final pos = snap.data ?? Duration.zero;
                            return StreamBuilder<Duration>(
                              stream: playlist.durationStream,
                              initialData: playlist.duration,
                              builder: (context, snap2) {
                                final dur = snap2.data ?? Duration.zero;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Column(
                                    children: [
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 4,
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                                enabledThumbRadius: 6,
                                              ),
                                          overlayShape:
                                              const RoundSliderOverlayShape(
                                                overlayRadius: 16,
                                              ),
                                          activeTrackColor: colorScheme.primary,
                                          inactiveTrackColor: colorScheme
                                              .surfaceContainerHighest,
                                          thumbColor: colorScheme.primary,
                                          overlayColor: colorScheme.primary
                                              .withValues(alpha: 0.12),
                                        ),
                                        child: Slider(
                                          value: dur.inMilliseconds > 0
                                              ? (pos.inMilliseconds /
                                                        dur.inMilliseconds)
                                                    .clamp(0.0, 1.0)
                                              : 0,
                                          onChanged: (v) {
                                            playlist.seek(
                                              Duration(
                                                milliseconds:
                                                    (v * dur.inMilliseconds)
                                                        .round(),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                GestureDetector(
                                                  onTap: () =>
                                                      _toggleLyrics(track),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _showLyrics
                                                          ? colorScheme.primary
                                                                .withValues(
                                                                  alpha: 0.15,
                                                                )
                                                          : null,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '词',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: _showLyrics
                                                            ? colorScheme
                                                                  .primary
                                                            : colorScheme
                                                                  .onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _formatDuration(pos),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              _formatDuration(dur),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
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
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.primary,
                              ),
                              child: IconButton(
                                iconSize: 36,
                                padding: const EdgeInsets.all(16),
                                icon: Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: colorScheme.onPrimary,
                                ),
                                onPressed: () => playlist.togglePlayPause(),
                              ),
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
                            _ModeButton(
                              playlist: playlist,
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(width: 16),
                            _RatingButton(
                              playlist: playlist,
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              iconSize: 28,
                              constraints: const BoxConstraints(
                                minWidth: 56,
                                minHeight: 56,
                              ),
                              icon: Icon(
                                Icons.queue_music_rounded,
                                color: colorScheme.onSurfaceVariant,
                              ),
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
                      Text(
                        l10n.playerQueue,
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        l10n.playerTracksCount(queue.length),
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (queue.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            final idx = currentIdx;
                            if (idx != null &&
                                idx >= 0 &&
                                scrollController.hasClients) {
                              const tileHeight = 60.0;
                              final viewport =
                                  scrollController.position.viewportDimension;
                              final offset =
                                  idx * tileHeight -
                                  (viewport - tileHeight) / 2;
                              scrollController.animateTo(
                                offset.clamp(
                                  0.0,
                                  scrollController.position.maxScrollExtent,
                                ),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: Text(
                            '当前',
                            style: TextStyle(color: colorScheme.primary),
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () => playlist.clearQueue(),
                          child: Text(
                            l10n.playerClear,
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: queue.isEmpty
                      ? Center(
                          child: Text(
                            l10n.playerQueueEmpty,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: queue.length,
                          itemBuilder: (ctx, i) {
                            final t = queue[i];
                            final isCurrent = i == currentIdx;
                            return ListTile(
                              tileColor: isCurrent
                                  ? colorScheme.primaryContainer.withValues(
                                      alpha: 0.3,
                                    )
                                  : null,
                              dense: true,
                              leading: Icon(
                                isCurrent ? Icons.music_note : Icons.audiotrack,
                                size: 18,
                                color: isCurrent
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              title: Text(
                                t.displayTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isCurrent ? colorScheme.primary : null,
                                  fontWeight: isCurrent
                                      ? FontWeight.w600
                                      : null,
                                ),
                              ),
                              subtitle: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      t.displayArtist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  if (t.displayDuration.isNotEmpty)
                                    Text(
                                      t.displayDuration,
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.0,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: colorScheme.onSurfaceVariant,
                                ),
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
      iconSize: 28,
      constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
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

class _RatingButtonState extends State<_RatingButton>
    with TickerProviderStateMixin {
  int _rating = 0;
  int _animKey = 0;
  bool _hovered = false;
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 1),
    ]).animate(_bounceCtrl);
    _sync();
    widget.playlist.addListener(_sync);
  }

  @override
  void dispose() {
    widget.playlist.removeListener(_sync);
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _sync() {
    final track = widget.playlist.currentTrack;
    final newRating = track != null ? widget.playlist.getRating(track.id) : 0;
    if (newRating == _rating) return;
    setState(() {
      if (newRating > _rating) _animKey++;
      _rating = newRating;
    });
  }

  void _increment() {
    final track = widget.playlist.currentTrack;
    if (track == null) return;
    final next = _rating >= 3 ? 0 : _rating + 1;
    widget.playlist.rateTrack(track.id, next);
    setState(() {
      if (next > _rating) {
        _animKey++;
        _bounceCtrl.forward(from: 0.0);
      }
      _rating = next;
    });
  }

  void _setMax() {
    final track = widget.playlist.currentTrack;
    if (track == null) return;
    widget.playlist.rateTrack(track.id, 3);
    setState(() {
      if (3 > _rating) {
        _animKey++;
        _bounceCtrl.forward(from: 0.0);
      }
      _rating = 3;
    });
  }

  Color _heartColor() {
    switch (_rating) {
      case 1:
        return Colors.red.withValues(alpha: 0.4);
      case 2:
        return Colors.red.withValues(alpha: 0.7);
      case 3:
        return Colors.red;
      default:
        return widget.colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filled = _rating > 0;
    final heartColor = _heartColor();
    return InkWell(
      onTap: _increment,
      onLongPress: _setMax,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: ScaleTransition(
          scale: _bounceAnim,
          child: SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hovered
                        ? Theme.of(context).hoverColor
                        : Colors.transparent,
                  ),
                ),
                Icon(
                  filled ? Icons.favorite : Icons.favorite_border,
                  color: heartColor,
                  size: 32,
                ),
                if (filled)
                  Lottie.asset(
                    'assets/animations/lottie/like.json',
                    key: ValueKey('like_$_animKey'),
                    width: 56,
                    height: 56,
                    repeat: false,
                    animate: true,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
