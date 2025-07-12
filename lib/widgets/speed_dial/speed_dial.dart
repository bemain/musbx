import 'package:flutter/material.dart';
import 'animated_children.dart';

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
    this.heroTag,
    this.expandedChild,
    this.expandedLabel,
    this.shouldExpand,
    this.onExpandedPressed,
    this.backgroundColor,
    this.expandedBackgroundColor,
    this.foregroundColor,
    this.expandedForegroundColor,
    this.overlayColor,
    this.animationDuration = const Duration(milliseconds: 200),
    required this.children,
    required this.child,
  })  : extendDuration = Duration.zero,
        label = null;

  const SpeedDial.extended({
    super.key,
    this.heroTag,
    this.expandedChild,
    this.expandedLabel,
    this.shouldExpand,
    this.onExpandedPressed,
    this.backgroundColor,
    this.expandedBackgroundColor,
    this.foregroundColor,
    this.expandedForegroundColor,
    this.overlayColor,
    this.extendDuration = const Duration(milliseconds: 50),
    this.animationDuration = const Duration(milliseconds: 200),
    required this.children,
    required Widget label,
    required this.child,
  }) : label = label as Widget?;

  /// The tag to apply to the button's [Hero] widget.
  ///
  /// Copied from [FloatingActionButton].
  final Object? heroTag;

  final Widget? label;

  final Duration extendDuration;

  /// Child of the primary [FloatingActionButton].
  final Widget child;

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

  /// Called whenever the user presses the button in the contracted state.
  /// Return `true` if the button is allowed to expand, `false` otherwise.
  final bool Function()? shouldExpand;

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

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.animationDuration);
  late final CurvedAnimation animation =
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);

  @override
  void dispose() {
    _controller.dispose();
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Opacity(
        opacity: 1 - animation.value,
        child: _buildFAB(key: _key),
      ),
    );
  }

  Widget _buildFAB({Key? key}) {
    final backgroundColorTween = ColorTween(
      begin: widget.backgroundColor ??
          Theme.of(context).colorScheme.primaryContainer,
      end: widget.expandedBackgroundColor ??
          widget.backgroundColor ??
          Theme.of(context).colorScheme.primary,
    );
    final foregroundColorTween = ColorTween(
      begin: widget.foregroundColor ??
          Theme.of(context).colorScheme.onPrimaryContainer,
      end: widget.expandedForegroundColor ??
          widget.foregroundColor ??
          Theme.of(context).colorScheme.onPrimary,
    );
    final angleTween = Tween<double>(begin: 0, end: 1);

    void onPressed() {
      if (isOpen) {
        _close();
        widget.onExpandedPressed?.call();
      } else if (widget.shouldExpand?.call() ?? true) {
        _open();
      }
    }

    final Widget icon = Stack(
      children: [
        Transform.rotate(
            angle: angleTween.animate(animation).value,
            child: Opacity(opacity: 1 - animation.value, child: widget.child)),
        Transform.rotate(
          angle: angleTween.animate(animation).value - 1,
          child: Opacity(
            opacity: animation.value,
            child: widget.expandedChild,
          ),
        ),
      ],
    );

    if (widget.label != null) {
      return AnimatedSize(
        clipBehavior: Clip.none,
        duration: widget.extendDuration,
        child: FloatingActionButton.extended(
          isExtended: !isOpen,
          key: key,
          heroTag: widget.heroTag,
          onPressed: onPressed,
          backgroundColor: backgroundColorTween.lerp(animation.value),
          foregroundColor: foregroundColorTween.lerp(animation.value),
          extendedPadding: !isOpen ? null : const EdgeInsets.all(16),
          label: widget.label!,
          icon: icon,
        ),
      );
    }

    return FloatingActionButton(
      key: key,
      heroTag: widget.heroTag,
      onPressed: onPressed,
      backgroundColor: backgroundColorTween.lerp(animation.value),
      foregroundColor: foregroundColorTween.lerp(animation.value),
      child: icon,
    );
  }

  bool get isOpen => _isOpen;

  dynamic toggle() => _isOpen ? _close() : _open();

  Future<void> _open() async {
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
    final Offset position = box.localToGlobal(Offset.zero);

    final double vertical =
        MediaQuery.sizeOf(context).height - position.dy - box.size.height;
    final double horizontal =
        MediaQuery.sizeOf(context).width - position.dx - box.size.width;

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
                        Theme.of(context).colorScheme.surface.withAlpha(0xf2),
                  ).lerp(animation.value),
                ),
              ),
            ),
            Positioned(
              bottom: vertical,
              right: horizontal,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, _) => Opacity(
                  opacity: animation.value,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.expandedLabel != null)
                        DefaultTextStyle(
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                overflow: TextOverflow.ellipsis,
                              ),
                          child: Opacity(
                            opacity: animation.value,
                            child: Center(child: widget.expandedLabel!),
                          ),
                        ),
                      const SizedBox(width: 16),
                      _buildFAB(),
                    ],
                  ),
                ),
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
