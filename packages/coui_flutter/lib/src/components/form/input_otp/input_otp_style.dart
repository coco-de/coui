import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedInputOtp
// ═══════════════════════════════════════════════════

/// Resolver output for `InputOtp`.
///
/// Single struct that the widget reads — every field has had the
/// nested-merge chain applied plus token-table fallback and type
/// conversion. Dimensional values are post-scaling (`* theme.scaling`).
/// `CoreTextStyle` slot is forwarded raw to the child unified `Text`
/// widget which self-scales.
class ResolvedInputOtp {
  /// Creates a [ResolvedInputOtp].
  const ResolvedInputOtp({
    required this.cellSize,
    required this.cellHeight,
    required this.obscuredDotSize,
    required this.obscuredDotColor,
    required this.cellSpacing,
    required this.height,
    required this.focusedCellContainerStyle,
    required this.unfocusedCellContainerStyle,
    required this.hoveredCellContainerStyle,
    required this.filledCellContainerStyle,
    required this.focusedFilledCellContainerStyle,
    required this.hoveredFilledCellContainerStyle,
    required this.caretColor,
    required this.caretWidth,
    required this.caretHeight,
    required this.caretBorderRadius,
    required this.separatorPadding,
    required this.separatorColor,
    required this.separatorWidth,
    required this.separatorThickness,
    required this.separatorBorderRadius,
    required this.valueTextStyle,
    required this.cellFocusOutlineStyle,
    required this.errorValidatorHintStyle,
    required this.errorTextPadding,
  });

  /// Width of each OTP cell (logical px, post-scaling).
  final double cellSize;

  /// Height of each OTP cell (logical px, post-scaling) — the chain
  /// `cellHeight ?? cellSize ?? CoreInputOtpStyle.defaultCellHeight`, so an
  /// unstated height keeps the cell square.
  final double cellHeight;

  /// Obscured-character dot size (logical px, square; scaling
  /// pre-applied).
  final double obscuredDotSize;

  /// Paint-ready colour of the obscured-character dot — the value-glyph
  /// foreground (`onSurface`) resolved through the active scheme. Mirrors
  /// the Web dot colour (`CoreInputOtpStyle.defaultTextStyle.color`).
  /// This glyph stays a directly-painted `Container` (never composed) —
  /// its opacity is exactly the signal the cell fill must not compete
  /// with, unlike the checked-glyph concern this mirrors.
  final Color obscuredDotColor;

  /// Gap between sibling OTP cells (logical px, post-scaling) —
  /// consumed natively as `Row(spacing: …)`.
  final double cellSpacing;

  /// Overall height of the OTP input row (logical px, post-scaling) —
  /// never shorter than [cellHeight], so a taller cell is not squeezed by
  /// the row's scale-down fit.
  final double height;

  /// Chrome for the active (focused) cell while it is EMPTY — fill =
  /// `focusBackgroundColor ?? backgroundColor`, border =
  /// `focusBorderColor ?? variant focus border ?? borderColor`: the empty
  /// cell's own look unless something states a focus colour. The caret and
  /// the ring are the focus signal.
  /// `surfaceBlur` is left unset: the fill is a real, opaque design
  /// token and no glyph rides directly on the cell fill — the
  /// obscured-dot / digit glyph paints as a separate `Position.fill`
  /// sibling on top, not inside this container's decoration — so
  /// there is no fill-less-box or glyph-contrast risk in letting a
  /// material preset reach it.
  final CoreOutlinedContainerStyle focusedCellContainerStyle;

  /// Chrome for an EMPTY cell while it is not the active cell — fill =
  /// `backgroundColor` token, border = `borderColor` token. Same
  /// `surfaceBlur`-unset reasoning as [focusedCellContainerStyle].
  final CoreOutlinedContainerStyle unfocusedCellContainerStyle;

  /// Chrome for a resting EMPTY cell while the pointer is over the control —
  /// fill = `backgroundColor` token (the idle fill, hover does not tint),
  /// border = `hoverBorderColor` token (`onSurface`; the error variant
  /// restates `error`). The widget picks it only when the control is
  /// enabled and no cell holds focus, so the ladder
  /// `disabled > error > focus > hover > rest` is decided by which style
  /// the widget selects, never by a colour computed here. Same
  /// `surfaceBlur`-unset reasoning as [focusedCellContainerStyle].
  final CoreOutlinedContainerStyle hoveredCellContainerStyle;

  /// Chrome for a cell that holds a digit while it is not the active cell —
  /// fill = `filledBackgroundColor`, border = `filledBorderColor`.
  final CoreOutlinedContainerStyle filledCellContainerStyle;

  /// Chrome for the active cell while it holds a digit — the filled look,
  /// unless a focus colour is stated.
  final CoreOutlinedContainerStyle focusedFilledCellContainerStyle;

  /// Chrome for a resting filled cell while the pointer is over the control
  /// — the filled fill with the hover border.
  final CoreOutlinedContainerStyle hoveredFilledCellContainerStyle;

  /// Paint-ready colour of the caret drawn in the active empty cell.
  final Color caretColor;

  /// Caret width (logical px, post-scaling).
  final double caretWidth;

  /// Caret height (logical px, post-scaling).
  final double caretHeight;

  /// Caret corner (post-scaling).
  final BorderRadius caretBorderRadius;

  /// Resolved padding around the separator bar (scaling pre-applied).
  final EdgeInsets separatorPadding;

  /// Paint-ready colour of the separator bar.
  final Color separatorColor;

  /// Separator bar length (logical px, post-scaling).
  final double separatorWidth;

  /// Separator bar thickness (logical px, post-scaling).
  final double separatorThickness;

  /// Separator bar corner (post-scaling).
  final BorderRadius separatorBorderRadius;

  /// Paint-ready text style for the OTP value glyph — the Core
  /// `defaultTextStyle` (`titleMedium` bound to the `onSurface` colour),
  /// then layered with the merged `textStyle` — the size row's role (`lg`
  /// restates its own; `md` states nothing), the theme and the
  /// per-instance override.
  final TextStyle valueTextStyle;

  /// Nested [CoreFocusOutlineStyle] slot forwarded to the active cell's
  /// `FocusOutline` — carries the cell's own corner radius (so the ring
  /// tracks the cell shape) plus the `error`-token ring colour override
  /// when the field is in its error variant. Raw-forwarded (no scaling
  /// or scheme resolution here — `FocusOutline`'s own resolver does
  /// that).
  final CoreFocusOutlineStyle cellFocusOutlineStyle;

  /// Nested [CoreValidatorHintStyle] slot forwarded raw to the composed
  /// `ValidatorHint.error` that renders the error line — see
  /// `CoreInputOtpStyle.resolveErrorValidatorHintStyle`. Rendered only when
  /// `widget.errorText != null`.
  final CoreValidatorHintStyle errorValidatorHintStyle;

  /// Resolved padding above the error helper message (post-scaling).
  final EdgeInsets errorTextPadding;
}

// ═══════════════════════════════════════════════════
// Resolver — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedInputOtp] for the given [context].
///
/// Walks the nested-merge chain plus token / colour fallback in a
/// single pass:
///
/// ```text
/// CoreInputOtpStyle.default*                 (per-field terminal fallback)
///   → CoreInputOtpStyle.defaultsBySize[size]    ┐ head of the merge chain
///   → CoreInputOtpStyle.defaultsByVariant[variant] ┘ (`chainHeadFor`)
///   → theme.coreComponentTheme.inputOtp.style
///   → theme.coreComponentTheme.inputOtp.variantStyles[variant]
///   → widget.inputOtpStyle
/// ```
///
/// [size] selects the size row — a build-time semantic identifier, never
/// read from the theme. The variant row is laid over it, so `lg`'s own
/// cell colours never erase the error variant's `error` borders; the
/// theme's and the caller's values still win over both. `md`'s row is
/// empty, so an `md` field resolves exactly as it did before the size axis
/// existed.
ResolvedInputOtp resolveInputOtp(
  BuildContext context, {
  CoreInputOtpSize size = CoreInputOtpSize.defaultSize,
  bool hasError = false,
  CoreInputOtpStyle? inputOtpStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final inputOtpTheme = theme.coreComponentTheme?.inputOtp;

  // `hasError` is a build-time semantic flag (not an interaction state),
  // so Map dispatch through `defaultsByVariant` is the correct resolver
  // pattern — never a scattered `if (hasError)` per field.
  final variant = hasError
      ? CoreInputOtpVariant.error
      : CoreInputOtpVariant.defaultVariant;
  final variantStyle = CoreInputOtpStyle.defaultsByVariant[variant]!;

  // The size row with the variant row over it heads the chain — `lg`
  // states its own cell colours, and the variant coming second keeps the
  // error variant's `error` borders on an `lg` field. Every later layer
  // (theme style, theme variant style, widget) still beats both.
  final callerLayers = [
    inputOtpTheme?.style,
    inputOtpTheme?.variantStyles?[variant],
    inputOtpStyle,
  ];
  final merged = resolveStyleChain(
    CoreInputOtpStyle.chainHeadFor(size, variant),
    callerLayers,
  );

  // ─── Stage 1 RESOLVE + Stage 2 EMIT (local vars) ──────
  // Dimensional fallback → `* scaling` (Stage 2 EMIT) — produced in the
  // local, never in the return literal.
  final cellSize =
      (merged.cellSize ?? CoreInputOtpStyle.defaultCellSize) * scaling;
  final cellHeight =
      (merged.cellHeight ??
          merged.cellSize ??
          CoreInputOtpStyle.defaultCellHeight) *
      scaling;
  final obscuredDotSize =
      (merged.obscuredDotSize ?? CoreInputOtpStyle.defaultObscuredDotSize) *
      scaling;
  final cellSpacing =
      theme.geometry.space(
        merged.cellSpacing ?? CoreInputOtpStyle.defaultCellSpacing,
      ) *
      scaling;
  // The row is never shorter than its cells — the Web root takes the same
  // larger of the two, so a tall cell neither shrinks (here, under the
  // row's scale-down fit) nor overflows (there).
  final height = math.max(
    (merged.height ?? CoreInputOtpStyle.defaultHeight) * scaling,
    cellHeight,
  );
  final separatorPadding =
      (merged.separatorPadding ?? CoreInputOtpStyle.defaultSeparatorPadding)
          .toValue(geometry: theme.geometry) *
      scaling;
  final transitionDuration = resolveMotionDuration(
    context,
    merged.transitionDuration ?? CoreInputOtpStyle.defaultTransitionDuration,
  );

  // Cell radius / border-width / colours stay raw Core values here — the
  // cell box is a composed `OutlinedContainer`, which runs
  // scheme.resolve / geometry / scaling itself for whatever flows
  // through `containerStyle`. `borderRadiusCoreRaw` is also
  // raw-forwarded (un-bent) to the nested `cellFocusOutlineStyle` slot
  // so `FocusOutline`'s own resolver is the single place geometry +
  // scaling apply to the ring.
  final borderRadiusCoreRaw =
      merged.borderRadius ?? CoreInputOtpStyle.defaultBorderRadius;
  final borderWidthCoreRaw =
      merged.borderWidth ?? CoreInputOtpStyle.defaultBorderWidth;

  // Background / border — raw Core tokens, one pair per fill state. The
  // border folds in the variant chrome (`variantStyle.X` — the `error`
  // token when `hasError`) before the terminal static default, per the
  // resolver-pattern's variant fallback chain.
  final backgroundColorCore =
      merged.backgroundColor ?? CoreInputOtpStyle.defaultBackgroundColor;
  final borderColorCore =
      merged.borderColor ??
      variantStyle.borderColor ??
      CoreInputOtpStyle.defaultBorderColor;
  final filledBackgroundColorCore =
      merged.filledBackgroundColor ??
      CoreInputOtpStyle.defaultFilledBackgroundColor;
  final filledBorderColorCore =
      merged.filledBorderColor ??
      variantStyle.filledBorderColor ??
      CoreInputOtpStyle.defaultFilledBorderColor;
  // Hovered-cell border — caller override wins, else the variant's own
  // hover step (the error variant restates `error`, so an invalid control
  // does not soften under the pointer), else the design-system hover tone.
  final hoverBorderColorCore =
      merged.hoverBorderColor ??
      variantStyle.hoverBorderColor ??
      CoreInputOtpStyle.defaultHoverBorderColor;
  // Active-cell colours — the fill keeps the cell's fill state; the edge is
  // a stated focus colour (caller, else variant chrome — `error`), else the
  // neutral `defaultFocusBorderColor` (`outline`) on empty and filled cells
  // alike — never `primary`: the caret and the ring say "focused". The
  // empty arm's fill terminal is the named `defaultFocusBackgroundColor`.
  final focusBorderColorCore =
      merged.focusBorderColor ??
      variantStyle.focusBorderColor ??
      CoreInputOtpStyle.defaultFocusBorderColor;
  final focusBackgroundColorCore =
      merged.focusBackgroundColor ??
      merged.backgroundColor ??
      CoreInputOtpStyle.defaultFocusBackgroundColor;
  final focusFilledBackgroundColorCore =
      merged.focusBackgroundColor ?? filledBackgroundColorCore;

  // Caret — the active empty cell's insertion mark.
  final caretColor = scheme
      .resolve(
        merged.caretColor ??
            variantStyle.caretColor ??
            CoreInputOtpStyle.defaultCaretColor,
      )
      .toValue();
  final caretWidth =
      (merged.caretWidth ?? CoreInputOtpStyle.defaultCaretWidth) * scaling;
  final caretHeight =
      (merged.caretHeight ?? CoreInputOtpStyle.defaultCaretHeight) * scaling;
  final caretBorderRadius =
      (merged.caretBorderRadius ?? CoreInputOtpStyle.defaultCaretBorderRadius)
          .toValue(geometry: theme.geometry) *
      scaling;

  // Separator bar.
  final separatorColor = scheme
      .resolve(merged.separatorColor ?? CoreInputOtpStyle.defaultSeparatorColor)
      .toValue();
  final separatorWidth =
      (merged.separatorWidth ?? CoreInputOtpStyle.defaultSeparatorWidth) *
      scaling;
  final separatorThickness =
      (merged.separatorThickness ??
          CoreInputOtpStyle.defaultSeparatorThickness) *
      scaling;
  final separatorBorderRadius =
      (merged.separatorBorderRadius ??
              CoreInputOtpStyle.defaultSeparatorBorderRadius)
          .toValue(geometry: theme.geometry) *
      scaling;

  // Obscured-dot colour — the value-glyph foreground (`onSurface`) via the
  // Core named default (`defaultTextStyle.color`), resolved through the
  // active scheme. Web parity: the dot uses the same `defaultTextStyle
  // .color` token. `!` is safe — `defaultTextStyle` always binds a colour.
  final obscuredDotColor = scheme
      .resolve(CoreInputOtpStyle.defaultTextStyle.color!)
      .toValue();

  // ─── Value glyph typography (paint-ready TextStyle) ───
  // Single primitive — `default.merge(override).toValue(theme:)`. The
  // Core `defaultTextStyle` slot carries the base role + the `onSurface`
  // colour; the merged `textStyle` (the size row's role, then theme /
  // instance overrides) layers on top, so `toValue(theme:)` materialises
  // the winning role and resolves the colour through the active scheme.
  final valueTextStyle = CoreInputOtpStyle.defaultTextStyle
      .merge(merged.textStyle)
      .toValue(theme: theme);

  // ─── Error line (nested ValidatorHint slot, raw-forward) ─
  // The composed `ValidatorHint.error` resolves its own accent, glyph and
  // message role; this forwards only InputOtp's divergence (the 14 glyph)
  // and the caller's overrides — one Core helper, shared with Web.
  final errorValidatorHintStyle = merged.resolveErrorValidatorHintStyle();
  final errorTextPadding =
      (merged.errorTextPadding ?? CoreInputOtpStyle.defaultErrorTextPadding)
          .toValue(geometry: theme.geometry) *
      scaling;

  // ─── Cell focus-outline nested slot (raw-forward) ─────
  // Only the cell's own corner radius and, when set, the ring colour are
  // supplied — `FocusOutline`'s own resolver applies scaling / scheme
  // resolution / its remaining design-system defaults (ring width,
  // offset, animation). The ring colour is the focus border a caller or
  // the variant states (theme / widget override → variant chrome,
  // unresolved) rather than a separate `hasError` ternary, so a project
  // overriding the error variant's `focusBorderColor` via
  // `CoreInputOtpTheme.variantStyles` recolours the ring consistently
  // with the cell border instead of leaving it hardcoded to the global
  // `error` token. The size row is left out on purpose: a size states no
  // ring colour, so the ring keeps `FocusOutline`'s default on every size.
  final ringColorStyle = resolveStyleChain(variantStyle, callerLayers);
  final cellFocusOutlineStyle = CoreFocusOutlineStyle(
    borderRadius: borderRadiusCoreRaw,
    borderColor: ringColorStyle.focusBorderColor,
  );

  // ─── Composed `OutlinedContainer` chrome — pre-EMIT, per state ──
  // Each cell box is a composed `OutlinedContainer` rather than a
  // hand-rolled decoration: passing Core values (not resolved ones)
  // keeps the scheme-resolve / geometry / scaling / cast-injection
  // bend applied exactly once — `OutlinedContainer` runs those steps
  // itself (its own fallback replaces the manual cast-injection helper
  // this resolver used to call). No `width`/`height` here — the cell's
  // footprint comes from the outer
  // `SizedBox(width: cellSize, height: cellHeight)` / `Position.fill` the
  // widget already wraps this container in. One builder, six
  // (fill state × interaction) arms — the widget picks one per cell.
  CoreOutlinedContainerStyle cellStyle(CoreColor fill, CoreColor border) =>
      CoreOutlinedContainerStyle(
        backgroundColor: fill,
        borderColor: border,
        borderRadius: borderRadiusCoreRaw,
        borderWidth: borderWidthCoreRaw,
        preserveTransparentBorder: true,
        duration: transitionDuration,
      );
  final unfocusedCellContainerStyle = cellStyle(
    backgroundColorCore,
    borderColorCore,
  );
  final focusedCellContainerStyle = cellStyle(
    focusBackgroundColorCore,
    focusBorderColorCore,
  );
  final hoveredCellContainerStyle = cellStyle(
    backgroundColorCore,
    hoverBorderColorCore,
  );
  final filledCellContainerStyle = cellStyle(
    filledBackgroundColorCore,
    filledBorderColorCore,
  );
  final focusedFilledCellContainerStyle = cellStyle(
    focusFilledBackgroundColorCore,
    focusBorderColorCore,
  );
  final hoveredFilledCellContainerStyle = cellStyle(
    filledBackgroundColorCore,
    hoverBorderColorCore,
  );

  return ResolvedInputOtp(
    cellSize: cellSize,
    cellHeight: cellHeight,
    obscuredDotSize: obscuredDotSize,
    obscuredDotColor: obscuredDotColor,
    cellSpacing: cellSpacing,
    height: height,
    focusedCellContainerStyle: focusedCellContainerStyle,
    unfocusedCellContainerStyle: unfocusedCellContainerStyle,
    hoveredCellContainerStyle: hoveredCellContainerStyle,
    filledCellContainerStyle: filledCellContainerStyle,
    focusedFilledCellContainerStyle: focusedFilledCellContainerStyle,
    hoveredFilledCellContainerStyle: hoveredFilledCellContainerStyle,
    caretColor: caretColor,
    caretWidth: caretWidth,
    caretHeight: caretHeight,
    caretBorderRadius: caretBorderRadius,
    separatorPadding: separatorPadding,
    separatorColor: separatorColor,
    separatorWidth: separatorWidth,
    separatorThickness: separatorThickness,
    separatorBorderRadius: separatorBorderRadius,
    valueTextStyle: valueTextStyle,
    cellFocusOutlineStyle: cellFocusOutlineStyle,
    errorValidatorHintStyle: errorValidatorHintStyle,
    errorTextPadding: errorTextPadding,
  );
}
