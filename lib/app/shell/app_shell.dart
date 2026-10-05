import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/now_playing/now_playing_sheet.dart';
import '../../shared/mini_player/mini_player.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _isNowPlayingExpanded = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) {
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
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
    );
  }
}
