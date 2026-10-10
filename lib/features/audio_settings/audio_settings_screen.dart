import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme_tokens.dart';
import '../../core/services/haptic_service.dart';
import '../../domain/models/audio_device_profile.dart';
import '../../domain/models/audio_settings.dart';
import '../../domain/models/equalizer_preset.dart';
import '../../domain/services/audio_settings_service.dart';
import '../../domain/services/device_profile_service.dart';

class AudioSettingsScreen extends ConsumerWidget {
  const AudioSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(audioSettingsProvider);
    final notifier = ref.read(audioSettingsProvider.notifier);
    final haptics = ref.read(hapticServiceProvider);
    final profileService = ref.watch(deviceProfileServiceProvider);
    final activeCategoryAsync = ref.watch(activeOutputCategoryProvider);
    final activeCategory =
        activeCategoryAsync.value ?? profileService.currentCategory;

    return Scaffold(
      appBar: AppBar(title: const Text('Audio Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        children: [
          // EQUALIZER SECTION
          _buildSectionHeader(context, 'EQUALIZER & SOUND EFFECTS'),
          ListTile(
            leading: const Icon(Icons.equalizer_rounded),
            title: const Text('Equalizer & Presets'),
            subtitle: Text(
              settings.equalizerEnabled
                  ? 'On · ${settings.equalizerPreset.toUpperCase()}'
                  : 'Off (Tap to configure)',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              haptics.light();
              context.push('/equalizer');
            },
          ),
          const Divider(),

          // PLAYBACK & TRANSITIONS SECTION
          _buildSectionHeader(context, 'PLAYBACK TRANSITIONS'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Crossfade Duration',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      settings.crossfadeDurationSeconds == 0
                          ? '0s (Gapless)'
                          : '${settings.crossfadeDurationSeconds}s',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Smoothly blends consecutive tracks together',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Slider(
                  value: settings.crossfadeDurationSeconds.toDouble(),
                  min: 0,
                  max: 12,
                  divisions: 12,
                  label: '${settings.crossfadeDurationSeconds}s',
                  onChanged: (val) {
                    notifier.setCrossfadeDuration(val.round());
                  },
                ),
              ],
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.volume_down_rounded),
            title: const Text('Smooth Volume Fades'),
            subtitle: const Text(
              '200ms volume ramp on manual pause, resume, and skip to eliminate audio pops',
            ),
            value: settings.smoothFades,
            onChanged: (val) {
              haptics.selection();
              notifier.setSmoothFades(val);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.play_circle_outline_rounded),
            title: const Text('Background Playback'),
            subtitle: const Text(
              'Keep music playing when leaving the app or locking the screen',
            ),
            value: settings.backgroundPlayback,
            onChanged: (val) {
              haptics.selection();
              notifier.setBackgroundPlayback(val);
            },
          ),
          const Divider(),

          // VOLUME NORMALIZATION (REPLAYGAIN)
          _buildSectionHeader(context, 'VOLUME NORMALIZATION (REPLAYGAIN)'),
          ListTile(
            leading: const Icon(Icons.tune_rounded),
            title: const Text('ReplayGain Mode'),
            subtitle: Text(_replayGainModeSubtitle(settings.replayGainMode)),
            trailing: const Icon(Icons.arrow_drop_down_rounded),
            onTap: () =>
                _showReplayGainDialog(context, ref, settings.replayGainMode),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pre-Amp Gain', style: theme.textTheme.titleMedium),
                    Text(
                      '${settings.replayGainPreAmpDb > 0 ? '+' : ''}${settings.replayGainPreAmpDb.toStringAsFixed(1)} dB',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Adjust baseline volume for tracks with ReplayGain tags',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Slider(
                  value: settings.replayGainPreAmpDb,
                  min: -12.0,
                  max: 12.0,
                  divisions: 48,
                  label:
                      '${settings.replayGainPreAmpDb > 0 ? '+' : ''}${settings.replayGainPreAmpDb.toStringAsFixed(1)} dB',
                  onChanged: (val) {
                    notifier.setReplayGainPreAmp(val);
                  },
                ),
              ],
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.shield_rounded),
            title: const Text('Prevent Clipping'),
            subtitle: const Text(
              'Clamps peak volume to avoid digital saturation and distortion',
            ),
            value: settings.preventClipping,
            onChanged: (val) {
              haptics.selection();
              notifier.setPreventClipping(val);
            },
          ),
          const Divider(),

          // PLATFORM AUDIO CONTROLS
          _buildSectionHeader(context, 'PLAYBACK ENGINE & HARDWARE'),
          SwitchListTile(
            secondary: const Icon(Icons.graphic_eq_rounded),
            title: const Text('Skip Silence'),
            subtitle: const Text(
              'Skip silence between songs and at track boundaries',
            ),
            value: settings.skipSilence,
            onChanged: (val) {
              haptics.selection();
              notifier.setSkipSilence(val);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stereo Channel Balance',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      _stereoBalanceText(settings.stereoBalance),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'L',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: settings.stereoBalance,
                        min: -1.0,
                        max: 1.0,
                        divisions: 20,
                        onChanged: (val) {
                          notifier.setStereoBalance(val);
                        },
                      ),
                    ),
                    Text(
                      'R',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.headphones_rounded),
            title: const Text('Mono Downmix'),
            subtitle: const Text(
              'Combines left and right audio into a single mono signal',
            ),
            value: settings.monoDownmix,
            onChanged: (val) {
              haptics.selection();
              notifier.setMonoDownmix(val);
            },
          ),
          const Divider(),

          // LONG-AUDIO MEMORY SECTION
          _buildSectionHeader(context, 'LONG AUDIO RESUMPTION'),
          SwitchListTile(
            secondary: const Icon(Icons.history_rounded),
            title: const Text('Long-Audio Position Memory'),
            subtitle: const Text(
              'Auto-resume playback position and speed for tracks longer than 20 minutes (podcasts, DJ sets, audiobooks)',
            ),
            value: settings.longAudioPositionMemory,
            onChanged: (val) {
              haptics.selection();
              notifier.setLongAudioPositionMemory(val);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.speed_rounded),
            title: const Text('Remember Speed & Pitch'),
            subtitle: const Text(
              'Persist custom playback speed and musical pitch key across app restarts instead of resetting to 1.0x',
            ),
            value: settings.rememberSpeedAndPitch,
            onChanged: (val) {
              haptics.selection();
              notifier.setRememberSpeedAndPitch(val);
            },
          ),
          const Divider(),

          // PER-OUTPUT-DEVICE PROFILES SECTION
          _buildSectionHeader(context, 'PER-OUTPUT AUDIO PROFILES'),
          SwitchListTile(
            secondary: const Icon(Icons.devices_rounded),
            title: const Text('Auto-Switch Output Profiles'),
            subtitle: const Text(
              'Remember distinct EQ presets, crossfade, and sound tweaks per output device and auto-apply when connected',
            ),
            value: settings.deviceProfilesEnabled,
            onChanged: (val) {
              haptics.selection();
              notifier.setDeviceProfilesEnabled(val);
            },
          ),
          if (settings.deviceProfilesEnabled) ...[
            for (final category in AudioOutputCategory.values)
              _buildCategoryTile(
                context,
                category,
                profileService,
                category == activeCategory,
                haptics,
              ),
          ],
          const Divider(),

          // NOW PLAYING PLAYER SKIN
          _buildSectionHeader(context, 'NOW PLAYING PLAYER SKIN'),
          ListTile(
            leading: const Icon(Icons.style_rounded),
            title: const Text('Active Player Skin'),
            subtitle: Text(switch (settings.nowPlayingSkin) {
              NowPlayingSkin.defaultModern =>
                'Default Modern (Adaptive Gradient)',
              NowPlayingSkin.spinningVinyl =>
                'Spinning Vinyl Turntable (33 RPM)',
              NowPlayingSkin.retroCassette =>
                'Retro 90s Cassette (Animated Spools)',
              NowPlayingSkin.minimalistOled => 'Minimalist OLED (Pure Black)',
            }),
            trailing: const Icon(Icons.arrow_drop_down_rounded),
            onTap: () => _showSkinDialog(context, ref, settings.nowPlayingSkin),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    AudioOutputCategory category,
    DeviceProfileService service,
    bool isCurrent,
    HapticService haptics,
  ) {
    final theme = Theme.of(context);
    final profile = service.getProfile(category);
    final icon = switch (category) {
      AudioOutputCategory.speaker => Icons.volume_up_rounded,
      AudioOutputCategory.bluetooth => Icons.bluetooth_audio_rounded,
      AudioOutputCategory.wired => Icons.headphones_rounded,
      AudioOutputCategory.usb => Icons.usb_rounded,
    };

    return ListTile(
      leading: Icon(icon, color: isCurrent ? theme.colorScheme.primary : null),
      title: Row(
        children: [
          Text(profile.name),
          if (isCurrent) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'CONNECTED',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        'Preset: ${profile.equalizerPreset.toUpperCase()} · Crossfade: ${profile.crossfadeSeconds}s',
      ),
      trailing: const Icon(Icons.tune_rounded, size: 20),
      onTap: () {
        haptics.light();
        _showProfileDialog(context, service, profile);
      },
    );
  }

  void _showProfileDialog(
    BuildContext context,
    DeviceProfileService service,
    AudioDeviceProfile profile,
  ) {
    var selectedPreset = profile.equalizerPreset;
    var crossfadeSeconds = profile.crossfadeSeconds;
    var bassBoost = profile.bassBoost;
    var monoDownmix = profile.monoDownmix;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('${profile.name} Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Equalizer Preset',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: selectedPreset,
                      isExpanded: true,
                      items: EqualizerPreset.defaultPresets.map((p) {
                        return DropdownMenuItem<String>(
                          value: p.id,
                          child: Text(p.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => selectedPreset = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Crossfade: ${crossfadeSeconds}s',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: crossfadeSeconds.toDouble(),
                      min: 0,
                      max: 12,
                      divisions: 12,
                      label: '${crossfadeSeconds}s',
                      onChanged: (v) {
                        setState(() => crossfadeSeconds = v.round());
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bass Boost: ${(bassBoost * 100).round()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: bassBoost,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      label: '${(bassBoost * 100).round()}%',
                      onChanged: (v) {
                        setState(() => bassBoost = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mono Downmix'),
                      value: monoDownmix,
                      onChanged: (v) {
                        setState(() => monoDownmix = v);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final updated = profile.copyWith(
                      equalizerPreset: selectedPreset,
                      crossfadeSeconds: crossfadeSeconds,
                      bassBoost: bassBoost,
                      monoDownmix: monoDownmix,
                    );
                    await service.saveProfile(updated);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.xs,
      ),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  String _replayGainModeSubtitle(ReplayGainMode mode) {
    switch (mode) {
      case ReplayGainMode.smart:
        return 'Smart (Track gain in shuffle, Album gain in sequential)';
      case ReplayGainMode.track:
        return 'Track Gain (Uniform loudness for each track)';
      case ReplayGainMode.album:
        return 'Album Gain (Preserves album dynamic master)';
      case ReplayGainMode.off:
        return 'Off';
    }
  }

  String _stereoBalanceText(double balance) {
    if (balance == 0.0) return 'Center';
    if (balance < 0) return 'L ${(-balance * 100).round()}%';
    return 'R ${(balance * 100).round()}%';
  }

  void _showReplayGainDialog(
    BuildContext context,
    WidgetRef ref,
    ReplayGainMode current,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('ReplayGain Mode'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                ref
                    .read(audioSettingsProvider.notifier)
                    .setReplayGainMode(ReplayGainMode.smart);
                Navigator.pop(ctx);
              },
              child: const Text('Smart (Recommended)'),
            ),
            SimpleDialogOption(
              onPressed: () {
                ref
                    .read(audioSettingsProvider.notifier)
                    .setReplayGainMode(ReplayGainMode.track);
                Navigator.pop(ctx);
              },
              child: const Text('Track Gain'),
            ),
            SimpleDialogOption(
              onPressed: () {
                ref
                    .read(audioSettingsProvider.notifier)
                    .setReplayGainMode(ReplayGainMode.album);
                Navigator.pop(ctx);
              },
              child: const Text('Album Gain'),
            ),
            SimpleDialogOption(
              onPressed: () {
                ref
                    .read(audioSettingsProvider.notifier)
                    .setReplayGainMode(ReplayGainMode.off);
                Navigator.pop(ctx);
              },
              child: const Text('Off'),
            ),
          ],
        );
      },
    );
  }

  void _showSkinDialog(
    BuildContext context,
    WidgetRef ref,
    NowPlayingSkin currentSkin,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Select Player Skin'),
          children: [
            for (final skin in NowPlayingSkin.values)
              SimpleDialogOption(
                onPressed: () {
                  ref
                      .read(audioSettingsProvider.notifier)
                      .setNowPlayingSkin(skin);
                  Navigator.pop(ctx);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(switch (skin) {
                      NowPlayingSkin.defaultModern => 'Default Modern',
                      NowPlayingSkin.spinningVinyl =>
                        'Spinning Vinyl Turntable',
                      NowPlayingSkin.retroCassette => 'Retro 90s Cassette',
                      NowPlayingSkin.minimalistOled => 'Minimalist OLED',
                    }),
                    if (skin == currentSkin)
                      const Icon(
                        Icons.check_rounded,
                        color: Colors.green,
                        size: 20,
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
