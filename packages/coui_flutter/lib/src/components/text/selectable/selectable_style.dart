import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedSelectableText
// ═══════════════════════════════════════════════════

/// Resolver output for `SelectableText`.
///
/// Single struct that the widget reads — every cursor / text-style
/// override has been merged through:
///
/// ```text
/// design system default (CoreSelectableTextStyle.defaultX)
///   → theme.coreComponentTheme.selectableText.style
///   → widget.selectableTextStyle
/// ```
class ResolvedSelectableText {
  /// Creates a [ResolvedSelectableText].
  const ResolvedSelectableText({
    required this.cursorWidth,
    required this.selectionColor,
    this.textStyle,
    this.cursorColor,
    this.cursorHeight,
    this.cursorRadius,
  });

  /// Effective text-caret width (logical px).
  final double cursorWidth;

  /// Effective text-selection highlight tint. Applied to an ancestor
  /// `DefaultSelectionStyle` so the selection colour comes from the CoUI
  /// scheme (`primaryContainer`) rather than the ambient Material
  /// `DefaultSelectionStyle` — which `m.SelectableText` would otherwise
  /// inherit (CoUI/Material clash).
  final Color selectionColor;

  /// Effective text style applied to the content. `null` → inherit.
  final TextStyle? textStyle;

  /// Effective caret colour, resolved from the Core default or override.
  final Color? cursorColor;

  /// Effective caret height (logical px). `null` → auto.
  final double? cursorHeight;

  /// Effective caret corner radius. `null` → none.
  final Radius? cursorRadius;
}

// ═══════════════════════════════════════════════════
// Resolver
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedSelectableText] for the given [context].
///
/// Priority (per-field):
/// `widget.selectableTextStyle` > `CoreSelectableTextTheme.style` >
/// `CoreSelectableTextStyle.defaultX` design-system defaults.
ResolvedSelectableText resolveSelectableText(
  BuildContext context, {
  CoreSelectableTextStyle? selectableTextStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final selectableTheme = theme.coreComponentTheme?.selectableText;

  final merged = resolveStyleChain(const CoreSelectableTextStyle(), [
    selectableTheme?.style,
    selectableTextStyle,
  ]);

  final cursorWidth =
      (merged.cursorWidth ?? CoreSelectableTextStyle.defaultCursorWidth) *
      scaling;

  final cursorHeight = merged.cursorHeight == null
      ? null
      : merged.cursorHeight! * scaling;

  final cursorColor = scheme
      .resolve(merged.cursorColor ?? CoreSelectableTextStyle.defaultCursorColor)
      .toValue();

  // Selection tint — resolved here so the widget reads it straight (no
  // widget-side `colorScheme`). Routes through the Core named default
  // (single source) and is painted as stated: the highlight sits behind the
  // text, so an opaque container tone reads without any alpha of its own.
  final selectionColor = scheme
      .resolve(
        merged.selectionColor ?? CoreSelectableTextStyle.defaultSelectionColor,
      )
      .toValue();

  final cursorRadiusCore = merged.cursorRadius;
  final cursorRadius = cursorRadiusCore == null
      ? null
      : Radius.circular(
          cursorRadiusCore.toValue(geometry: theme.geometry).topLeft.x *
              scaling,
        );

  // EMIT Stage 2 (Flutter) — the nested `CoreTextStyle` slot has no
  // design-system default (selectable text inherits the surrounding
  // typography), so the merged overlay is materialised through the single
  // `toValue(theme:)` primitive. The token-less overlay resolves its own
  // colour through the active scheme (dark-mode aware) and converts
  // `letterSpacing` (em) → logical px — no hand-rolled assembly.
  // Ambient default (`bodyMedium` + `onSurface`) from the shared Core
  // field — Flutter has no automatic ambient text style, so without the
  // default the framework's own text style leaked in (Web inherits
  // bodyMedium).
  final textStyle = CoreSelectableTextStyle.defaultTextStyle
      .merge(merged.textStyle)
      .toValue(theme: theme);

  return ResolvedSelectableText(
    cursorWidth: cursorWidth,
    selectionColor: selectionColor,
    textStyle: textStyle,
    cursorColor: cursorColor,
    cursorHeight: cursorHeight,
    cursorRadius: cursorRadius,
  );
}

// ═══════════════════════════════════════════════════
// Cross-platform enum → Flutter enum mapping
// ═══════════════════════════════════════════════════

/// Maps a [CoreTextAlign] to the Flutter [TextAlign]. `null` → `null`.
TextAlign? coSelectableTextAlign(CoreTextAlign? align) {
  return switch (align) {
    null => null,
    .start => .start,
    .end => .end,
    .center => .center,
    .justify => .justify,
    .left => .left,
    .right => .right,
  };
}

/// Maps a [CoreTextDirection] to the Flutter [TextDirection]. `null` →
/// `null`.
TextDirection? coSelectableTextDirection(CoreTextDirection? direction) {
  return switch (direction) {
    null => null,
    .ltr => .ltr,
    .rtl => .rtl,
  };
}
