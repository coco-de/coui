import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedMockupCode
// ═══════════════════════════════════════════════════

/// Resolver output for `MockupCode`.
///
/// Single struct that the widget reads — every chrome / dimensional
/// override has been merged through:
///
/// ```text
/// CoreMockupCodeStyle defaults
///   → theme.coreComponentTheme.mockup legacy shared fields
///   → theme.coreComponentTheme.mockupCode.style
///   → widget.mockupCodeStyle
/// ```
///
/// The outer container is a composed `OutlinedContainer` — not a
/// hand-rolled `Container` — so background / radius / padding and the
/// "no shadow of my own → take the active style's injected
/// control-shadow at rest" fallback come from the single shared
/// primitive (`core/style-contract.md`'s child-component-composition
/// rule).
@immutable
class ResolvedMockupCode {
  /// Creates a [ResolvedMockupCode].
  const ResolvedMockupCode({
    required this.containerStyle,
    required this.textStyle,
    required this.toneTextStyles,
    required this.prefixTextStyle,
    required this.lineSpacing,
    required this.lineNumberWidth,
  });

  /// [CoreOutlinedContainerStyle] for the composed `OutlinedContainer`
  /// outer container surface — `OutlinedContainer`'s contract input.
  /// Background / radius / padding / width are merged and expressed as
  /// `coui_core` domain types so the receiving widget runs its own
  /// colour / radius resolution + scaling once.
  final CoreOutlinedContainerStyle containerStyle;

  /// Paint-ready code text style (typography role + slot override +
  /// resolved foreground colour) — the `neutral` tone's style. It is the
  /// base every entry of [toneTextStyles] is built from; the widget reads
  /// [toneTextStyles] and picks the entry by `line.tone`.
  final TextStyle textStyle;

  /// Paint-ready code text style per line tone — one entry for every
  /// [CoreCodeLineTone]. A tone changes only the colour: each entry is
  /// [textStyle]'s typography with the tone's colour resolved through the
  /// active scheme, and `neutral` is [textStyle] itself. The widget selects
  /// by `line.tone` and raw-forwards the entry into `Text(style: ...)`.
  final Map<CoreCodeLineTone, TextStyle> toneTextStyles;

  /// Paint-ready line-number prefix text style (typography role + slot
  /// override + resolved prefix colour). The widget raw-forwards this
  /// into the gutter `Text(style: ...)`.
  final TextStyle prefixTextStyle;

  /// Per-line bottom spacing (logical px, pre-scaling).
  final double lineSpacing;

  /// Width allocated for the line-number prefix (logical px, pre-scaling).
  final double lineNumberWidth;
}

// ═══════════════════════════════════════════════════
// Resolver
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedMockupCode] for the given [context].
///
/// Priority (per-field):
/// `widget.mockupCodeStyle` > `CoreMockupCodeTheme.style` >
/// `CoreMockupTheme.style` (shared cross-variant) > `CoreMockupCodeStyle`
/// default constants.
ResolvedMockupCode resolveMockupCode(
  BuildContext context, {
  CoreMockupCodeStyle? mockupCodeStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final mkStyle = theme.coreComponentTheme?.mockup?.style;
  final codeTheme = theme.coreComponentTheme?.mockupCode;

  // ─── Merge chain (Stage 1 RESOLVE) ────────────────────
  final merged = resolveStyleChain(const CoreMockupCodeStyle(), [
    codeTheme?.style,
    mockupCodeStyle,
  ]);

  // ─── Stage 1 RESOLVE — Core values (local vars) ───────
  // Scalar chrome: `merged.X ?? default` (background folds in the shared
  // cross-variant `CoreMockupTheme.style` before the design-system
  // default). Composite typography: `default.merge(merged.X)` so a
  // caller that overrides only colour / font keeps the rest of the
  // `codeSm` role (12 / regular / fixed 21px line box / monospace) + its
  // colour token.
  final backgroundCore =
      merged.backgroundColor ??
      mkStyle?.backgroundColor ??
      CoreMockupCodeStyle.defaultBackgroundColor;
  final textCore = CoreMockupCodeStyle.defaultTextStyle.merge(
    merged.textStyle,
  );
  final prefixCore = CoreMockupCodeStyle.defaultPrefixTextStyle.merge(
    merged.prefixTextStyle,
  );
  final borderRadiusCore =
      merged.borderRadius ??
      mkStyle?.borderRadius ??
      CoreMockupCodeStyle.defaultBorderRadius;
  final paddingCore = merged.padding ?? CoreMockupCodeStyle.defaultPadding;
  final lineSpacing =
      theme.geometry.space(
        merged.lineSpacing ?? CoreMockupCodeStyle.defaultLineSpacing,
      ) *
      scaling;
  final lineNumberWidth =
      (merged.lineNumberWidth ?? CoreMockupCodeStyle.defaultLineNumberWidth) *
      scaling;

  // ─── Composed OutlinedContainer surface (outer container) ──
  // The outer container is a composed `OutlinedContainer`, not a
  // hand-rolled `Container` (`core/style-contract.md`'s
  // child-component-composition rule) — background / radius / padding
  // stay `coui_core` domain types because `OutlinedContainer`'s own
  // resolver runs the `scheme.resolve(...).toValue()` step and applies
  // `theme.scaling` itself. Composing it also gets the "no shadow of my
  // own → take the active style's injected control-shadow at rest"
  // fallback for free. `MockupCode` never drew a border of its own —
  // `borderColor: transparent` collapses `OutlinedContainer`'s default
  // border width to 0 (a bare `borderWidth: 0` would still leave a
  // hairline — the suppression has to travel through the colour).
  final containerStyle = CoreOutlinedContainerStyle(
    backgroundColor: backgroundCore,
    borderColor: .transparent,
    borderRadius: borderRadiusCore,
    padding: paddingCore,
    width: .infinity,
  );

  // ─── Stage 2 EMIT — paint-ready Flutter values (local) ─
  // Colour = `scheme.resolve(c).toValue()`; typography =
  // `.toValue(theme:)` (the merged slot carries its own colour token —
  // `onSurface` / `onSurfaceVariant` or a caller override — which
  // `.toValue(theme:)` resolves through the active scheme). Dimensional
  // domain types convert theme-free via `.toValue()`.
  final textStyle = textCore.toValue(theme: theme);
  final prefixTextStyle = prefixCore.toValue(theme: theme);
  // A tone swaps only the colour: the tone slot's colour is laid over the
  // merged code text style, so the role / weight / line box are the text's
  // own. `neutral` has no slot and keeps the text style's colour.
  CoreColor? toneColorOf(CoreCodeLineTone tone) => switch (tone) {
    .neutral => null,
    .muted =>
      merged.mutedToneColor ?? CoreMockupCodeStyle.defaultMutedToneColor,
    .link => merged.linkToneColor ?? CoreMockupCodeStyle.defaultLinkToneColor,
    .success =>
      merged.successToneColor ?? CoreMockupCodeStyle.defaultSuccessToneColor,
    .warning =>
      merged.warningToneColor ?? CoreMockupCodeStyle.defaultWarningToneColor,
    .error =>
      merged.errorToneColor ?? CoreMockupCodeStyle.defaultErrorToneColor,
  };
  final toneTextStyles = {
    for (final tone in CoreCodeLineTone.values)
      tone: switch (toneColorOf(tone)) {
        final toneColor? =>
          textCore.merge(CoreTextStyle(color: toneColor)).toValue(theme: theme),
        null => textStyle,
      },
  };

  // ─── RETURN = bare mapping (+ * scaling on dimensional) ─
  return ResolvedMockupCode(
    containerStyle: containerStyle,
    textStyle: textStyle,
    toneTextStyles: toneTextStyles,
    prefixTextStyle: prefixTextStyle,
    lineSpacing: lineSpacing,
    lineNumberWidth: lineNumberWidth,
  );
}
