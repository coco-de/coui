import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved style (already-merged values)
// ═══════════════════════════════════════════════════

/// Resolver output for `CodeDiff`.
///
/// Single struct that the widget reads — the nested-merge chain
/// (theme.style → widget.codeDiffStyle) plus legacy theme color /
/// dimensional fallback applied once here. Every field already has
/// the design-system default applied so `Co{CodeDiff}.build` reads
/// the struct directly without further fallback chains.
class ResolvedCodeDiff {
  /// Creates a [ResolvedCodeDiff].
  const ResolvedCodeDiff({
    required this.containerStyle,
    required this.lineNumberWidth,
    required this.addedBackgroundColor,
    required this.addedForegroundColor,
    required this.removedBackgroundColor,
    required this.removedForegroundColor,
    required this.unchangedTextColor,
    required this.lineNumberColor,
    required this.prefixFontWeight,
    required this.linePadding,
    required this.lineNumberPadding,
    required this.bodyTextStyle,
    required this.gutterTextStyle,
  });

  /// [CoreOutlinedContainerStyle] for the composed `OutlinedContainer`
  /// surface — `OutlinedContainer`'s contract input. Background /
  /// border / radius are merged from this component's own style and
  /// left as `coui_core` domain types so the receiving widget runs its
  /// own colour / radius resolution once — plus the surface-material
  /// wiring (glass blur / role fill) and the "no shadow of its own →
  /// take the active style's injected control-shadow" fallback a
  /// hand-drawn box never got (`core/style-contract.md` — 합성 =
  /// 재구현 금지).
  final CoreOutlinedContainerStyle containerStyle;

  /// Effective line-number column width (logical px, already scaled).
  final double lineNumberWidth;

  /// Resolved band face of an added row (final, theme-resolved, opaque).
  final Color addedBackgroundColor;

  /// Resolved ink of an added row's `+ ` prefix and gutter number — drawn on
  /// [addedBackgroundColor].
  final Color addedForegroundColor;

  /// Resolved band face of a removed row (final, theme-resolved, opaque).
  final Color removedBackgroundColor;

  /// Resolved ink of a removed row's `- ` prefix and gutter number — drawn on
  /// [removedBackgroundColor].
  final Color removedForegroundColor;

  /// Resolved body ink: the diff text of every row, and an unchanged row's
  /// blank prefix.
  final Color unchangedTextColor;

  /// Resolved gutter number colour on a plain (unchanged) row — opaque. A
  /// band row's number is [addedForegroundColor] / [removedForegroundColor].
  final Color lineNumberColor;

  /// Resolved font weight for the `+ ` / `- ` / `  ` prefix span.
  final FontWeight prefixFontWeight;

  /// Resolved per-row padding (already scaled).
  final EdgeInsets linePadding;

  /// Resolved line-number gutter padding (already scaled). Geometry, not
  /// `EdgeInsets`: the default is directional (the gap sits on the end
  /// side) and only resolves to a physical side against the ambient text
  /// direction.
  final EdgeInsetsGeometry lineNumberPadding;

  /// Effective body text style (theme typography + per-instance
  /// CoreTextStyle override merged).
  final TextStyle bodyTextStyle;

  /// Effective gutter text style (theme typography + per-instance
  /// CoreTextStyle override merged).
  final TextStyle gutterTextStyle;
}

// ═══════════════════════════════════════════════════
// Resolver
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedCodeDiff] for the given [context].
///
/// ```text
/// CoreCodeDiffStyle.defaultX → CoreCodeDiffTheme.style → widget.codeDiffStyle
/// ```
ResolvedCodeDiff resolveCodeDiff(
  BuildContext context, {
  CoreCodeDiffStyle? codeDiffStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final coreTheme = theme.coreComponentTheme?.codeDiff;

  // Layer the per-instance CoreCodeDiffStyle:
  //   theme.style → widget.codeDiffStyle.
  final merged = resolveStyleChain(const CoreCodeDiffStyle(), [
    coreTheme?.style,
    codeDiffStyle,
  ]);

  // Every chrome / dimensional / colour / typography value reads
  // `merged.X ?? CoreCodeDiffStyle.defaultX` (1:1:1:1 chaining contract,
  // mirrors the Web resolver). Padding / width scale by the theme
  // scaling factor.
  final lineNumberWidth =
      (merged.lineNumberWidth ?? CoreCodeDiffStyle.defaultLineNumberWidth) *
      scaling;

  final addedBackgroundColor = scheme
      .resolve(
        merged.addedBackgroundColor ??
            CoreCodeDiffStyle.defaultAddedBackgroundColor,
      )
      .toValue();
  final addedForegroundColor = scheme
      .resolve(
        merged.addedForegroundColor ??
            CoreCodeDiffStyle.defaultAddedForegroundColor,
      )
      .toValue();
  final removedBackgroundColor = scheme
      .resolve(
        merged.removedBackgroundColor ??
            CoreCodeDiffStyle.defaultRemovedBackgroundColor,
      )
      .toValue();
  final removedForegroundColor = scheme
      .resolve(
        merged.removedForegroundColor ??
            CoreCodeDiffStyle.defaultRemovedForegroundColor,
      )
      .toValue();
  // sb8 — the body ink lives inside the nested `unchangedTextStyle.color`
  // slot, and every row's diff text reads it.
  final unchangedTextColor = scheme
      .resolve(
        merged.unchangedTextStyle?.color ??
            CoreCodeDiffStyle.defaultUnchangedTextStyle.color!,
      )
      .toValue();
  final lineNumberColor = scheme
      .resolve(
        merged.lineNumberColor ?? CoreCodeDiffStyle.defaultLineNumberColor,
      )
      .toValue();

  // Outer chrome composes the shared `OutlinedContainer` surface
  // primitive rather than a hand-drawn box, so background / border /
  // radius stay `coui_core` domain types and that primitive's own
  // resolver runs colour and radius resolution plus the surface
  // material wiring and the active style's injected control shadow
  // fallback exactly once.
  final containerStyle = CoreOutlinedContainerStyle(
    backgroundColor:
        merged.surfaceColor ?? CoreCodeDiffStyle.defaultSurfaceColor,
    borderColor: merged.outlineColor ?? CoreCodeDiffStyle.defaultOutlineColor,
    borderRadius: merged.cornerRadius ?? CoreCodeDiffStyle.defaultCornerRadius,
    borderWidth: merged.borderWidth ?? CoreCodeDiffStyle.defaultBorderWidth,
  );

  final linePadding =
      ((merged.linePadding ?? CoreCodeDiffStyle.defaultLinePadding).toValue(
        geometry: theme.geometry,
      )) *
      scaling;
  // `toGeometry`, not `toValue`: the default gap is a directional inset
  // (it sits on the side the code runs toward), which `toValue` refuses
  // rather than flatten into a physical side.
  final lineNumberPadding =
      ((merged.lineNumberPadding ?? CoreCodeDiffStyle.defaultLineNumberPadding)
          .toGeometry(geometry: theme.geometry)) *
      scaling;

  // Typography (paint-ready TextStyle). Single primitive — merge the
  // token role default with the per-instance `CoreTextStyle` overlay,
  // then `.toValue(theme:)` materialises the role and resolves any
  // colour through the active scheme in one step (no hand-rolled
  // `typography.resolve` / `scheme.resolve` assembly). The widget
  // overrides the foreground colour per row at paint time, so the base
  // colour here only applies when the overlay sets one explicitly.
  final bodyCore =
      (merged.bodyTypography ?? CoreCodeDiffStyle.defaultBodyTypography).merge(
        merged.bodyTextStyle,
      );
  final gutterCore =
      (merged.gutterTypography ?? CoreCodeDiffStyle.defaultGutterTypography)
          .merge(merged.gutterTextStyle);
  final bodyTextStyle = bodyCore.toValue(theme: theme);
  final gutterTextStyle = gutterCore.toValue(theme: theme);

  final prefixFontWeight = fontWeightFromInt(
    merged.prefixFontWeight ?? CoreCodeDiffStyle.defaultPrefixFontWeight,
  )!;

  return ResolvedCodeDiff(
    containerStyle: containerStyle,
    lineNumberWidth: lineNumberWidth,
    addedBackgroundColor: addedBackgroundColor,
    addedForegroundColor: addedForegroundColor,
    removedBackgroundColor: removedBackgroundColor,
    removedForegroundColor: removedForegroundColor,
    unchangedTextColor: unchangedTextColor,
    lineNumberColor: lineNumberColor,
    prefixFontWeight: prefixFontWeight,
    linePadding: linePadding,
    lineNumberPadding: lineNumberPadding,
    bodyTextStyle: bodyTextStyle,
    gutterTextStyle: gutterTextStyle,
  );
}
