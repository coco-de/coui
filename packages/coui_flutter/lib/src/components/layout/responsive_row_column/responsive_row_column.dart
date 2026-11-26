import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/components/layout/responsive_row_column/responsive_row_column_style.dart';
import 'package:flutter/widgets.dart';

/// Layout primitive that renders [children] as a `Row` (horizontal)
/// at or above `switchAt`, and as a `Column` (vertical) below it —
/// the cross-platform analogue of `responsive_framework`'s
/// `ResponsiveRowColumn`.
///
/// Mirrors the Web `ResponsiveRowColumn` — same parameter names, same
/// defaults (`switchAt: tablet`, `spacing: CoreSpace.space8`,
/// `mainAxisAlignment: start`, `crossAxisAlignment: center`), same
/// visual outcome. Direction is derived from the ambient viewport
/// breakpoint tier (the shared `resolveBreakpoint` entry point, Story
/// B) — this widget performs no measurement of its own.
class ResponsiveRowColumn extends StatelessWidget
    implements CoreResponsiveRowColumnContract<Widget> {
  /// Creates a [ResponsiveRowColumn].
  const ResponsiveRowColumn({
    required this.children,
    super.key,
    this.switchAt,
    this.responsiveRowColumnStyle,
  });

  @override
  final List<Widget> children;

  @override
  final CoreBreakpointTier? switchAt;

  @override
  final CoreResponsiveRowColumnStyle? responsiveRowColumnStyle;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveResponsiveRowColumn(
      context,
      switchAt: switchAt,
      responsiveRowColumnStyle: responsiveRowColumnStyle,
    );

    return Flex(
      direction: resolved.direction,
      mainAxisAlignment: resolved.mainAxisAlignment,
      crossAxisAlignment: resolved.crossAxisAlignment,
      spacing: resolved.spacing,
      children: children,
    );
  }
}

/// Chain sugar for merging a [CoreResponsiveRowColumnStyle] patch into
/// [ResponsiveRowColumn.responsiveRowColumnStyle] without
/// hand-reconstructing every field. Mirrors the Web
/// `ResponsiveRowColumn.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreResponsiveRowColumnStyle.merge` right-side-wins
/// semantics).
///
/// ```dart
/// ResponsiveRowColumn(children: [...]).withStyle(
///   CoreResponsiveRowColumnStyle(spacing: CoreSpace.space16),
/// )
/// ```
extension ResponsiveRowColumnStyleChain on ResponsiveRowColumn {
  /// Returns a copy of this [ResponsiveRowColumn] with [patch] merged
  /// into [responsiveRowColumnStyle] (patch fields win on conflict).
  ResponsiveRowColumn withStyle(CoreResponsiveRowColumnStyle patch) => .new(
    key: key,
    switchAt: switchAt,
    responsiveRowColumnStyle:
        (responsiveRowColumnStyle ?? const CoreResponsiveRowColumnStyle())
            .merge(patch),
    children: children,
  );
}
