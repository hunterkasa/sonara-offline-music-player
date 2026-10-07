import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme_tokens.dart';
import '../../core/services/haptic_service.dart';
import '../../domain/models/wrapped_data.dart';
import '../../domain/services/wrapped_service.dart';

class WrappedScreen extends ConsumerStatefulWidget {
  const WrappedScreen({super.key});

  @override
  ConsumerState<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends ConsumerState<WrappedScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _cardRepaintKey = GlobalKey();
  int _currentIndex = 0;
  WrappedData? _data;
  bool _isLoading = true;
  bool _isExporting = false;

  late final AnimationController _progressController;
  Timer? _storyTimer;

  static const int _totalCards = 6;
  static const Duration _cardDuration = Duration(seconds: 7);

  @override
  void initState() {
    super.initState();
    _progressController =
        AnimationController(vsync: this, duration: _cardDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _nextCard();
            }
          });

    _loadData();
  }

  Future<void> _loadData() async {
    final service = ref.read(wrappedServiceProvider);
    final data = await service.generateWrapped();
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
      _startCardTimer();
    }
  }

  void _startCardTimer() {
    _progressController.forward(from: 0.0);
  }

  void _nextCard() {
    if (_currentIndex < _totalCards - 1) {
      setState(() {
        _currentIndex++;
      });
      _progressController.forward(from: 0.0);
    } else {
      _progressController.stop();
    }
  }

  void _prevCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _progressController.forward(from: 0.0);
    } else {
      _progressController.forward(from: 0.0);
    }
  }

  void _pauseTimer() {
    _progressController.stop();
  }

  void _resumeTimer() {
    if (_currentIndex < _totalCards - 1) {
      _progressController.forward();
    }
  }

  Future<void> _exportShareCard() async {
    final haptics = ref.read(hapticServiceProvider);
    haptics.medium();

    setState(() {
      _isExporting = true;
    });

    try {
      final boundary =
          _cardRepaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();

      if (bytes != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green),
                const SizedBox(width: AppSpacing.s),
                Text('Rendered ${bytes.lengthInBytes ~/ 1024} KB share card!'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not export card: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _storyTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final haptics = ref.read(hapticServiceProvider);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final data = _data;
    if (data == null || data.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.music_off_rounded,
                size: 64,
                color: Colors.white54,
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                'No Listening History Yet',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Text(
                  'Play some tunes in Sonara to generate your 100% offline Wrapped recap!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTapDown: (details) {
            final screenWidth = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx < screenWidth * 0.3) {
              haptics.selection();
              _prevCard();
            } else if (details.globalPosition.dx > screenWidth * 0.7) {
              haptics.selection();
              _nextCard();
            }
          },
          onLongPressStart: (_) => _pauseTimer(),
          onLongPressEnd: (_) => _resumeTimer(),
          child: Stack(
            children: [
              // Card Content View
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.l,
                  vertical: AppSpacing.m,
                ),
                child: RepaintBoundary(
                  key: _cardRepaintKey,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: _buildCardContent(_currentIndex, data),
                  ),
                ),
              ),

              // Story Progress Indicators at the Top
              Positioned(
                top: AppSpacing.s,
                left: AppSpacing.m,
                right: AppSpacing.m,
                child: Row(
                  children: List.generate(_totalCards, (index) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: SizedBox(
                            height: 3,
                            child: AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, _) {
                                double val = 0.0;
                                if (index < _currentIndex) {
                                  val = 1.0;
                                } else if (index == _currentIndex) {
                                  val = _progressController.value;
                                }
                                return LinearProgressIndicator(
                                  value: val,
                                  backgroundColor: Colors.white24,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Header Close & Action Buttons
              Positioned(
                top: AppSpacing.m + 8,
                left: AppSpacing.m,
                right: AppSpacing.m,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Row(
                      children: [
                        if (_currentIndex == _totalCards - 1)
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.m,
                                vertical: 8,
                              ),
                            ),
                            icon: _isExporting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Icon(Icons.share_rounded, size: 18),
                            label: const Text(
                              'Share Card',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: _isExporting ? null : _exportShareCard,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(int index, WrappedData data) {
    return switch (index) {
      0 => _buildIntroCard(data),
      1 => _buildTopTracksCard(data),
      2 => _buildTopArtistsCard(data),
      3 => _buildPersonalityCard(data),
      4 => _buildTopGenresCard(data),
      _ => _buildSummaryPosterCard(data),
    };
  }

  Widget _buildIntroCard(WrappedData data) {
    return Container(
      key: const ValueKey('intro_card'),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'SONARA OFFLINE WRAPPED',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          const Text(
            'Your Year in Sound.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Time Immersed',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '${data.totalListeningMinutes} Minutes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'Across ${data.totalTracksPlayed} unique local tracks & ${data.totalPlaysCount} total plays.',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            '100% On-Device & Zero Cloud Tracking 🔒',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTracksCard(WrappedData data) {
    return Container(
      key: const ValueKey('top_tracks_card'),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D2671), Color(0xFFC33764)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            'YOUR TOP ANTHEMS',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Songs You Kept on Repeat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          Expanded(
            child: ListView.separated(
              itemCount: data.topTracks.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
              itemBuilder: (context, i) {
                final track = data.topTracks[i];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.s,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '#${i + 1}',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              track.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${track.playCount} plays',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopArtistsCard(WrappedData data) {
    final topArtist = data.topArtists.isNotEmpty ? data.topArtists.first : null;
    return Container(
      key: const ValueKey('top_artists_card'),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            'ARTIST SPOTLIGHT',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your Sound Masters',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          if (topArtist != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.amberAccent.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '👑 Number 1 Artist',
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    topArtist.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${topArtist.playCount} total plays · ${topArtist.totalMinutes} minutes',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.l),
          Expanded(
            child: ListView.separated(
              itemCount: data.topArtists.skip(1).length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
              itemBuilder: (context, i) {
                final artist = data.topArtists[i + 1];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Text(
                      '#${i + 2}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    artist.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Text(
                    '${artist.playCount} plays',
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalityCard(WrappedData data) {
    return Container(
      key: const ValueKey('personality_card'),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF654EA3), Color(0xFFEAAFC8)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'AUDIO PERSONALITY',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            data.personalityTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            data.personalityDescription,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Peak Listening Window',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  data.peakHourLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  '🔥 ${data.listeningStreakDays} Days Listening Streak',
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopGenresCard(WrappedData data) {
    return Container(
      key: const ValueKey('top_genres_card'),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            'GENRE LANDSCAPE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your Musical DNA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          Expanded(
            child: ListView.separated(
              itemCount: data.topGenres.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
              itemBuilder: (context, i) {
                final genre = data.topGenres[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          genre.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${genre.percentage}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (genre.percentage / 100.0).clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPosterCard(WrappedData data) {
    final topTrack = data.topTracks.isNotEmpty ? data.topTracks.first : null;
    final topArtist = data.topArtists.isNotEmpty ? data.topArtists.first : null;

    return Container(
      key: const ValueKey('summary_poster_card'),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.graphic_eq_rounded,
                    color: Colors.amberAccent,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'SONARA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  data.periodLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          Text(
            data.personalityTitle,
            style: const TextStyle(
              color: Colors.amberAccent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  'Total Listening',
                  '${data.totalListeningMinutes} mins',
                ),
                const Divider(color: Colors.white12),
                if (topArtist != null) ...[
                  _buildSummaryRow('Top Artist', topArtist.name),
                  const Divider(color: Colors.white12),
                ],
                if (topTrack != null) ...[
                  _buildSummaryRow('Top Anthem', topTrack.title),
                  const Divider(color: Colors.white12),
                ],
                _buildSummaryRow('Peak Vibe', data.peakHourLabel),
              ],
            ),
          ),
          const Spacer(),
          Center(
            child: Text(
              '100% Private Offline Audio · Zero Tracking',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
