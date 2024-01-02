import 'package:flutter/material.dart';
import 'animated_children.dart';
import 'animated_fab.dart';

abstract class SpeedDialChild {
  /// A child of [SpeedDial].
  const SpeedDialChild();

  /// Should return a widget that animates in and out according to [animation].
  Widget assemble(BuildContext context, Animation<double> animation);
}

class SpeedDial extends StatefulWidget {
  /// An expandable [FloatingActionButton] that shows [children] when pressed.
  const SpeedDial({
    super.key,
    this.child,
    this.expandedChild,
    this.expandedLabel,
    this.onExpandedPressed,
    this.backgroundColor,
    this.expandedBackgroundColor,
    this.foregroundColor,
    this.expandedForegroundColor,
    this.overlayColor,
    required this.children,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  /// Child of the primary [FloatingActionButton].
  final Widget? child;

  /// Child of the primary [FloatingActionButton] when expanded.
  final Widget? expandedChild;

  /// Label displayed next to the primary [FloatingActionButton] when expanded.
  final Widget? expandedLabel;

  /// The widgets displayed when in an expanded state.
  final List<SpeedDialChild> children;

  /// Background color of the primary [FloatingActionButton].
  final Color? backgroundColor;

  /// Background color of the primary [FloatingActionButton] when expanded.
  final Color? expandedBackgroundColor;

  /// Foreground color of the primary [FloatingActionButton].
  final Color? foregroundColor;

  /// Foreground color of the primary [FloatingActionButton] when expanded.
  final Color? expandedForegroundColor;

  /// Color of the overlay that is placed behind the [children] when in an
  /// expanded state, to avoid interference with the content of the rest of the app.
  final Color? overlayColor;

  /// The duration of the opening and closing animation.
  final Duration animationDuration;

  /// Callback for when the primary [FloatingActionButton] is pressed in an expanded state.
  final VoidCallback? onExpandedPressed;

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
