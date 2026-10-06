import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/core/logging/local_logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  final logger = LocalLogger.instance;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sonara_logs_test_');
    await logger.init(overrideDir: tempDir);
  });

  tearDown(() async {
    await logger.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('LocalLogger Tests', () {
    test('writes info, warning, and error logs into file', () async {
      logger.info('Test info message');
      logger.warning('Test warning message');
      logger.error('Test error message', Exception('TestException'));

      // Allow async write to flush
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final logs = await logger.readLogs();
      expect(logs, contains('[INFO] Test info message'));
      expect(logs, contains('[WARN] Test warning message'));
      expect(
        logs,
        contains(
          '[ERROR] Test error message | Error: Exception: TestException',
        ),
      );
    });

    test('clears logs successfully', () async {
      logger.info('Temporary message');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await logger.clearLogs();
      final logsAfterClear = await logger.readLogs();
      expect(logsAfterClear.trim(), isEmpty);
    });
  });
}
