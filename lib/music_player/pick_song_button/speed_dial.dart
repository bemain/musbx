import 'package:flutter/material.dart';
import 'animated_children.dart';
import 'animated_fab.dart';

abstract class SpeedDialChild {
  const SpeedDialChild();

  Widget assemble(BuildContext context, Animation<double> animation);
}

class SpeedDial extends StatefulWidget {
  final Widget? child;
  final Widget? expandedChild;
  final Widget? expandedLabel;
  final List<SpeedDialChild> children;
  final Color? backgroundColor;
  final Color? expandedBackgroundColor;
  final Color? foregroundColor;
  final Color? expandedForegroundColor;
  final Color? overlayColor;
  final Duration animationDuration;
  final VoidCallback? onExpandedPressed;

  const SpeedDial({
    Key? key,
    this.child,
    this.expandedChild,
    this.expandedLabel,
    this.onExpandedPressed,
    this.backgroundColor,
    this.expandedBackgroundColor,
    this.foregroundColor,
    this.expandedForegroundColor,
    this.overlayColor,
    this.children = const [],
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  SpeedDialState createState() => SpeedDialState();
}

class SpeedDialState extends State<SpeedDial>
    with SingleTickerProviderStateMixin {
  final _key = GlobalKey();
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.animationDuration);
  }

  @override
  void dispose() {
    _controller.dispose();
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _isOpen ? 0 : 1,
      child: FloatingActionButton(
        key: _key,
        onPressed: _open,
        foregroundColor: widget.foregroundColor,
        backgroundColor: widget.backgroundColor,
        child: widget.child,
      ),
    );
  }

  bool get isOpen => _isOpen;

  toggle() => _isOpen ? _close() : _open();

  _open() {
    if (_isOpen) {
      return;
    }
    setState(() {
      _isOpen = true;
    });
    _overlayEntry?.remove();
    _overlayEntry = _buildOverlay();
    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    _controller.animateTo(1);
  }

  Future<bool> _close() async {
    if (!_isOpen) {
      return false;
    }
    await _controller.animateTo(0).whenComplete(() {
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() {
        _isOpen = false;
      });
    });
    return true;
  }

  OverlayEntry _buildOverlay() {
    RenderBox? box = _key.currentContext?.findRenderObject() as RenderBox;
    Offset position = box.localToGlobal(Offset.zero);

    final CurvedAnimation animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);

    final double horizontal =
        MediaQuery.of(context).size.width - position.dx - box.size.width;

    return OverlayEntry(
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            GestureDetector(
              onTap: _close,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, _) => Container(
                  color: ColorTween(
                    end: widget.overlayColor ??
                        Theme.of(context).colorScheme.surface.withOpacity(0.95),
                  ).lerp(animation.value),
                ),
              ),
            ),
            if (widget.expandedLabel != null)
              Positioned(
                top: position.dy,
                height: 56.0,
                right: MediaQuery.sizeOf(context).width - position.dx + 16.0,
                child: DefaultTextStyle(
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        overflow: TextOverflow.ellipsis,
                      ),
                  child: AnimatedBuilder(
                    animation: animation,
                    builder: (context, _) => Opacity(
                      opacity: animation.value,
                      child: Center(child: widget.expandedLabel!),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: position.dy,
              left: position.dx,
              child: AnimatedFAB(
                animation: animation,
                expandedChild: widget.expandedChild,
                backgroundColor: widget.backgroundColor,
                expandedBackgroundColor: widget.expandedBackgroundColor,
                foregroundColor: widget.foregroundColor,
                expandedForegroundColor: widget.expandedForegroundColor,
                onExpandedPressed: () {
                  _close();
                  widget.onExpandedPressed?.call();
                },
                child: widget.child,
              ),
            ),
            Positioned(
              top: 0,
              bottom: MediaQuery.of(context).size.height - position.dy + 4,
              left: horizontal,
              right: horizontal,
              child: AnimatedChildren(
                animation: _controller,
                children: widget.children,
                close: _close,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
