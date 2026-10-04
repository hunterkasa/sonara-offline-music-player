import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/core/errors/app_error.dart';

void main() {
  group('AppError', () {
    test('formats error messages correctly', () {
      const e1 = StoragePermissionDeniedError();
      expect(e1.toString(), contains('Storage permission was denied.'));

      const e2 = CorruptAudioFileError('/path/test.mp3');
      expect(e2.toString(), contains('corrupted or unreadable'));

      const e3 = MissingAudioFileError('/path/missing.flac');
      expect(e3.toString(), contains('could not be found'));

      const e4 = DatabaseMigrationError('V1 failure', 'Disk full');
      expect(e4.toString(), contains('V1 failure'));
      expect(e4.toString(), contains('Disk full'));
    });
  });
}
