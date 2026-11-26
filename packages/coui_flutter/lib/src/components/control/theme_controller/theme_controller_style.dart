import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedThemeController
// ═══════════════════════════════════════════════════

/// Resolver output for [ThemeController].
///
/// Single struct that the widget reads — every chrome / dimensional
/// override has had the nested-merge chain applied plus the
/// `CoreThemeControllerStyle.defaultX` static const fallback and Flutter
/// type conversion:
///
/// ```text
/// CoreThemeControllerStyle.defaultX     // design system default
///   → CoreThemeControllerStyle.defaultsBySize[size]
///   → theme.coreComponentTheme.themeController.style
///   → widget.themeControllerStyle
/// ```
class ResolvedThemeController {
  /// Creates a [ResolvedThemeController].
  const ResolvedThemeController({
    required this.previewSize,
    required this.pressedPreviewSize,
    required this.buttonSpacing,
    required this.swatchMinWidth,
    required this.previewBorderRadius,
    required this.selectedContainerStyle,
    required this.unselectedContainerStyle,
    required this.hoverContainerStyle,
    required this.disabledContainerStyle,
    required this.disabledSelectedContainerStyle,
    required this.labelTextStyle,
    required this.selectedLabelTextStyle,
    required this.disabledLabelTextStyle,
    required this.labelGapStyle,
    required this.disabledPreviewColor,
    required this.clickableStyle,
  });

  /// Effective colour-preview circle size (logical px, scaling
  /// applied).
  final double previewSize;

  /// Colour-preview circle size while its swatch is pressed (logical px,
  /// scaling applied) — [previewSize] less
  /// `CoreThemeControllerStyle.pressedPreviewShrink`. The corner radius
  /// is [previewBorderRadius] either way: fully round, so the smaller
  /// circle is still a circle.
  final double pressedPreviewSize;

  /// Effective spacing between adjacent theme buttons (logical px,
  /// scaling applied) — consumed by `co_*` as native `Wrap.spacing` /
  /// `Wrap.runSpacing`.
  final double buttonSpacing;

  /// Minimum width of one swatch cell (logical px, scaling applied) — a
  /// floor, so a longer theme name widens its own cell instead of being cut.
  final double swatchMinWidth;

  /// Effective colour-preview circle corner radius — defaults to a
  /// fully round dot.
  final BorderRadius previewBorderRadius;

  /// Composed-`OutlinedContainer` chrome for a selected swatch button —
  /// fill = the button background token (unchanged by selection),
  /// border = the selected border token: the ring that marks the
  /// selection. The swatch button is a ring around the palette, not a
  /// surface with a fill of its own, so `surfaceBlur` is forced to 0
  /// while the fill paints nothing; a caller who gives it a fill gets the
  /// material the box's `role` states.
  final CoreOutlinedContainerStyle selectedContainerStyle;

  /// Composed-`OutlinedContainer` chrome for an unselected swatch
  /// button at rest — same fill as [selectedContainerStyle]; the border
  /// is the unselected one, which is zero wide by default (no ring).
  final CoreOutlinedContainerStyle unselectedContainerStyle;

  /// Chrome for an unselected, enabled swatch while it is hovered or
  /// pressed — the hover ring (`hoverBorderColor` · `hoverBorderWidth`).
  /// A selected swatch keeps [selectedContainerStyle] in those states.
  final CoreOutlinedContainerStyle hoverContainerStyle;

  /// Nested [CoreClickableStyle] slot for the composed per-swatch
  /// `Clickable` — `CoreThemeControllerStyle.defaultClickableStyle`
  /// merged with the per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;

  /// Button chrome for a **disabled unselected** swatch — the border
  /// colour drops to the disabled token; the fill and geometry are the
  /// enabled ones.
  final CoreOutlinedContainerStyle disabledContainerStyle;

  /// Button chrome for a **disabled selected** swatch. Keeps the
  /// selected border *width* so the selection survives the greying;
  /// only the colour drops.
  final CoreOutlinedContainerStyle disabledSelectedContainerStyle;

  /// Paint-ready label typography for an enabled, unselected swatch.
  final TextStyle labelTextStyle;

  /// Paint-ready label typography for the enabled, selected swatch — the
  /// same role in the selected ink.
  final TextStyle selectedLabelTextStyle;

  /// Paint-ready label typography for a disabled swatch.
  final TextStyle disabledLabelTextStyle;

  /// Nested [CoreGapStyle] slot for the button-to-label gap —
  /// raw-forwarded to `Gap`.
  final CoreGapStyle labelGapStyle;

  /// Resolved fill every palette segment takes on a disabled swatch —
  /// the palette discards the caller's colours there.
  final Color disabledPreviewColor;
}

// ═══════════════════════════════════════════════════
// resolveThemeController — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedThemeController] for the given [context].
///
/// Walks the nested-merge chain and applies the
/// `CoreThemeControllerStyle.defaultX` static const fallback so the
/// widget reads only fully-resolved Flutter-typed values.
ResolvedThemeController resolveThemeController(
  BuildContext context, {
  required CoreThemeControllerSize size,
  CoreThemeControllerStyle? themeControllerStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final controllerTheme = theme.coreComponentTheme?.themeController;

  // The size tier is the base of the chain, not a lookup beside it: the
  // ladder states several fields at once (button / preview / radius /
  // spacing plus label), and a project or instance override has to be
  // able to move one of them without restating the rest.
  final sizeStyle = CoreThemeControllerStyle.defaultsBySize[size]!;
  final merged = resolveStyleChain(sizeStyle, [
    controllerTheme?.style,
    themeControllerStyle,
  ]);

  // Pre-scaled: `OutlinedContainer` does not scale `width` / `height`
  // itself, so the composed button needs the already-scaled size.
  final buttonSize =
      (merged.buttonSize ?? CoreThemeControllerStyle.defaultButtonSize) *
      scaling;
  final previewSizeCore =
      merged.previewSize ?? CoreThemeControllerStyle.defaultPreviewSize;
  final previewSize = previewSizeCore * scaling;
  // The pressed circle is the resting one less a fixed amount, each
  // scaled once — never `previewSize` (already scaled) less a raw amount.
  final pressedPreviewSize =
      (previewSizeCore -
          (merged.pressedPreviewShrink ??
              CoreThemeControllerStyle.defaultPressedPreviewShrink)) *
      scaling;
  final buttonSpacing =
      theme.geometry.space(
        merged.buttonSpacing ?? CoreThemeControllerStyle.defaultButtonSpacing,
      ) *
      scaling;
  final swatchMinWidth =
      (merged.swatchMinWidth ??
          CoreThemeControllerStyle.defaultSwatchMinWidth) *
      scaling;
  // The preview circle is a plain decorative dot (a colour sample, not a
  // surface) — kept as a direct Flutter conversion, unlike the button
  // chrome below.
  final previewBorderRadius =
      (merged.previewBorderRadius ??
              CoreThemeControllerStyle.defaultPreviewBorderRadius)
          .toValue(geometry: theme.geometry);
  final buttonBackgroundColor =
      merged.buttonBackgroundColor ??
      CoreThemeControllerStyle.defaultButtonBackgroundColor;
  // Whether the button paints a fill at rest. The ring around a palette is
  // not a surface, so a material has nothing to frost behind it unless a
  // caller gave it a fill — the Web twin gates its surface marker on the
  // same answer.
  final paintsFill =
      theme.colorScheme.resolve(buttonBackgroundColor).toValue().a > 0;
  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest).
  final clickableStyle = CoreThemeControllerStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // ─── Composed `OutlinedContainer` chrome — pre-EMIT, per state ──
  // The face is the box `Card` / `Radio` compose, not a hand-rolled
  // decoration: passing Core values (not resolved ones) is what keeps
  // the scheme-resolve / geometry / scaling bend applied exactly once —
  // `OutlinedContainer` runs those steps itself. Every bundle shares the
  // same fill token and the same size / radius, so swapping between them
  // animates through the one `AnimatedContainer` `OutlinedContainer`
  // owns rather than a widget rebuild.
  //
  // `surfaceBlur: 0` while the fill paints nothing: a material would
  // frost the page behind a ring that has no body. Same forced zero
  // `Checkbox` / `Toggle` / `Radio` state for their bodiless boxes.
  final buttonRadius =
      merged.buttonRadius ?? CoreThemeControllerStyle.defaultButtonRadius;
  final surfaceBlur = paintsFill ? null : 0.0;
  // A cast is the shadow of a filled box. The container contributes the
  // surface style's cast whenever a box states no shadow of its own, and
  // `BoxDecoration` paints that cast as a solid shape BEHIND the box — so
  // over a transparent body it shows through as a block behind the palette
  // (CSS clips the inside, which is why Web draws none). An explicitly
  // empty stack is how a box says "no shadow"; a body that paints keeps
  // the style's.
  final boxShadow = paintsFill ? null : const <CoreShadowLayer>[];
  CoreOutlinedContainerStyle ring(CoreColor color, double width) =>
      CoreOutlinedContainerStyle(
        backgroundColor: buttonBackgroundColor,
        borderColor: color,
        borderRadius: buttonRadius,
        borderWidth: width,
        width: buttonSize,
        height: buttonSize,
        surfaceBlur: surfaceBlur,
        boxShadow: boxShadow,
      );
  final selectedBorderColor =
      merged.selectedBorderColor ??
      CoreThemeControllerStyle.defaultSelectedBorderColor;
  final selectedBorderWidth =
      merged.selectedBorderWidth ??
      CoreThemeControllerStyle.defaultSelectedBorderWidth;
  final selectedContainerStyle = ring(selectedBorderColor, selectedBorderWidth);
  final unselectedContainerStyle = ring(
    merged.unselectedBorderColor ??
        CoreThemeControllerStyle.defaultUnselectedBorderColor,
    merged.unselectedBorderWidth ??
        CoreThemeControllerStyle.defaultUnselectedBorderWidth,
  );
  final hoverContainerStyle = ring(
    merged.hoverBorderColor ?? CoreThemeControllerStyle.defaultHoverBorderColor,
    merged.hoverBorderWidth ?? CoreThemeControllerStyle.defaultHoverBorderWidth,
  );

  // ─── Disabled button chrome — the same two boxes with the border
  // colour swapped. Widths are untouched: a locked selected swatch is
  // still the selected one, and dropping to a hairline there would take
  // the selection away rather than grey it.
  final disabledBorderColor =
      merged.disabledBorderColor ??
      CoreThemeControllerStyle.defaultDisabledBorderColor;
  final disabledContainerStyle = unselectedContainerStyle.copyWith(
    borderColor: disabledBorderColor,
  );
  final disabledSelectedContainerStyle = selectedContainerStyle.copyWith(
    borderColor: disabledBorderColor,
  );

  // ─── Label · palette-disabled ──────────────────────────────────
  final labelStyle = CoreThemeControllerStyle.defaultLabelStyle.merge(
    merged.labelStyle,
  );
  // The role carries no colour (Core states it separately), so the
  // state colour is laid on here — one source per state, and the
  // caller's `labelStyle` colour still wins if it set one.
  final labelColor = theme.colorScheme
      .resolve(
        labelStyle.color ??
            merged.labelColor ??
            CoreThemeControllerStyle.defaultLabelColor,
      )
      .toValue();
  final labelTextStyle = labelStyle
      .toValue(theme: theme)
      .copyWith(color: labelColor);
  final selectedLabelColor = theme.colorScheme
      .resolve(
        labelStyle.color ??
            merged.selectedLabelColor ??
            CoreThemeControllerStyle.defaultSelectedLabelColor,
      )
      .toValue();
  final selectedLabelTextStyle = labelTextStyle.copyWith(
    color: selectedLabelColor,
  );
  final disabledLabelColor = theme.colorScheme
      .resolve(
        merged.disabledLabelColor ??
            CoreThemeControllerStyle.defaultDisabledLabelColor,
      )
      .toValue();
  final disabledLabelTextStyle = labelTextStyle.copyWith(
    color: disabledLabelColor,
  );
  final labelGapStyle = CoreThemeControllerStyle.defaultLabelGapStyle.merge(
    merged.labelGapStyle,
  );
  final disabledPreviewColor = theme.colorScheme
      .resolve(
        merged.disabledPreviewColor ??
            CoreThemeControllerStyle.defaultDisabledPreviewColor,
      )
      .toValue();

  return ResolvedThemeController(
    previewSize: previewSize,
    pressedPreviewSize: pressedPreviewSize,
    buttonSpacing: buttonSpacing,
    swatchMinWidth: swatchMinWidth,
    previewBorderRadius: previewBorderRadius,
    selectedContainerStyle: selectedContainerStyle,
    unselectedContainerStyle: unselectedContainerStyle,
    hoverContainerStyle: hoverContainerStyle,
    disabledContainerStyle: disabledContainerStyle,
    disabledSelectedContainerStyle: disabledSelectedContainerStyle,
    labelTextStyle: labelTextStyle,
    selectedLabelTextStyle: selectedLabelTextStyle,
    disabledLabelTextStyle: disabledLabelTextStyle,
    labelGapStyle: labelGapStyle,
    disabledPreviewColor: disabledPreviewColor,
    clickableStyle: clickableStyle,
  );
}
