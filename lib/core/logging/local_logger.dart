import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final localLoggerProvider = Provider<LocalLogger>((ref) {
  return LocalLogger.instance;
});

class LocalLogger {
  LocalLogger._();

  static final LocalLogger instance = LocalLogger._();

  File? _logFile;
  File? _prevLogFile;
  IOSink? _sink;

  static const int maxFileSizeBytes = 1024 * 1024; // 1 MB per log file

  Future<void> init({Directory? overrideDir}) async {
    try {
      final dir = overrideDir ?? await getApplicationDocumentsDirectory();
      final logsDir = Directory(p.join(dir.path, 'logs'));
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }
      _logFile = File(p.join(logsDir.path, 'sonara.log'));
      _prevLogFile = File(p.join(logsDir.path, 'sonara.log.old'));

      await _rotateIfNeeded();
      _openSink();

      info('LocalLogger initialized. App starting.');
    } catch (e) {
      debugPrint('Failed to initialize LocalLogger: $e');
    }
  }

  void _openSink() {
    final file = _logFile;
    if (file == null) return;
    _sink = file.openWrite(mode: FileMode.append);
  }

  Future<void> _rotateIfNeeded() async {
    final file = _logFile;
    if (file == null) return;
    if (await file.exists() && await file.length() > maxFileSizeBytes) {
      final prev = _prevLogFile;
      if (prev != null) {
        if (await prev.exists()) {
          await prev.delete();
        }
        await file.rename(prev.path);
      }
    }
  }

  void info(String message) {
    _enqueue('INFO', message);
  }

  void warning(String message) {
    _enqueue('WARN', message);
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    final sb = StringBuffer(message);
    if (error != null) {
      sb.write(' | Error: $error');
    }
    if (stackTrace != null) {
      sb.write('\n$stackTrace');
    }
    _enqueue('ERROR', sb.toString());
  }

  void _enqueue(String level, String text) {
    final timestamp = DateTime.now().toIso8601String();
    final logLine = '[$timestamp] [$level] $text';
    if (kDebugMode) {
      debugPrint('[$level] $text');
    }
    _sink?.writeln(logLine);
  }

  Future<String> readLogs() async {
    await _sink?.flush();
    final sb = StringBuffer();
    final prev = _prevLogFile;
    if (prev != null && await prev.exists()) {
      try {
        sb.writeln('=== PREVIOUS LOG SESSION ===');
        sb.writeln(await prev.readAsString());
        sb.writeln('=== CURRENT LOG SESSION ===');
      } catch (_) {}
    }
    final cur = _logFile;
    if (cur != null && await cur.exists()) {
      try {
        sb.write(await cur.readAsString());
      } catch (_) {}
    }
    return sb.toString();
  }

  Future<void> clearLogs() async {
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
    try {
      if (_logFile != null && await _logFile!.exists()) {
        await _logFile!.delete();
      }
      if (_prevLogFile != null && await _prevLogFile!.exists()) {
        await _prevLogFile!.delete();
      }
    } catch (e) {
      debugPrint('Error clearing logs: $e');
    }
    _openSink();
  }

  Future<void> dispose() async {
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
  }
}
