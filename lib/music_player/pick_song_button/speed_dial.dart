import 'package:flutter/material.dart';
import 'animated_children.dart';
import 'animated_fab.dart';

abstract class SpeedDialChild {
  const SpeedDialChild();

  Widget assemble(BuildContext context, Animation<double> animation);
}

class SpeedDial extends StatefulWidget {
  final Widget? child, expandedChild;
  final List<SpeedDialChild> children;
  final Color? backgroundColor,
      expandedBackgroundColor,
      foregroundColor,
      expandedForegroundColor,
      overlayColor;
  final Duration animationDuration;

  /// onPressed for SpeedDial will be called after completely closing the SpeedDial.
  /// Enabling it will prevent SpeedDial from showing between navigation transitions
  /// or when SnackBar is being shown.
  final bool invokeAfterClosing;

  const SpeedDial({
    Key? key,
    this.child,
    this.expandedChild,
    this.backgroundColor,
    this.expandedBackgroundColor,
    this.foregroundColor,
    this.expandedForegroundColor,
    this.overlayColor,
    this.children = const [],
    this.invokeAfterClosing = false,
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

    final overlayBackgroundColorTween =
        ColorTween(end: widget.overlayColor ?? Colors.black.withOpacity(0.5));
    final animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);

    double? left, right;
    if (Directionality.of(context) == TextDirection.ltr) {
      right = MediaQuery.of(context).size.width - position.dx - box.size.width;
    } else {
      left = position.dx;
    }
    print("$left $right");

    return OverlayEntry(
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            GestureDetector(
              onTap: _close,
              child: AnimatedBuilder(
                animation: animation,
                builder: (_, __) => Container(
                  color: overlayBackgroundColorTween.lerp(animation.value),
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
                onClosePressed: _close,
                child: widget.child,
              ),
            ),
            Positioned(
              top: 0,
              bottom: MediaQuery.of(context).size.height - position.dy + 4,
              left: left,
              right: right,
              child: AnimatedChildren(
                animation: _controller,
                children: widget.children,
                invokeAfterClosing: widget.invokeAfterClosing,
                close: _close,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
