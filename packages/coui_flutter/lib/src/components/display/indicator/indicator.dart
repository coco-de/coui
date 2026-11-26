import 'package:coui_flutter/coui_flutter.dart';

/// Wraps [child] and overlays [item] on a corner / edge of the bounding box.
///
/// Useful for status dots on avatars, count badges on icons, "NEW" labels on
/// cards, etc.
///
/// ```dart
/// Indicator(
///   item: const Badge(
///     tone: CoreBadgeTone.destructive,
///     variant: CoreBadgeVariant.filled,
///     form: CoreBadgeForm.count,
///     size: CoreComponentSize.xs,
///     child: Text('99+'),
///   ),
///   child: const Avatar(initials: 'DW'),
/// );
///
/// Indicator(
///   horizontalPosition: CoreIndicatorHorizontalPosition.start,
///   verticalPosition: CoreIndicatorVerticalPosition.bottom,
///   indicatorStyle: const CoreIndicatorStyle(offset: 4),
///   item: const Status(),
///   child: const Icon(LucideIcons.bell),
/// );
/// ```
class Indicator extends StatelessWidget
    implements CoreIndicatorContract<Widget> {
  /// Creates a [Indicator].
  const Indicator({
    required this.item,
    required this.child,
    super.key,
    this.horizontalPosition = CoreIndicatorHorizontalPosition.end,
    this.verticalPosition = CoreIndicatorVerticalPosition.top,
    this.indicatorStyle,
  });

  @override
  final Widget child;

  @override
  final Widget item;

  @override
  final CoreIndicatorHorizontalPosition horizontalPosition;

  @override
  final CoreIndicatorVerticalPosition verticalPosition;

  @override
  final CoreIndicatorStyle? indicatorStyle;

  /// Returns a copy of this [Indicator] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Indicator copyWith({
    Key? key,
    Widget? item,
    CoreIndicatorHorizontalPosition? horizontalPosition,
    CoreIndicatorVerticalPosition? verticalPosition,
    CoreIndicatorStyle? indicatorStyle,
    Widget? child,
  }) {
    return Indicator(
      key: key ?? this.key,
      item: item ?? this.item,
      horizontalPosition: horizontalPosition ?? this.horizontalPosition,
      verticalPosition: verticalPosition ?? this.verticalPosition,
      indicatorStyle: indicatorStyle ?? this.indicatorStyle,
      child: child ?? this.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveIndicator(
      context,
      indicatorStyle: indicatorStyle,
    );
    // The item's own corner meets the child's corner; the ring overhangs the
    // item by its width, so the anchor moves out by the ring on each edge.
    final ring = resolved.ringWidth;
    final anchor = resolved.offset - ring;

    final horizontalAlign = switch (horizontalPosition) {
      .start => -1.0,
      .center => 0.0,
      .end => 1.0,
    };
    final verticalAlign = switch (verticalPosition) {
      .top => -1.0,
      .middle => 0.0,
      .bottom => 1.0,
    };
    final isCentered =
        horizontalPosition == .center || verticalPosition == .middle;

    final ringed = ring > 0
        ? DecoratedBox(
            decoration: ShapeDecoration(
              color: resolved.ringColor,
              shape: RoundedRectangleBorder(
                borderRadius: resolved.ringBorderRadius,
              ),
            ),
            child: Padding(padding: EdgeInsets.all(ring), child: item),
          )
        : item;

    return Stacks(
      clipBehavior: .none,
      children: [
        child,
        Position(
          top: verticalPosition == .top ? anchor : null,
          right: horizontalPosition == .end ? anchor : null,
          bottom: verticalPosition == .bottom ? anchor : null,
          left: horizontalPosition == .start ? anchor : null,
          child: isCentered
              ? Align(
                  alignment: Alignment(horizontalAlign, verticalAlign),
                  child: ringed,
                )
              : ringed,
        ),
      ],
    );
  }
}

/// Chain sugar for merging a [CoreIndicatorStyle] patch into
/// [Indicator.indicatorStyle] (later `.withStyle(...)` calls win).
extension IndicatorStyleChain on Indicator {
  /// Returns a copy of this [Indicator] with [patch] merged into
  /// [indicatorStyle] (patch fields win on conflict).
  Indicator withStyle(CoreIndicatorStyle patch) => copyWith(
    indicatorStyle: (indicatorStyle ?? const CoreIndicatorStyle()).merge(patch),
  );
}
