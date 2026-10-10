import 'package:flutter/material.dart';

/// Container that smoothly animates transitions between branch Navigators
/// (e.g. Home, Search, Library) in a [StatefulShellRoute].
class AnimatedBranchContainer extends StatelessWidget {
  const AnimatedBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
    this.duration = const Duration(milliseconds: 260),
  });

  final int currentIndex;
  final List<Widget> children;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List<Widget>.generate(children.length, (index) {
        return _AnimatedBranch(
          key: ValueKey<int>(index),
          isActive: index == currentIndex,
          duration: duration,
          child: children[index],
        );
      }),
    );
  }
}

class _AnimatedBranch extends StatefulWidget {
  const _AnimatedBranch({
    super.key,
    required this.isActive,
    required this.duration,
    required this.child,
  });

  final bool isActive;
  final Duration duration;
  final Widget child;

  @override
  State<_AnimatedBranch> createState() => _AnimatedBranchState();
}

class _AnimatedBranchState extends State<_AnimatedBranch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.isActive ? 1.0 : 0.0,
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0.0, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(covariant _AnimatedBranch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final isOffstage = !widget.isActive && _controller.isDismissed;
        return Offstage(
          offstage: isOffstage,
          child: IgnorePointer(
            ignoring: !widget.isActive,
            child: FadeTransition(
              opacity: _opacity,
              child: SlideTransition(
                position: _slide,
                child: TickerMode(
                  enabled: widget.isActive,
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
