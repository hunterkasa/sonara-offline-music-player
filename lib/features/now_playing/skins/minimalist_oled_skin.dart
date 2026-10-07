import 'package:flutter/material.dart';

import '../../../app/theme/theme_tokens.dart';
import '../../../audio/playback_controller.dart';
import '../../../shared/artwork/artwork_widget.dart';

class MinimalistOledSkin extends StatelessWidget {
  const MinimalistOledSkin({
    super.key,
    required this.snapshot,
    this.artworkKey,
    this.filePath,
    required this.title,
  });

  final PlaybackSnapshot snapshot;
  final String? artworkKey;
  final String? filePath;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Monochromatic artwork frame
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
                child: ArtworkWidget(
                  artworkKey: artworkKey,
                  filePath: filePath,
                  title: title,
                  size: 180,
                  borderRadius: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // High contrast OLED typography
          Text(
            snapshot.title.isNotEmpty ? snapshot.title : 'No Track Selected',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            snapshot.artist.isNotEmpty ? snapshot.artist : 'Unknown Artist',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'OLED PURE BLACK',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 9,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
