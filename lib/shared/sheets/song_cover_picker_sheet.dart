import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sonara/app/theme/theme_tokens.dart';
import 'package:sonara/core/services/haptic_service.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/shared/artwork/artwork_widget.dart';
import 'package:sonara/shared/artwork/song_artwork_presets.dart';

/// Modal bottom sheet allowing users to set a custom gallery photo
/// or select from curated aesthetic placeholder presets for any song/track.
class SongCoverPickerSheet extends ConsumerStatefulWidget {
  final Track track;

  const SongCoverPickerSheet({super.key, required this.track});

  static Future<void> show(BuildContext context, Track track) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SongCoverPickerSheet(track: track),
    );
  }

  @override
  ConsumerState<SongCoverPickerSheet> createState() =>
      _SongCoverPickerSheetState();
}

class _SongCoverPickerSheetState extends ConsumerState<SongCoverPickerSheet> {
  late String? _currentArtworkKey;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentArtworkKey = widget.track.artworkKey;
  }

  Future<void> _pickFromGallery() async {
    final haptics = ref.read(hapticServiceProvider);
    haptics.selection();

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked == null || !mounted) return;

      setState(() => _isSaving = true);

      // Copy image to persistent application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final artDir = Directory(p.join(appDir.path, 'song_artwork'));
      if (!await artDir.exists()) {
        await artDir.create(recursive: true);
      }

      final safeKey = widget.track.trackKey.replaceAll(
        RegExp(r'[^a-zA-Z0-9_-]'),
        '_',
      );
      final ext = p.extension(picked.path).isNotEmpty
          ? p.extension(picked.path)
          : '.jpg';
      final fileName =
          'song_${safeKey}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final targetPath = p.join(artDir.path, fileName);

      await File(picked.path).copy(targetPath);

      if (!mounted) return;

      final db = ref.read(databaseProvider);
      await db.updateTrackArtwork(widget.track.trackKey, targetPath);

      setState(() {
        _currentArtworkKey = targetPath;
        _isSaving = false;
      });

      haptics.light();
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Custom song artwork updated'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to update artwork: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _selectPreset(SongArtworkPreset preset) async {
    final haptics = ref.read(hapticServiceProvider);
    haptics.selection();

    setState(() {
      _currentArtworkKey = preset.uri;
      _isSaving = true;
    });

    try {
      final db = ref.read(databaseProvider);
      await db.updateTrackArtwork(widget.track.trackKey, preset.uri);
      if (mounted) {
        setState(() => _isSaving = false);
        haptics.light();
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Selected "${preset.name}" preset'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _removeArtwork() async {
    final haptics = ref.read(hapticServiceProvider);
    haptics.selection();

    setState(() {
      _currentArtworkKey = null;
      _isSaving = true;
    });

    try {
      final db = ref.read(databaseProvider);
      await db.updateTrackArtwork(widget.track.trackKey, null);
      if (mounted) {
        setState(() => _isSaving = false);
        haptics.light();
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Song artwork reset to default'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.m,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Song Icon & Artwork',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),

          // Live Preview Card
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: AppRadii.cardRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ArtworkWidget(
                    artworkKey: _currentArtworkKey,
                    filePath: widget.track.path,
                    title: widget.track.title,
                    size: 140,
                    borderRadius: 14.0,
                  ),
                ),
                if (_isSaving)
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: AppRadii.cardRadius,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          // Action buttons: Pick from Gallery & Reset
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _isSaving ? null : _pickFromGallery,
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label: const Text('Choose Photo'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_currentArtworkKey != null) ...[
                  const SizedBox(width: AppSpacing.s),
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _removeArtwork,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          // Section Title: Default Placeholder Styles
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Default Styles',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s),

          // Presets Horizontal list
          SizedBox(
            height: 110,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              scrollDirection: Axis.horizontal,
              itemCount: SongArtworkPresets.presets.length,
              itemBuilder: (context, index) {
                final preset = SongArtworkPresets.presets[index];
                final isSelected = _currentArtworkKey == preset.uri;

                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: InkWell(
                    onTap: _isSaving ? null : () => _selectPreset(preset),
                    borderRadius: AppRadii.cardRadius,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                gradient: preset.gradient,
                                borderRadius: AppRadii.cardRadius,
                                border: isSelected
                                    ? Border.all(
                                        color: colorScheme.primary,
                                        width: 2.5,
                                      )
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  preset.icon,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: colorScheme.primary,
                                    size: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 72,
                          child: Text(
                            preset.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
