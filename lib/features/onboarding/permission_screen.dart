import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonara/core/services/permission_service.dart';
import 'package:sonara/domain/services/library_scanner.dart';

class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
  AudioPermissionStatus? _status;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final service = ref.read(permissionServiceProvider);
    final status = await service.checkAudioPermission();
    if (mounted) {
      setState(() => _status = status);
      if (status == AudioPermissionStatus.granted) {
        // Trigger initial scan if needed and proceed
        unawaited(ref.read(libraryScannerProvider.notifier).scanLibrary());
      }
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);
    final service = ref.read(permissionServiceProvider);
    final status = await service.requestAudioPermission();
    if (mounted) {
      setState(() {
        _status = status;
        _isRequesting = false;
      });
      if (status == AudioPermissionStatus.granted) {
        await ref.read(libraryScannerProvider.notifier).scanLibrary();
        if (mounted) {
          context.go('/home');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scanProgress = ref.watch(libraryScannerProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 96.0,
                height: 96.0,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.music_note_rounded,
                  size: 56.0,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 28.0),
              Text(
                'Welcome to Sonara',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12.0),
              Text(
                'Your premium, private, offline-first music sanctuary. To play your local music, Sonara needs permission to read audio files on your device.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      color: colorScheme.primary,
                      size: 28.0,
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '100% Offline & Private',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'Zero network access. No telemetry. Your files and library stay strictly on your device.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (scanProgress.isScanning) ...[
                LinearProgressIndicator(
                  value: scanProgress.totalCount > 0
                      ? scanProgress.scannedCount / scanProgress.totalCount
                      : null,
                ),
                const SizedBox(height: 12.0),
                Text(
                  scanProgress.statusMessage ?? 'Scanning music...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (scanProgress.totalCount > 0)
                  Text(
                    '${scanProgress.scannedCount} of ${scanProgress.totalCount} tracks',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                const SizedBox(height: 16.0),
              ] else if (_status ==
                  AudioPermissionStatus.permanentlyDenied) ...[
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Text(
                          'Permission was permanently denied. Please enable audio storage access in Android System Settings.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
                FilledButton.icon(
                  onPressed: () async {
                    await ref.read(permissionServiceProvider).openSettings();
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Open App Settings'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52.0),
                  ),
                ),
              ] else ...[
                FilledButton.icon(
                  onPressed: _isRequesting ? null : _requestPermission,
                  icon: const Icon(Icons.folder_open_rounded),
                  label: Text(_isRequesting ? 'Requesting...' : 'Grant Access'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52.0),
                  ),
                ),
                const SizedBox(height: 12.0),
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Skip for now'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
