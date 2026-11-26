import 'dart:math';

import 'package:coui_flutter/coui_flutter.dart';

/// Flutter typedef for the cross-platform stage container builder.
typedef StageContainerBuilder = CoreStageContainerBuilder<Widget>;

/// Responsive container that clamps its child onto one of the breakpoint
/// rungs and redistributes any extra viewport width as symmetric horizontal
/// padding.
///
/// Implements [CoreStageContainerContract] so callers can share the
/// same call site with the Web counterpart. Mirrors the legacy
/// `StageContainer`'s layout math verbatim so migrated call sites render
/// identically.
class StageContainer extends StatelessWidget
    implements CoreStageContainerContract<Widget> {
  /// Creates a [StageContainer].
  const StageContainer({
    required this.builder,
    super.key,
    CoreStageBreakpoint? breakpoint,
    CoreEdgeInsets? padding,
    this.stageContainerStyle,
  }) : _widgetBreakpoint = breakpoint,
       _widgetPadding = padding;

  @override
  final StageContainerBuilder builder;

  final CoreStageBreakpoint? _widgetBreakpoint;
  final CoreEdgeInsets? _widgetPadding;

  @override
  final CoreStageContainerStyle? stageContainerStyle;

  @override
  CoreStageBreakpoint get breakpoint =>
      _widgetBreakpoint ?? CoreStageBreakpoint.defaultBreakpoints;

  @override
  CoreEdgeInsets get padding =>
      _widgetPadding ?? CoreStageContainerStyle.defaultPadding;

  /// Returns a copy of this [StageContainer] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  StageContainer copyWith({
    Key? key,
    CoreStageBreakpoint? breakpoint,
    CoreEdgeInsets? padding,
    CoreStageContainerStyle? stageContainerStyle,
    StageContainerBuilder? builder,
  }) {
    return StageContainer(
      key: key ?? this.key,
      breakpoint: breakpoint ?? _widgetBreakpoint,
      padding: padding ?? _widgetPadding,
      stageContainerStyle: stageContainerStyle ?? this.stageContainerStyle,
      builder: builder ?? this.builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveStageContainer(
      context,
      breakpoint: _widgetBreakpoint,
      padding: _widgetPadding,
      stageContainerStyle: stageContainerStyle,
    );
    final resolvedBreakpoint = resolved.breakpoint;
    final basePadding = resolved.padding;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final topPadding = basePadding.top;
        final bottomPadding = basePadding.bottom;
        double leftPadding = basePadding.left;
        double rightPadding = basePadding.right;

        if (size < resolvedBreakpoint.minSize) {
          return builder(
            context,
            CoreEdgeInsets.only(
              top: topPadding,
              bottom: bottomPadding,
            ),
          );
        }

        if (size > resolvedBreakpoint.maxSize) {
          final remainingWidth = (size - resolvedBreakpoint.maxSize) / 2;
          leftPadding = max(0, leftPadding + remainingWidth);
          rightPadding = max(0, rightPadding + remainingWidth);
          return builder(
            context,
            CoreEdgeInsets.only(
              left: leftPadding,
              top: topPadding,
              right: rightPadding,
              bottom: bottomPadding,
            ),
          );
        }

        final minWidth = resolvedBreakpoint.getMinWidth(size);
        final maxWidth = resolvedBreakpoint.getMaxWidth(size);
        assert(
          minWidth <= maxWidth,
          'minWidth must be <= maxWidth ($minWidth > $maxWidth)',
        );
        final remainingWidth = (size - minWidth) / 2;
        leftPadding = max(0, leftPadding + remainingWidth);
        rightPadding = max(0, rightPadding + remainingWidth);

        return builder(
          context,
          CoreEdgeInsets.only(
            left: leftPadding,
            top: topPadding,
            right: rightPadding,
            bottom: bottomPadding,
          ),
        );
      },
    );
  }
}

/// Chain sugar for merging a [CoreStageContainerStyle] patch into
/// [StageContainer.stageContainerStyle] without hand-reconstructing every
/// field. Mirrors the Web `StageContainer.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreStageContainerStyle.merge` right-side-wins semantics).
extension StageContainerStyleChain on StageContainer {
  /// Returns a copy of this [StageContainer] with [patch] merged into
  /// [stageContainerStyle] (patch fields win on conflict).
  StageContainer withStyle(CoreStageContainerStyle patch) => copyWith(
    stageContainerStyle:
        (stageContainerStyle ?? const CoreStageContainerStyle()).merge(patch),
  );
}
