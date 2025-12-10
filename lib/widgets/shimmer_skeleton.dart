import 'package:flutter/material.dart';

/// Lightweight shimmer utilities for skeleton placeholders.
/// No external dependencies.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child, this.baseColor, this.highlightColor, this.duration});

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration? duration;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration ?? const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color fallbackBase = (widget.baseColor ?? Colors.grey).withValues(alpha: 0.28);
    final Color fallbackHighlight = (widget.highlightColor ?? Colors.white).withValues(alpha: 0.75);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double slidePercent = _controller.value; // 0..1
        // Slide from -1 to +2 so gradient traverses fully
        final double dx = -1.0 + (slidePercent * 3.0);

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment(-1 + dx, 0),
              end: Alignment(1 + dx, 0),
              colors: <Color>[
                fallbackBase,
                fallbackHighlight,
                fallbackBase,
              ],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class ShimmerContainer extends StatelessWidget {
  const ShimmerContainer({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.margin,
    this.padding,
    this.decoration,
    this.baseColor,
    this.highlightColor,
    this.child,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BoxDecoration? decoration;
  final Color? baseColor;
  final Color? highlightColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final BoxDecoration box = (decoration ?? BoxDecoration(
      color: Colors.grey.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
    ));

    return Shimmer(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding,
        decoration: box,
        child: child,
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  const ShimmerList.horizontal({
    super.key,
    required this.itemWidth,
    required this.itemHeight,
    this.itemCount = 3,
    this.borderRadius = 16,
    this.spacing = 12,
  }) : axis = Axis.horizontal;

  const ShimmerList.vertical({
    super.key,
    required this.itemWidth,
    required this.itemHeight,
    this.itemCount = 6,
    this.borderRadius = 16,
    this.spacing = 12,
  }) : axis = Axis.vertical;

  final Axis axis;
  final double itemWidth;
  final double itemHeight;
  final int itemCount;
  final double borderRadius;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final EdgeInsetsGeometry margin = axis == Axis.horizontal
        ? EdgeInsets.only(right: spacing)
        : EdgeInsets.only(bottom: spacing);

    return ListView.builder(
      scrollDirection: axis,
      itemCount: itemCount,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemBuilder: (_, __) => ShimmerContainer(
        width: itemWidth,
        height: itemHeight,
        borderRadius: borderRadius,
        margin: margin,
      ),
    );
  }
}

class ShimmerGrid extends StatelessWidget {
  const ShimmerGrid({
    super.key,
    required this.columns,
    required this.itemCount,
    this.aspectRatio = 0.82,
    this.cardBorderRadius = 18,
    this.crossAxisSpacing = 24,
    this.mainAxisSpacing = 24,
    this.padding = EdgeInsets.zero,
  });

  final int columns;
  final int itemCount;
  final double aspectRatio;
  final double cardBorderRadius;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: aspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => _ShimmerCard(borderRadius: cardBorderRadius),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({required this.borderRadius});
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail placeholder
            Expanded(
              child: ShimmerContainer(
                borderRadius: 14,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ShimmerContainer(height: 14, borderRadius: 6),
            const SizedBox(height: 8),
            ShimmerContainer(width: 140, height: 12, borderRadius: 6),
          ],
        ),
      ),
    );
  }
}
