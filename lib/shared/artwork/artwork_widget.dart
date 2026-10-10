import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonara/data/sources/artwork_service.dart';
import 'package:sonara/shared/artwork/song_artwork_presets.dart';

class ArtworkWidget extends ConsumerStatefulWidget {
  final String? artworkKey;
  final String? filePath;
  final String title;
  final double size;
  final double borderRadius;
  final bool isCircular;

  const ArtworkWidget({
    super.key,
    this.artworkKey,
    this.filePath,
    required this.title,
    this.size = 48.0,
    this.borderRadius = 8.0,
    this.isCircular = false,
  });

  @override
  ConsumerState<ArtworkWidget> createState() => _ArtworkWidgetState();
}

class _ArtworkWidgetState extends ConsumerState<ArtworkWidget> {
  File? _resolvedArt;
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    _resolveArtwork();
  }

  @override
  void didUpdateWidget(covariant ArtworkWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artworkKey != widget.artworkKey ||
        oldWidget.filePath != widget.filePath) {
      _resolveArtwork();
    }
  }

  Future<void> _resolveArtwork() async {
    if (widget.artworkKey != null && widget.artworkKey!.startsWith('preset:')) {
      if (mounted) {
        setState(() {
          _resolvedArt = null;
          _hasChecked = true;
        });
      }
      return;
    }

    final artService = ref.read(artworkServiceProvider);
    final file = await artService.resolveArtworkFile(
      artworkKey: widget.artworkKey,
      filePath: widget.filePath,
    );
    if (mounted) {
      setState(() {
        _resolvedArt = file;
        _hasChecked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final clipRadius = widget.isCircular
        ? BorderRadius.circular(widget.size.isFinite ? widget.size / 2 : 64.0)
        : BorderRadius.circular(widget.borderRadius);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: clipRadius,
        child: SizedBox(
          width: widget.size.isFinite ? widget.size : null,
          height: widget.size.isFinite ? widget.size : null,
          child: _buildArtworkContent(),
        ),
      ),
    );
  }

  Widget _buildArtworkContent() {
    if (widget.artworkKey != null && widget.artworkKey!.startsWith('preset:')) {
      final preset = SongArtworkPresets.getPreset(widget.artworkKey);
      if (preset != null) {
        final iconSize = widget.size.isFinite
            ? (widget.size * 0.45).clamp(14.0, 96.0)
            : 36.0;
        return Container(
          decoration: BoxDecoration(gradient: preset.gradient),
          child: Center(
            child: Icon(
              preset.icon,
              size: iconSize,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        );
      }
    }

    if (_resolvedArt != null) {
      final cacheDim = widget.size.isFinite ? (widget.size * 2).toInt() : 256;
      return Image.file(
        _resolvedArt!,
        width: widget.size.isFinite ? widget.size : null,
        height: widget.size.isFinite ? widget.size : null,
        fit: BoxFit.cover,
        cacheWidth: cacheDim,
        cacheHeight: cacheDim,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    if (!_hasChecked) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    final gradient = ArtworkService.generateGradientFallback(widget.title);
    final iconSize = widget.size.isFinite
        ? (widget.size * 0.45).clamp(16.0, 96.0)
        : 36.0;

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Center(
        child: Icon(
          widget.isCircular ? Icons.person : Icons.music_note,
          size: iconSize,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}
