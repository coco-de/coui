import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedPagination
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Pagination`.
///
/// Widget tree (`co_pagination` decides which optional branches render):
///
/// ```text
/// Semantics
///   └─ Row (spacing: itemSpacing)
///        ├─ previous button (Clickable → OutlinedContainer)
///        ├─ optional skip-to-first / leading ellipsis button
///        ├─ page-number buttons (active/hover/idle ⇒ *ContainerStyle)
///        ├─ optional trailing ellipsis / skip-to-last button
///        └─ next button
/// ```
///
/// Each button is a composed `Clickable` (tap / keyboard activation /
/// cursor / press feedback / focus ring, fed the [clickableStyle] slot)
/// wrapping a composed `OutlinedContainer` (the face — fill, radius,
/// and whatever material the active style states for `role`) fed one
/// of the three pre-EMIT [activeContainerStyle] / [hoverContainerStyle]
/// / [idleContainerStyle] bundles, selected by `co_pagination`. Carrying
/// pre-EMIT Core values (not resolved Flutter ones) is what keeps the
/// scheme-resolve / geometry / scaling bend applied exactly once —
/// `OutlinedContainer` runs those steps itself (mirrors `Alert`'s
/// composed panel box).
///
/// Merge chain:
///
/// ```text
/// CorePaginationStyle.defaultX           // design-system default
///   → theme.coreComponentTheme.pagination.style
///   → theme.coreComponentTheme.pagination.variantStyles[variant]
///   → widget.paginationStyle
/// ```
class ResolvedPagination {
  /// Creates a [ResolvedPagination].
  const ResolvedPagination({
    required this.itemSpacing,
    required this.buttonTextStyle,
    required this.activeContainerStyle,
    required this.hoverContainerStyle,
    required this.idleContainerStyle,
    required this.labelHoverContainerStyle,
    required this.labelIdleContainerStyle,
    required this.activeForegroundColor,
    required this.hoverForegroundColor,
    required this.foregroundColor,
    required this.ellipsisForegroundColor,
    required this.disabledForegroundColor,
    required this.disabledActiveContainerStyle,
    required this.activeButtonTextStyle,
    required this.iconStyle,
    required this.ellipsisTextStyle,
    required this.clickableStyle,
  });

  /// Effective spacing between adjacent buttons (logical px, scaling
  /// pre-applied) — fed straight to the host-layout `Row.spacing` in
  /// `co_pagination`.
  final double itemSpacing;

  /// Paint-ready base [TextStyle] shared by every page-number / prev /
  /// next button — the `bodyMedium` role (14 / Regular) + the per-instance
  /// `buttonTextStyle` slot override, with **no colour** (the per-state
  /// foreground colour is overlaid by `co_pagination` via
  /// `copyWith(color:)`).
  final TextStyle buttonTextStyle;

  /// Paint-ready [TextStyle] of the active (current) page button — the
  /// `labelLarge` role at `semiBold` over the base, plus the per-instance
  /// `activeButtonTextStyle` override. No colour either
  /// ([activeForegroundColor] is overlaid by the widget).
  final TextStyle activeButtonTextStyle;

  /// Nested [CoreIconStyle] slot for the previous / next chevron — the size
  /// (pre-scaling, the `Icon` runs its own resolve step); the colour is the
  /// button's foreground.
  final CoreIconStyle iconStyle;

  /// Composed-`OutlinedContainer` chrome for the active (current) page
  /// button — fill = active background token, `surfaceBlur`/`surfaceOpacity`
  /// left unset so the box takes whatever material `role` states.
  final CoreOutlinedContainerStyle activeContainerStyle;

  /// Composed-`OutlinedContainer` chrome for the hovered button — fill =
  /// hover background token. `surfaceBlur: 0`, same as
  /// [idleContainerStyle]: the Web twin's hover fill is a CSS
  /// `:hover` pseudo-class, which cannot gate the marker class a
  /// material rule keys on, so a hover-only material would sit on the
  /// button at rest too.
  final CoreOutlinedContainerStyle hoverContainerStyle;

  /// Composed-`OutlinedContainer` chrome for the resting (idle) button —
  /// a transparent fill that draws nothing. `surfaceBlur: 0` forces the
  /// box out of the material path: this box states no fill, so it has
  /// no claim to the backdrop blur a filled sibling gets (blurring the
  /// page behind an invisible box would leave a frosted rectangle that
  /// no state ever explains).
  final CoreOutlinedContainerStyle idleContainerStyle;

  /// [hoverContainerStyle] for a previous / next button that shows its
  /// label: same height, fill and radius, but no width — the box takes
  /// its width from the icon, gap and label plus the label padding, so a
  /// word is never squeezed into the square page-button box.
  final CoreOutlinedContainerStyle labelHoverContainerStyle;

  /// [idleContainerStyle] for a previous / next button that shows its
  /// label — sized like [labelHoverContainerStyle].
  final CoreOutlinedContainerStyle labelIdleContainerStyle;

  /// Effective active (current) page button foreground colour.
  final Color activeForegroundColor;

  /// Effective hover foreground colour.
  final Color hoverForegroundColor;

  /// Effective inactive / prev / next button foreground colour.
  final Color foregroundColor;

  /// Effective foreground colour of the ellipsis (`…`) button at rest —
  /// `onSurfaceSubtle` by default, the decorative step beside the page
  /// numbers' [foregroundColor].
  final Color ellipsisForegroundColor;

  /// Effective foreground colour of every number, the ellipsis and the
  /// chevrons while the pagination is disabled.
  final Color disabledForegroundColor;

  /// [activeContainerStyle] while the pagination is disabled: same box and
  /// radius, the fill is the disabled container token.
  final CoreOutlinedContainerStyle disabledActiveContainerStyle;

  /// Paint-ready ellipsis (`…`) [TextStyle] override — `null` when the
  /// caller did not override. Materialised through the single
  /// `CoreTextStyle.toValue(theme:)` primitive (any role + overlay
  /// resolved, colour resolved through the active scheme), so the widget
  /// layers it onto its base text style via `TextStyle.merge`.
  final TextStyle? ellipsisTextStyle;

  /// Nested [CoreClickableStyle] slot for the composed per-button
  /// `Clickable` — `CorePaginationStyle.defaultClickableStyle` merged
  /// with the per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;
}

// ═══════════════════════════════════════════════════
// resolvePagination — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedPagination] for the given [context].
///
/// Walks the nested-merge chain and applies the
/// `CorePaginationStyle.defaultX` static const fallback so the widget
/// reads only fully-resolved Flutter-typed values.
ResolvedPagination resolvePagination(
  BuildContext context, {
  required CorePaginationVariant variant,
  CorePaginationStyle? paginationStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final paginationTheme = theme.coreComponentTheme?.pagination;

  // ─── Merge chain ──────────────────────────────────────
  // 3-stage merge chain — theme.style → theme.variantStyles[variant] →
  // widget.paginationStyle. Semantic identifier `variant` comes straight
  // from the widget; the theme cannot override it (render-only.md (c)).
  final merged = resolveStyleChain(const CorePaginationStyle(), [
    paginationTheme?.style,
    paginationTheme?.variantStyles?[variant],
    paginationStyle,
  ]);

  // ─── Stage 1 RESOLVE — paint-ready dimensional / chrome locals ──
  final itemSpacing =
      theme.geometry.space(
        merged.itemSpacing ?? CorePaginationStyle.defaultItemSpacing,
      ) *
      scaling;
  // Pre-scaled: `OutlinedContainer` does not scale `width` / `height`
  // itself (it hands them straight through), so the composed box needs
  // the already-scaled size the same way `Card` supplies its own.
  final buttonSize =
      (merged.buttonSize ?? CorePaginationStyle.defaultButtonSize) * scaling;
  // Raw (pre-EMIT) — `OutlinedContainer` runs its own
  // `.toValue(geometry:)` step, so handing it a resolved `BorderRadius`
  // here would bend the geometry constraint twice.
  final buttonRadius =
      merged.buttonRadius ?? CorePaginationStyle.defaultButtonRadius;
  // Raw (pre-EMIT) — `OutlinedContainer` runs `resolveMotionDuration`
  // itself when it applies `merged.duration` to its own transition.
  final hoverDuration =
      merged.hoverDuration ?? CorePaginationStyle.defaultHoverDuration;
  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest).
  final clickableStyle = CorePaginationStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // ─── Stage 2 EMIT — base button typography (paint-ready) ───────
  // Single primitive — `default.merge(override).toValue(theme:)`
  // materialises the `bodyMedium` role (carried by
  // `defaultButtonTextStyle`) and overlays the per-instance
  // `buttonTextStyle` slot. Carries no colour — the per-state foreground
  // colour is overlaid by `co_pagination` via `copyWith(color:)`.
  final baseButtonTextStyle = CorePaginationStyle.defaultButtonTextStyle.merge(
    merged.buttonTextStyle,
  );
  final buttonTextStyle = baseButtonTextStyle.toValue(theme: theme);
  // The active button's role (`labelLarge` at `semiBold`) is a DEFAULT, so it
  // is layered under the caller's overlays: a size or line box the caller
  // states on `buttonTextStyle` reaches the active button like every other
  // one, and `activeButtonTextStyle` goes last.
  final activeButtonTextStyle = CorePaginationStyle.defaultButtonTextStyle
      .merge(CorePaginationStyle.defaultActiveButtonTextStyle)
      .merge(merged.buttonTextStyle)
      .merge(merged.activeButtonTextStyle)
      .toValue(theme: theme);
  // Nested icon slot — raw-forwarded (the `Icon` scales itself).
  final iconStyle = CorePaginationStyle.defaultIconStyle.merge(
    merged.iconStyle,
  );

  // ─── Composed `OutlinedContainer` chrome — pre-EMIT, per state ──
  // The face is the panel box `Card` / `Alert` compose, not a hand-rolled
  // decoration: passing Core values (not resolved ones) is what keeps the
  // scheme-resolve / geometry / scaling bend applied exactly once — that
  // component runs those steps itself. Every bundle shares
  // size/radius/duration so swapping between them (active ⇄ hover ⇄ idle)
  // animates through the one `AnimatedContainer` `OutlinedContainer` owns
  // rather than a widget rebuild.
  //
  // A page button states a fill and nothing else — the Web twin draws a
  // bare box and so does the Figma set — and whatever a composed box
  // leaves unsaid, `OutlinedContainer` fills in. So the absence is stated,
  // twice, on every bundle:
  //  - stroke: `borderWidth: 0` alone is not "no stroke". The box still
  //    takes its default `outlineVariant`, and Flutter paints a zero-width
  //    solid side as a hairline (one device pixel). Only a transparent
  //    colour makes `OutlinedContainer` collapse the width, so the colour
  //    is stated as well.
  //  - cast: a box that states no shadow takes the active style's own
  //    (`controlShadow` — the hard offset under neoBrutalism). An
  //    explicitly empty stack is the one way to say "none"; the Web twin's
  //    cells carry no control-shadow marker either.
  //
  // Only the active bundle leaves `surfaceBlur` unset (inherits whatever
  // the active style states for `role`). Hover and idle force it to `0`:
  // hover's fill is a CSS `:hover` pseudo-class on the Web twin, which
  // cannot gate the *marker class* a material rule keys on — that class
  // is either always on the element or never is, so a hover-only
  // material would sit on the button at rest too and blur the page
  // behind an inactive, unhighlighted number. Suppressing it on Flutter
  // as well keeps the two platforms honest about what they can promise
  // in parity — see `theme-axis-composition.md`'s "표면 처리는 표면이
  // 자기를 표면으로 말할 때만 닿는다": a fill that only sometimes exists
  // is not a standing surface declaration.
  final activeBackgroundToken =
      merged.activeBackgroundColor ??
      CorePaginationStyle.defaultActiveBackgroundColor;
  final hoverBackgroundToken =
      merged.hoverBackgroundColor ??
      CorePaginationStyle.defaultHoverBackgroundColor;
  final disabledBackgroundToken =
      merged.disabledBackgroundColor ??
      CorePaginationStyle.defaultDisabledBackgroundColor;
  final activeContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: activeBackgroundToken,
    borderRadius: buttonRadius,
    borderWidth: 0,
    borderColor: .transparent,
    boxShadow: const [],
    width: buttonSize,
    height: buttonSize,
    duration: hoverDuration,
  );
  final disabledActiveContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: disabledBackgroundToken,
    borderRadius: buttonRadius,
    borderWidth: 0,
    borderColor: .transparent,
    boxShadow: const [],
    width: buttonSize,
    height: buttonSize,
    duration: hoverDuration,
  );
  final hoverContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: hoverBackgroundToken,
    borderRadius: buttonRadius,
    borderWidth: 0,
    borderColor: .transparent,
    boxShadow: const [],
    surfaceBlur: 0,
    width: buttonSize,
    height: buttonSize,
    duration: hoverDuration,
  );
  // `surfaceBlur: 0` — see the field doc on `ResolvedPagination
  // .idleContainerStyle`: a transparent fill has no claim to the
  // backdrop blur a filled sibling gets.
  final idleContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: .transparent,
    borderRadius: buttonRadius,
    borderWidth: 0,
    borderColor: .transparent,
    boxShadow: const [],
    surfaceBlur: 0,
    width: buttonSize,
    height: buttonSize,
    duration: hoverDuration,
  );
  // Label mode (previous / next with `showLabel`): the same bundles with
  // the width released to the content. Raw padding (pre-EMIT) —
  // `OutlinedContainer` scales its own padding.
  final labelButtonPadding =
      merged.labelButtonPadding ??
      CorePaginationStyle.defaultLabelButtonPadding;
  final labelHoverContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: hoverBackgroundToken,
    borderRadius: buttonRadius,
    borderWidth: 0,
    borderColor: .transparent,
    boxShadow: const [],
    surfaceBlur: 0,
    padding: labelButtonPadding,
    height: buttonSize,
    duration: hoverDuration,
  );
  final labelIdleContainerStyle = CoreOutlinedContainerStyle(
    backgroundColor: .transparent,
    borderRadius: buttonRadius,
    borderWidth: 0,
    borderColor: .transparent,
    boxShadow: const [],
    surfaceBlur: 0,
    padding: labelButtonPadding,
    height: buttonSize,
    duration: hoverDuration,
  );

  // ─── Stage 2 EMIT — foreground colours (scheme.resolve(c).toValue()) ──
  // Pulled from the nested `CoreTextStyle` slots (`activeTextStyle` /
  // `hoverTextStyle` / `textStyle`) whose `.color` carries the per-state
  // foreground (sb8).
  final activeForegroundColor = scheme
      .resolve(
        CorePaginationStyle.defaultActiveTextStyle
            .merge(merged.activeTextStyle)
            .color!,
      )
      .toValue();
  final hoverForegroundColor = scheme
      .resolve(
        CorePaginationStyle.defaultHoverTextStyle
            .merge(merged.hoverTextStyle)
            .color!,
      )
      .toValue();
  final foregroundColor = scheme
      .resolve(
        CorePaginationStyle.defaultTextStyle.merge(merged.textStyle).color!,
      )
      .toValue();
  final ellipsisForegroundColor = scheme
      .resolve(
        CorePaginationStyle.defaultEllipsisStyle
            .merge(merged.ellipsisStyle)
            .color!,
      )
      .toValue();
  final disabledForegroundColor = scheme
      .resolve(merged.disabledColor ?? CorePaginationStyle.defaultDisabledColor)
      .toValue();

  // ─── Stage 2 EMIT — ellipsis typography override (nullable) ────
  // The per-instance `ellipsisStyle` slot is a partial override the
  // widget merges onto its base text style via `TextStyle.merge`. When
  // unset, no override is emitted. The single primitive
  // `style.toValue(theme:)` materialises any role + overlay and resolves
  // its colour through the active scheme (dark-mode tracks).
  final ellipsisTextStyle = merged.ellipsisStyle?.toValue(theme: theme);

  return ResolvedPagination(
    itemSpacing: itemSpacing,
    buttonTextStyle: buttonTextStyle,
    activeContainerStyle: activeContainerStyle,
    hoverContainerStyle: hoverContainerStyle,
    idleContainerStyle: idleContainerStyle,
    labelHoverContainerStyle: labelHoverContainerStyle,
    labelIdleContainerStyle: labelIdleContainerStyle,
    activeForegroundColor: activeForegroundColor,
    hoverForegroundColor: hoverForegroundColor,
    foregroundColor: foregroundColor,
    ellipsisForegroundColor: ellipsisForegroundColor,
    disabledForegroundColor: disabledForegroundColor,
    disabledActiveContainerStyle: disabledActiveContainerStyle,
    activeButtonTextStyle: activeButtonTextStyle,
    iconStyle: iconStyle,
    ellipsisTextStyle: ellipsisTextStyle,
    clickableStyle: clickableStyle,
  );
}
