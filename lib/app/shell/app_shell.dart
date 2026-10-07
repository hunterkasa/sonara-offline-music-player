import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../audio/playback_controller.dart';
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
    final currentIndex = widget.navigationShell.currentIndex;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _handlePop(didPop),
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: widget.navigationShell,
                ),
                MiniPlayer(onTap: _openNowPlaying),
              ],
            ),
            if (_isNowPlayingExpanded)
              Positioned.fill(
                child: NowPlayingSheet(onCollapse: _collapseNowPlaying),
              ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            if (index != currentIndex) {
              _tabHistory.add(index);
            }
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == currentIndex,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_rounded),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.library_music_outlined),
              selectedIcon: Icon(Icons.library_music_rounded),
              label: 'Library',
            ),
          ],
        ),
      ),
    );
  }
}
