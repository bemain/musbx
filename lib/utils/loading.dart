import 'package:flutter/material.dart';

/// A [GradientTransform] that slides a gradient horizontally.
class _SlidingGradientTransform extends GradientTransform {
  /// Creates a [_SlidingGradientTransform].
  const _SlidingGradientTransform({required this.slidePercent});

  /// The percentage of the bounds' width to slide the gradient.
  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// A widget that provides a shimmer effect to its descendants.
///
/// The shimmer is an animated gradient that can be used to indicate a loading
/// state. Descendant widgets can use [Shimmer.of] to access the [ShimmerState]
/// and apply the effect.
///
/// This widget is often used at the root of a screen or a large component
/// that contains shimmering placeholders.
class Shimmer extends StatefulWidget {
  /// Finds the [ShimmerState] from the closest [Shimmer] ancestor.
  static ShimmerState? of(BuildContext context) {
    return context.findAncestorStateOfType<ShimmerState>();
  }

  /// Creates a [Shimmer] widget.
  const Shimmer({super.key, required this.gradient, this.child});

  /// The gradient to use for the shimmer effect.
  final LinearGradient gradient;

  /// The widget below this widget in the tree.
  final Widget? child;

  @override
  ShimmerState createState() => ShimmerState();
}

/// The state for a [Shimmer] widget.
///
/// Manages the animation controller for the shimmer effect.
class ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  /// A [Listenable] that notifies when the shimmer animation changes.
  Listenable get shimmerChanges => _shimmerController;

  /// The animated gradient for the shimmer effect.
  LinearGradient get gradient => LinearGradient(
        colors: widget.gradient.colors,
        stops: widget.gradient.stops,
        begin: widget.gradient.begin,
        end: widget.gradient.end,
        transform: _SlidingGradientTransform(
          slidePercent: _shimmerController.value,
        ),
      );

  /// Whether the [Shimmer] widget has been laid out and has a size.
  bool get isSized =>
      (context.findRenderObject() as RenderBox?)?.hasSize ?? false;

  /// The size of the [Shimmer] widget's render box.
  Size get size => (context.findRenderObject() as RenderBox).size;

  /// Calculates the offset of a descendant [RenderBox] within this [Shimmer]
  /// widget's coordinate system.
  Offset getDescendantOffset({
    required RenderBox descendant,
    Offset offset = Offset.zero,
  }) {
    final shimmerBox = context.findRenderObject() as RenderBox;
    return descendant.localToGlobal(offset, ancestor: shimmerBox);
  }

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1000));
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ?? const SizedBox();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }
}

/// A widget that applies a shimmer effect from an ancestor [Shimmer] widget.
///
/// When [isLoading] is true, this widget will apply a [ShaderMask] to its
/// [child] to create the shimmer effect. It must be a descendant of a
/// [Shimmer] widget.
class ShimmerLoading extends StatefulWidget {
  /// Creates a [ShimmerLoading] widget.
  const ShimmerLoading({
    super.key,
    this.isLoading = true,
    required this.child,
  });

  /// Whether the shimmer effect is active.
  ///
  /// If true, the child will have the shimmer effect applied.
  /// If false, the child will be displayed as is.
  final bool isLoading;

  /// The widget to which the shimmer effect will be applied.
  final Widget child;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> {
  Listenable? _shimmerChanges;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shimmerChanges != null) {
      _shimmerChanges!.removeListener(_onShimmerChange);
    }
    _shimmerChanges = Shimmer.of(context)?.shimmerChanges;
    if (_shimmerChanges != null) {
      _shimmerChanges!.addListener(_onShimmerChange);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    // Collect ancestor shimmer information.
    final shimmer = Shimmer.of(context)!;
    if (!shimmer.isSized) {
      // The ancestor Shimmer widget isn't laid
      // out yet. Return an empty box.
      return const SizedBox();
    }
    final shimmerSize = shimmer.size;
    final gradient = shimmer.gradient;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox();
    final offsetWithinShimmer = shimmer.getDescendantOffset(
      descendant: renderBox,
    );

    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return gradient.createShader(
          Rect.fromLTWH(
            -offsetWithinShimmer.dx,
            -offsetWithinShimmer.dy,
            shimmerSize.width,
            shimmerSize.height,
          ),
        );
      },
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _shimmerChanges?.removeListener(_onShimmerChange);
    super.dispose();
  }

  void _onShimmerChange() {
    if (widget.isLoading) {
      setState(() {
        // Update the shimmer painting.
      });
    }
  }
}

/// A widget that displays a placeholder for text with a shimmer effect.
///
/// This is useful for indicating that text content is loading.
/// It creates a box with the approximate height of the text and applies
/// a [ShimmerLoading] effect to it.
class TextPlaceholder extends StatelessWidget {
  /// Creates a [TextPlaceholder] widget.
  const TextPlaceholder({
    super.key,
    this.style,
    this.fontSize,
    this.width = double.infinity,
  });

  /// The [TextStyle] to use for calculating the placeholder's height.
  ///
  /// This is merged with the default text style.
  final TextStyle? style;

  /// The font size to use for calculating the placeholder's height.
  ///
  /// Overrides the font size in [style] if not `null`.
  final double? fontSize;

  /// The width of the placeholder.
  ///
  /// Defaults to [double.infinity].
  final double width;

  @override
  Widget build(BuildContext context) {
    // Determine text height
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: "Placeholder",
        style: DefaultTextStyle.of(context).style.merge(style).copyWith(
              fontSize: fontSize,
            ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    return ShimmerLoading(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Card(
          margin: EdgeInsets.symmetric(vertical: 4),
          color: Theme.of(context).colorScheme.surfaceContainer,
          elevation: 0,
          child: SizedBox(
            height: textPainter.height -
                8, // Compensate for the margin around the card
            width: width,
          ),
        ),
      ),
    );
  }
}

/// A widget that displays a placeholder for an icon with a shimmer effect.
///
/// This is useful for indicating that icon content is loading.
/// It creates a square box with the approximate size of an icon and applies
/// a [ShimmerLoading] effect to it.
class IconPlaceholder extends StatelessWidget {
  /// Creates an [IconPlaceholder] widget.
  const IconPlaceholder({
    super.key,
    this.size,
  });

  /// The size of the icon.
  ///
  /// Defaults to the current [IconThemeData.size].
  final double? size;

  @override
  Widget build(BuildContext context) {
    final double iconSize = size ?? IconTheme.of(context).size ?? 24.0;

    return ShimmerLoading(
      child: Card(
        margin: EdgeInsets.zero,
        color: Theme.of(context).colorScheme.surfaceContainer,
        elevation: 0,
        child: SizedBox(
          height: iconSize,
          width: iconSize,
        ),
      ),
    );
  }
}
