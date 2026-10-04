sealed class AppError {
  const AppError(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      '$runtimeType: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

class StoragePermissionDeniedError extends AppError {
  const StoragePermissionDeniedError([
    super.message = 'Storage permission was denied.',
    super.cause,
  ]);
}

class CorruptAudioFileError extends AppError {
  const CorruptAudioFileError(String filePath, [Object? cause])
    : super('The audio file at $filePath is corrupted or unreadable.', cause);
}

class MissingAudioFileError extends AppError {
  const MissingAudioFileError(String filePath, [Object? cause])
    : super('The audio file could not be found at $filePath.', cause);
}

class DatabaseMigrationError extends AppError {
  const DatabaseMigrationError(String details, [Object? cause])
    : super('Database migration failure: $details', cause);
}
