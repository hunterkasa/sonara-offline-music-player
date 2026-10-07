import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../../audio/playback_controller.dart';
import '../../domain/models/audio_settings.dart';
import '../../domain/services/audio_settings_service.dart';
import '../../features/now_playing/now_playing_sheet.dart';
import '../../shared/mini_player/mini_player.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  bool _isNowPlayingExpanded = false;
  final List<int> _tabHistory = [0];
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      final audioSettings = ref.read(audioSettingsProvider);
      if (!audioSettings.backgroundPlayback) {
        ref.read(playbackControllerProvider).pause();
      }
    }
  }

  void _openNowPlaying() {
    setState(() {
      _isNowPlayingExpanded = true;
    });
  }

  void _collapseNowPlaying() {
    setState(() {
      _isNowPlayingExpanded = false;
    });
  }

  void _handlePop(bool didPop) {
    if (didPop) return;

    // 1. If Now Playing is open, collapse it
    if (_isNowPlayingExpanded) {
      _collapseNowPlaying();
      return;
    }

    // 2. If user came from a previous tab, go back to it
    if (_tabHistory.length > 1) {
      setState(() {
        _tabHistory.removeLast();
        final prevIndex = _tabHistory.last;
        widget.navigationShell.goBranch(prevIndex);
      });
      return;
    }

    // 3. User is at root Home tab: prompt to press back again to exit
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      unawaited(SystemNavigator.pop());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = widget.navigationShell.currentIndex;
    final audioSettings = ref.watch(audioSettingsProvider);
    final themeMode = ref.watch(themeModeProvider);

    final isOled =
        themeMode == AppThemeMode.amoled ||
        audioSettings.nowPlayingSkin == NowPlayingSkin.minimalistOled ||
        theme.scaffoldBackgroundColor == Colors.black;
    final isWhite = theme.brightness == Brightness.light && !isOled;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _handlePop(didPop),
      child: Scaffold(
        backgroundColor: isOled
            ? Colors.black
            : (isWhite ? Colors.white : theme.scaffoldBackgroundColor),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(child: widget.navigationShell),
                MiniPlayer(onTap: _openNowPlaying),
              ],
            ),
            if (_isNowPlayingExpanded)
              Positioned.fill(
                child: NowPlayingSheet(onCollapse: _collapseNowPlaying),
              ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isOled
                ? Colors.black
                : (isWhite
                      ? Colors.white
                      : theme.navigationBarTheme.backgroundColor),
            border: isOled
                ? const Border(
                    top: BorderSide(color: Colors.white12, width: 0.8),
                  )
                : (isWhite
                      ? const Border(
                          top: BorderSide(color: Color(0xFFE8E8E8), width: 0.8),
                        )
                      : null),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            elevation: 0,
            backgroundColor: isOled
                ? Colors.black
                : (isWhite ? Colors.white : null),
            surfaceTintColor: Colors.transparent,
            indicatorColor: isOled
                ? Colors.white12
                : (isWhite
                      ? theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.45,
                        )
                      : null),
            onDestinationSelected: (index) {
              if (index != currentIndex) {
                _tabHistory.add(index);
              }
              widget.navigationShell.goBranch(
                index,
                initialLocation: index == currentIndex,
              );
            },
            destinations: [
              NavigationDestination(
                icon: Icon(
                  Icons.home_outlined,
                  color: isOled && currentIndex != 0 ? Colors.white60 : null,
                ),
                selectedIcon: Icon(
                  Icons.home_rounded,
                  color: isOled ? Colors.white : null,
                ),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.search_rounded,
                  color: isOled && currentIndex != 1 ? Colors.white60 : null,
                ),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.library_music_outlined,
                  color: isOled && currentIndex != 2 ? Colors.white60 : null,
                ),
                selectedIcon: Icon(
                  Icons.library_music_rounded,
                  color: isOled ? Colors.white : null,
                ),
                label: 'Library',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
