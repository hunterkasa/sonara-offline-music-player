import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/features/library_tools/backup_restore_screen.dart';

void main() {
  testWidgets(
    'BackupRestoreScreen renders export card and local backups section',
    (tester) async {
      final db = AppDatabase.inMemory();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            localBackupsProvider.overrideWith((ref) => <File>[]),
          ],
          child: const MaterialApp(home: BackupRestoreScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Backup & Restore'), findsOneWidget);
      expect(find.text('Export Library Backup'), findsOneWidget);
      expect(find.text('Create Backup Now'), findsOneWidget);
      expect(find.text('No local backups saved yet'), findsOneWidget);

      await db.close();
    },
  );
}
