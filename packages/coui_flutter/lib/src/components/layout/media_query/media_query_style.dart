import 'package:coui_flutter/coui_flutter.dart';

/// Resolved visibility range for [MediaQueryVisibility].
///
/// Pixel bounds combine the explicit `minWidth`/`maxWidth` override with the
/// breakpoint bounds. When both sides provide the same end, explicit pixels
/// win so consumers can fine-tune beyond the breakpoint system.
class ResolvedMediaQueryVisibility {
  /// Creates a [ResolvedMediaQueryVisibility].
  const ResolvedMediaQueryVisibility({
    required this.minWidth,
    required this.maxWidth,
  });

  /// Minimum viewport width (px), inclusive.
  final double? minWidth;

  /// Maximum viewport width (px), inclusive.
  final double? maxWidth;
}

/// Resolves the visibility range for [MediaQueryVisibility].
///
/// Priority: widget pixel > widget breakpoint > theme pixel > theme
/// breakpoint.
ResolvedMediaQueryVisibility resolveMediaQueryVisibility(
  BuildContext context, {
  double? minWidth,
  double? maxWidth,
  CoreBreakpoint? minBreakpoint,
  CoreBreakpoint? maxBreakpoint,
}) {
  final coreTheme = Theme.of(context).coreComponentTheme?.mediaQueryVisibility;

  final effectiveMin =
      minWidth ??
      minBreakpoint?.minWidth ??
      coreTheme?.style?.minWidth ??
      coreTheme?.style?.minBreakpoint?.minWidth;

  final effectiveMax =
      maxWidth ??
      maxBreakpoint?.minWidth ??
      coreTheme?.style?.maxWidth ??
      coreTheme?.style?.maxBreakpoint?.minWidth;

  return ResolvedMediaQueryVisibility(
    minWidth: effectiveMin,
    maxWidth: effectiveMax,
  );
}
