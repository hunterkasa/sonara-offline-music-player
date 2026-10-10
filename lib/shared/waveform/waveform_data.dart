import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

/// Generates and caches deterministic normalized waveform amplitude peaks
/// (values from 0.08 to 1.0) for tracks.
class WaveformGenerator {
  static const int defaultSamplesCount = 64;

  static final Map<String, List<double>> _cache = {};

  /// Returns cached waveform peaks or synthesizes them deterministically.
  static List<double> getWaveformPeaks(
    String trackKey, {
    int samples = defaultSamplesCount,
  }) {
    final cached = _cache[trackKey];
    if (cached != null && cached.length == samples) {
      return cached;
    }

    final peaks = synthesizePeaks(trackKey, samples: samples);
    _cache[trackKey] = peaks;
    return peaks;
  }

  /// Extracts real audio amplitude peaks from file (PCM RMS for WAV,
  /// audio frame energy distribution for compressed streams), with fallback to
  /// deterministic synthesis.
  static Future<List<double>> extractPeaksFromFile({
    required String trackKey,
    required String filePath,
    int samples = defaultSamplesCount,
  }) async {
    final cached = _cache[trackKey];
    if (cached != null && cached.length == samples) {
      return cached;
    }

    final peaks = await compute(
      _extractPeaksWorker,
      _WaveformExtractionRequest(
        trackKey: trackKey,
        filePath: filePath,
        samples: samples,
      ),
    );

    _cache[trackKey] = peaks;
    return peaks;
  }

  /// Synthesizes realistic audio waveform envelope deterministically from trackKey.
  static List<double> synthesizePeaks(
    String trackKey, {
    int samples = defaultSamplesCount,
  }) {
    // Seed Random with deterministic integer hash of trackKey
    final seed = trackKey.hashCode.abs();
    final rng = Random(seed);

    final peaks = <double>[];
    final baseFreq1 = 1.0 + (rng.nextDouble() * 3.0);
    final baseFreq2 = 3.0 + (rng.nextDouble() * 5.0);
    final phase1 = rng.nextDouble() * 2 * pi;
    final phase2 = rng.nextDouble() * 2 * pi;

    for (var i = 0; i < samples; i++) {
      final t = i / samples;

      // Envelope: softer intro and outro, fuller in the body
      final envelope = sin(t * pi);

      // Primary harmonics
      final h1 = (sin(t * 2 * pi * baseFreq1 + phase1) + 1.0) / 2.0;
      final h2 = (sin(t * 2 * pi * baseFreq2 + phase2) + 1.0) / 2.0;
      final noise = rng.nextDouble() * 0.25;

      final combined = (0.5 * h1 + 0.3 * h2 + noise) * envelope;
      peaks.add(combined.clamp(0.08, 1.0));
    }

    return peaks;
  }

  static void clearCache() {
    _cache.clear();
  }
}

class _WaveformExtractionRequest {
  final String trackKey;
  final String filePath;
  final int samples;

  const _WaveformExtractionRequest({
    required this.trackKey,
    required this.filePath,
    required this.samples,
  });
}

List<double> _extractPeaksWorker(_WaveformExtractionRequest req) {
  final file = File(req.filePath);
  if (!file.existsSync()) {
    return WaveformGenerator.synthesizePeaks(
      req.trackKey,
      samples: req.samples,
    );
  }

  try {
    final length = file.lengthSync();
    if (length < 128) {
      return WaveformGenerator.synthesizePeaks(
        req.trackKey,
        samples: req.samples,
      );
    }

    final lowerPath = req.filePath.toLowerCase();
    if (lowerPath.endsWith('.wav')) {
      final wavPeaks = _extractWavRms(file, length, req.samples);
      if (wavPeaks != null && wavPeaks.length == req.samples) {
        return wavPeaks;
      }
    }

    // Compressed audio (MP3, M4A, FLAC, OGG) energy extraction
    final energyPeaks = _extractCompressedEnergy(file, length, req.samples);
    if (energyPeaks != null && energyPeaks.length == req.samples) {
      return energyPeaks;
    }
  } catch (_) {}

  return WaveformGenerator.synthesizePeaks(req.trackKey, samples: req.samples);
}

List<double>? _extractWavRms(File file, int fileSize, int samples) {
  final raf = file.openSync(mode: FileMode.read);
  try {
    final header = raf.readSync(44);
    if (header.length < 44) return null;
    final headerData = ByteData.sublistView(header);

    // Verify RIFF & WAVE markers
    if (header[0] != 0x52 ||
        header[1] != 0x49 ||
        header[2] != 0x46 ||
        header[3] != 0x46 ||
        header[8] != 0x57 ||
        header[9] != 0x41 ||
        header[10] != 0x56 ||
        header[11] != 0x45) {
      return null;
    }

    final numChannels = headerData.getUint16(22, Endian.little);
    final bitsPerSample = headerData.getUint16(34, Endian.little);
    if (numChannels == 0 || bitsPerSample != 16) {
      return null;
    }

    var dataOffset = 44;
    var dataSize = fileSize - 44;

    if (fileSize > 200) {
      raf.setPositionSync(12);
      final searchBytes = raf.readSync(188);
      for (var i = 0; i < searchBytes.length - 8; i++) {
        if (searchBytes[i] == 0x64 &&
            searchBytes[i + 1] == 0x61 &&
            searchBytes[i + 2] == 0x74 &&
            searchBytes[i + 3] == 0x61) {
          dataOffset = 12 + i + 8;
          final bd = ByteData.sublistView(searchBytes, i + 4, i + 8);
          dataSize = bd.getUint32(0, Endian.little);
          break;
        }
      }
    }

    if (dataSize <= 0 || dataOffset + dataSize > fileSize) {
      dataSize = fileSize - dataOffset;
    }

    final bytesPerSample = (bitsPerSample ~/ 8) * numChannels;
    final totalSamples = dataSize ~/ bytesPerSample;
    if (totalSamples < samples) return null;

    final step = totalSamples ~/ samples;
    final windowSamples = step.clamp(32, 2048);
    final rawRms = <double>[];

    for (var i = 0; i < samples; i++) {
      final sampleIndex = i * step;
      final filePos = dataOffset + (sampleIndex * bytesPerSample);
      raf.setPositionSync(filePos);
      final readLen = windowSamples * bytesPerSample;
      final buf = raf.readSync(
        readLen.clamp(0, dataSize - (sampleIndex * bytesPerSample)),
      );
      if (buf.length < 2) {
        rawRms.add(0.0);
        continue;
      }

      final bd = ByteData.sublistView(buf);
      var sumSquares = 0.0;
      final count = buf.length ~/ 2;
      for (var s = 0; s < count; s += numChannels) {
        final val = bd.getInt16(s * 2, Endian.little);
        final norm = val / 32768.0;
        sumSquares += norm * norm;
      }
      final rms = sqrt(sumSquares / (count ~/ numChannels).clamp(1, count));
      rawRms.add(rms);
    }

    return _normalizePeaks(rawRms);
  } finally {
    raf.closeSync();
  }
}

List<double>? _extractCompressedEnergy(File file, int fileSize, int samples) {
  final raf = file.openSync(mode: FileMode.read);
  try {
    var startOffset = 0;
    final id3Header = raf.readSync(10);
    if (id3Header.length == 10 &&
        id3Header[0] == 0x49 &&
        id3Header[1] == 0x44 &&
        id3Header[2] == 0x33) {
      final size =
          ((id3Header[6] & 0x7F) << 21) |
          ((id3Header[7] & 0x7F) << 14) |
          ((id3Header[8] & 0x7F) << 7) |
          (id3Header[9] & 0x7F);
      startOffset = 10 + size;
    }

    final audioPayloadSize = (fileSize - startOffset).clamp(1024, fileSize);
    final step = audioPayloadSize ~/ samples;
    final windowSize = step.clamp(128, 4096);
    final rawEnergy = <double>[];

    for (var i = 0; i < samples; i++) {
      final pos = startOffset + (i * step);
      raf.setPositionSync(pos.clamp(0, fileSize - windowSize));
      final chunk = raf.readSync(windowSize);
      if (chunk.isEmpty) {
        rawEnergy.add(0.0);
        continue;
      }
      var devSum = 0.0;
      for (var b = 0; b < chunk.length; b++) {
        devSum += (chunk[b] - 128).abs() / 128.0;
      }
      rawEnergy.add(devSum / chunk.length);
    }

    return _normalizePeaks(rawEnergy);
  } finally {
    raf.closeSync();
  }
}

List<double> _normalizePeaks(List<double> raw) {
  var maxVal = 0.0;
  for (final v in raw) {
    if (v > maxVal) maxVal = v;
  }
  if (maxVal <= 0.0001) maxVal = 1.0;
  return raw.map((v) => (v / maxVal).clamp(0.08, 1.0)).toList();
}
