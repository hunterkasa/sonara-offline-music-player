import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/core/constants/licenses.dart';

void main() {
  test(
    'kSonaraMitLicense contains required MIT copyright and warranty clauses',
    () {
      expect(kSonaraMitLicense, contains('MIT License'));
      expect(
        kSonaraMitLicense,
        contains('Copyright (c) 2026 Sonara Contributors'),
      );
      expect(
        kSonaraMitLicense,
        contains('Permission is hereby granted, free of charge'),
      );
      expect(kSonaraMitLicense, contains('THE SOFTWARE IS PROVIDED "AS IS"'));
    },
  );

  test('registerSonaraLicense adds Sonara to LicenseRegistry', () async {
    registerSonaraLicense();
    // Subsequent calls are idempotent
    registerSonaraLicense();

    final entries = await LicenseRegistry.licenses.toList();
    final sonaraEntries = entries.where(
      (entry) => entry.packages.contains('Sonara (Application)'),
    );

    expect(sonaraEntries, isNotEmpty);
    final paragraphs = sonaraEntries.first.paragraphs
        .map((p) => p.text)
        .join('\n');
    expect(paragraphs, contains('Copyright (c) 2026 Sonara Contributors'));
  });
}
