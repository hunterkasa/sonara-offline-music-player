import 'dart:io';

/// tool/seed_music.dart
///
/// Generates tagged sine-wave tracks using ffmpeg, pushes them to the
/// Android device / emulator Music directory via adb, and triggers
/// the Android MediaStore scanner.
void main(List<String> args) async {
  stdout.writeln('=== Sonara Music Seeder Tool ===');

  // 1. Verify ffmpeg
  final ffmpegCheck = await Process.run('ffmpeg', ['-version']).catchError((e) {
    return ProcessResult(0, 1, '', 'ffmpeg not found in PATH');
  });

  if (ffmpegCheck.exitCode != 0) {
    stderr.writeln('ERROR: ffmpeg is not available on PATH.');
    stderr.writeln(
      'Fallback: Manually drop standard MP3/FLAC audio files into the '
      'device /storage/emulated/0/Music/ directory.',
    );
    exit(1);
  }

  // 2. Locate ADB
  String adbPath = 'adb';
  final adbCheck = await Process.run(adbPath, ['version']).catchError((e) {
    return ProcessResult(0, 1, '', 'adb not found');
  });

  if (adbCheck.exitCode != 0) {
    // Try fallback path
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      final fallbackAdb =
          '$localAppData\\Android\\Sdk\\platform-tools\\adb.exe';
      if (File(fallbackAdb).existsSync()) {
        adbPath = fallbackAdb;
      } else {
        stderr.writeln('ERROR: adb was not found in PATH or Android SDK.');
        exit(1);
      }
    }
  }

  // Check connected devices
  final devicesResult = await Process.run(adbPath, ['devices']);
  stdout.writeln('Connected ADB devices:\n${devicesResult.stdout}');

  // 3. Create temporary output directory for generated tracks
  final tempDir = Directory.systemTemp.createTempSync('sonara_music_seed_');
  stdout.writeln('Generating synthetic audio files in: ${tempDir.path}');

  const tracksToGenerate = [
    _SeedTrack(
      filename: '01_sine_440_acoustic.mp3',
      frequency: 440,
      durationSec: 45,
      title: 'Harmonic Prelude',
      artist: 'Acoustic Labs',
      album: 'Resonance',
      genre: 'Acoustic',
      trackNo: 1,
      year: 2024,
    ),
    _SeedTrack(
      filename: '02_sine_528_solfeggio.flac',
      frequency: 528,
      durationSec: 60,
      title: 'Miracle Frequency',
      artist: 'Solfeggio Ensemble',
      album: 'Resonance',
      genre: 'Ambient',
      trackNo: 2,
      year: 2024,
    ),
    _SeedTrack(
      filename: '03_sine_660_pulse.m4a',
      frequency: 660,
      durationSec: 36,
      title: 'High Pulse',
      artist: 'Sine Wave Collective',
      album: 'Waveforms',
      genre: 'Electronic',
      trackNo: 3,
      year: 2025,
    ),
    _SeedTrack(
      filename: '04_sine_330_warmth.ogg',
      frequency: 330,
      durationSec: 50,
      title: 'Warm Current',
      artist: 'Acoustic Labs',
      album: 'Waveforms',
      genre: 'Ambient',
      trackNo: 4,
      year: 2025,
    ),
    _SeedTrack(
      filename: '05_nebula_drift.mp3',
      frequency: 220,
      durationSec: 40,
      title: 'Nebula Drift',
      artist: 'Cosmic Echoes',
      album: 'Starlight Odyssey',
      genre: 'Ambient',
      trackNo: 1,
      year: 2025,
    ),
  ];

  for (final track in tracksToGenerate) {
    final outputPath = '${tempDir.path}\\${track.filename}';
    stdout.writeln('Synthesizing ${track.filename} (${track.title})...');

    final ffmpegArgs = [
      '-y',
      '-f',
      'lavfi',
      '-i',
      'sine=frequency=${track.frequency}:duration=${track.durationSec}',
      '-metadata',
      'title=${track.title}',
      '-metadata',
      'artist=${track.artist}',
      '-metadata',
      'album=${track.album}',
      '-metadata',
      'genre=${track.genre}',
      '-metadata',
      'track=${track.trackNo}',
      '-metadata',
      'date=${track.year}',
      outputPath,
    ];

    final genResult = await Process.run('ffmpeg', ffmpegArgs);
    if (genResult.exitCode != 0) {
      stderr.writeln(
        'Failed to generate ${track.filename}: ${genResult.stderr}',
      );
    } else {
      stdout.writeln('Successfully generated ${track.filename}');
    }
  }

  // Generate cover.jpg
  final coverPath = '${tempDir.path}\\cover.jpg';
  stdout.writeln('Generating cover.jpg artwork...');
  await Process.run('ffmpeg', [
    '-y',
    '-f',
    'lavfi',
    '-i',
    'color=c=royalblue:s=500x500:d=1',
    '-vframes',
    '1',
    coverPath,
  ]);

  // 4. Push generated tracks to device
  const targetDeviceFolder = '/storage/emulated/0/Music/SonaraTest';
  stdout.writeln('\nCreating target directory on device: $targetDeviceFolder');
  await Process.run(adbPath, ['shell', 'mkdir', '-p', targetDeviceFolder]);

  stdout.writeln('Pushing audio tracks to device via ADB...');
  final pushResult = await Process.run(adbPath, [
    'push',
    tempDir.path,
    targetDeviceFolder,
  ]);
  stdout.writeln(pushResult.stdout);

  // 5. Trigger MediaStore scan
  stdout.writeln('Triggering Android MediaStore scan...');
  for (final track in tracksToGenerate) {
    final remotePath =
        '$targetDeviceFolder/${tempDir.path.split('\\').last}/${track.filename}';
    await Process.run(adbPath, [
      'shell',
      'am',
      'broadcast',
      '-a',
      'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
      '-d',
      'file://$remotePath',
    ]);
  }

  stdout.writeln(
    '\nDone! Seed tracks created and pushed to $targetDeviceFolder',
  );
}

class _SeedTrack {
  const _SeedTrack({
    required this.filename,
    required this.frequency,
    required this.durationSec,
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    required this.trackNo,
    required this.year,
  });

  final String filename;
  final int frequency;
  final int durationSec;
  final String title;
  final String artist;
  final String album;
  final String genre;
  final int trackNo;
  final int year;
}
