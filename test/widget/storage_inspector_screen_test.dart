import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/domain/services/storage_inspector_service.dart';
import 'package:sonara/features/library_tools/storage_inspector_screen.dart';

void main() {
  testWidgets(
    'StorageInspectorScreen displays storage metrics and action buttons',
    (tester) async {
      const mockInfo = StorageInfo(
        databaseSizeBytes: 2048000,
        artworkCacheSizeBytes: 5120000,
        artworkCachedFilesCount: 42,
        totalTracksCount: 150,
        totalAlbumsCount: 12,
        totalArtistsCount: 8,
        totalPlaylistsCount: 3,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageInfoProvider.overrideWith((ref) => Future.value(mockInfo)),
          ],
          child: const MaterialApp(home: StorageInspectorScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Storage Inspector'), findsOneWidget);
      expect(find.text('Total Sonara Storage'), findsOneWidget);
      expect(find.text('Artwork Thumbnail Cache'), findsOneWidget);
      expect(find.text('Database & Index'), findsOneWidget);
      expect(find.text('Clear Artwork Cache'), findsOneWidget);
      expect(find.text('Optimize Database (VACUUM)'), findsOneWidget);
      expect(find.text('42 files'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
    },
  );
}
