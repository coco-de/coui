import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// Raw rest paint stays inline through var(state, exactRawBase). Ordinary
// state rules only set that private property; this value-free body reset
// prevents a nested raw face from inheriting its parent's state fill.
const _kChipHoverFillVar = '--co-chip-hover-fill';
const _kChipFocusFillVar = '--co-chip-focus-fill';
const _kChipPressedFillVar = '--co-chip-pressed-fill';
const _kChipStateFillVar = '--co-chip-state-fill';
const _kChipStateResetRule =
    ':where(.$kChipBodyMarker){$_kChipStateFillVar:initial;}';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Chip`.
///
/// DOM shape (`co_chip` wraps [root] in a composing `Clickable` —
/// which owns cursor / focus ring / press feedback / keyboard
/// activation — only when the chip is tappable, `onTap != null`):
///
/// ```text
/// root (<div>)                                      // chip — inline-flex, border, radius, padding
///   ├─ leading (caller-supplied Component)          // co_chip renders only when leading != null
///   ├─ Gap (iconLabelGapStyle)                    // co_chip renders only when leading != null
///   ├─ prefixLabel (<span>)                         // co_chip renders only when prefixLabel != null — one line, never shrinks
///   ├─ Gap (iconLabelGapStyle)                    // co_chip renders only when prefixLabel != null and a label / child follows
///   ├─ child (caller-supplied Component) | label (<span>)
///   │                                               // co_chip prefers `child`; falls back to default `<span>` label
///   ├─ Gap (iconLabelGapStyle)                    // co_chip renders only when trailing != null
///   ├─ trailing (caller-supplied Component)         // co_chip renders only when trailing != null
///   ├─ Gap (iconLabelGapStyle)                    // co_chip renders only when onRemove != null && enabled
///   └─ closeButton (Button)                       // co_chip renders only when onRemove != null && enabled
/// ```
///
/// All slot chromes are non-null — `co_chip` decides whether to render
/// each optional slot based on instance state.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — [WebElementChrome] slots (paint-ready chrome).
/// * Cat 2 — nested `CoreXxxStyle` slots passed to child unified
///   widgets. The leading / trailing icon style slots
///   ([leadingIconStyle] / [trailingIconStyle]) are handed to the
///   caller-supplied `leading` / `trailing` slot as the nearest
///   `IconTheme`, so a bare `Icon` placed there takes the size row's glyph
///   size; the close-button slot pair ([closeIconStyle] /
///   [closeButtonStyle]) is forwarded to the nested
///   `Button(buttonStyle: …)` + `Icon(iconStyle: …)` pair `co_chip`
///   synthesises for `onRemove`.
///   [iconLabelGapStyle] is forwarded to a `Gap(gapStyle: …)`
///   rendered between every adjacent sibling pair inside the chip
///   (matching the Flutter widget — single source of horizontal gap).
///   [clickableStyle] is forwarded to the `Clickable` composed around
///   a tappable chip.
///
/// No scalar metadata (chipColor / size / enabled) is
/// exposed — semantic identifiers stay on the widget prop and behaviour
/// flags pass through `co_chip` directly.
class ResolvedChip implements WebResolvedChrome {
  /// Creates a [ResolvedChip].
  const ResolvedChip({
    required this.root,
    required this.label,
    required this.prefixLabel,
    required this.leading,
    required this.trailing,
    required this.closeButton,
    required this.iconLabelGapStyle,
    required this.leadingIconStyle,
    required this.trailingIconStyle,
    required this.closeIconStyle,
    required this.closeButtonStyle,
    required this.clickableStyle,
  });

  /// Paint-ready chrome for the outer chip `<div>` element.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the default label `<span>` — `co_chip`
  /// renders this element only when `child == null && label != null`.
  final WebElementChrome label;

  /// Paint-ready chrome for the key `<span>` in front of the label —
  /// `co_chip` renders this element only when `prefixLabel != null`. It
  /// carries its own role class and colour (at rest the key reads its own
  /// column, which the root's label colour it would otherwise inherit does
  /// not follow) and holds one line
  /// at full width, so the label is the half that truncates.
  final WebElementChrome prefixLabel;

  /// Paint-ready chrome for the leading slot wrapper — `co_chip`
  /// renders this element only when `leading != null`. The wrapper is
  /// `inline-flex` so it acts as the icon row item.
  final WebElementChrome leading;

  /// Paint-ready chrome for the trailing slot wrapper — `co_chip`
  /// renders this element only when `trailing != null`.
  final WebElementChrome trailing;

  /// Paint-ready chrome for the close button wrapper — `co_chip`
  /// renders this element only when `onRemove != null && enabled`.
  /// The actual `<button>` chrome is owned by the nested `Button`
  /// via [closeButtonStyle]; this wrapper is a flex item that
  /// participates in the row layout.
  final WebElementChrome closeButton;

  /// Nested [CoreGapStyle] slot forwarded to `Gap(gapStyle: …)`
  /// rendered between every adjacent sibling pair inside the chip —
  /// `leading ↔ label`, `label ↔ trailing`, `trailing ↔ closeButton`.
  /// Mirrors the Flutter widget's per-side `Gap` insertions so the
  /// nested slot is the **single source** of horizontal gap (no inline
  /// `gap` CSS on the root).
  final CoreGapStyle iconLabelGapStyle;

  /// Nested [CoreIconStyle] slot `co_chip` hands the `leading` slot as
  /// its nearest `IconTheme`, so a caller-supplied `Icon` with no size of
  /// its own takes the resolved icon size and (when overridden) colour.
  final CoreIconStyle leadingIconStyle;

  /// Nested [CoreIconStyle] slot `co_chip` hands the `trailing` slot as
  /// its nearest `IconTheme`, with the same size and colour rules as
  /// [leadingIconStyle].
  final CoreIconStyle trailingIconStyle;

  /// Nested [CoreIconStyle] slot forwarded to the X icon inside the
  /// `onRemove` close button.
  final CoreIconStyle closeIconStyle;

  /// Nested [CoreButtonStyle] slot forwarded to `Button(buttonStyle:
  /// …)` for the `onRemove` close button. `null` → Button uses its
  /// own design-system defaults.
  final CoreButtonStyle? closeButtonStyle;

  /// Nested [CoreClickableStyle] slot for the `Clickable` `co_chip`
  /// composes around a tappable (`onTap != null`) chip —
  /// `CoreChipStyle.defaultClickableStyle` (which keeps the
  /// Clickable's generic disabled fade off because the chip paints its
  /// own disabled tokens) with the face's corner (so the focus ring
  /// follows the corner the face is drawn with — the size row's, or the
  /// pill's) merged with the per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedChip] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreChipStyle.defaultsBySize[size]
///                        → CoreChipStyle.defaultsByShape[shape])
///   → theme.coreComponentTheme.chip.style
///   → theme.coreComponentTheme.chip.colorStyles[chipColor]
///   → theme.coreComponentTheme.chip.variantStyles[variant]
///   → widget.chipStyle
/// ```
///
/// Semantic identifiers (`chipColor` / `variant` / `size` / `shape`) are
/// widget props — they thread through to pick the per-size and per-shape
/// default style entries, the per-colour table row and the unselected fill
/// here. The theme cannot override them (Epic #1603 옵션 B 최종).
///
/// [shape] defaults to [CoreChipShape.defaultShape], so a caller that
/// predates the shape axis resolves the corner it always did.
///
/// State branches (`enabled` / `selected` / `seedColor`) shape the
/// chrome classes / inline CSS — they are resolver parameters so the
/// widget hands its state once and receives paint-ready output.
///
/// [labelMaxLines] / [labelOverflow] are the caller's label clamp. They
/// reach the resolver because the default clamp is a Tailwind utility
/// (`truncate`, which also pins `white-space: nowrap`) while an override
/// is inline CSS the `Text` emits — and the two cannot both be on the
/// element, or `nowrap` would win and the override would draw one line.
/// Both `null` is the shape this component has always drawn, and emits
/// the identical class list it always did.
ResolvedChip resolveChip(
  BuildContext context, {
  required CoreChipColor chipColor,
  required CoreChipVariant variant,
  required CoreChipSize size,
  required bool selected,
  required CoreChipEmphasis emphasis,
  required bool enabled,
  CoreChipShape shape = CoreChipShape.defaultShape,
  CoreColor? seedColor,
  CoreChipStyle? chipStyle,
  int? labelMaxLines,
  CoreTextOverflow? labelOverflow,
}) {
  final csTheme = context.theme.coreComponentTheme?.chip;

  // ─── Merge chain ──────────────────────────────────────
  // defaultsBySize entry is the design-system base — folded onto an
  // empty `CoreChipStyle()` head so per-instance overrides win over it
  // (the empty head also keeps the resolved-chrome surface keyed on
  // `CoreChipStyle`, matching the card exemplar). The shape's row lays
  // over the size row: `rounded` states nothing and keeps the row's
  // corner, `pill` states the full corner — and a corner the theme or the
  // instance states still wins over both (mirrors the Flutter resolver).
  final sizeDefault = CoreChipStyle.defaultsBySize[size]!;
  final merged = resolveStyleChain(
    const CoreChipStyle()
        .merge(sizeDefault)
        .merge(CoreChipStyle.defaultsByShape[shape]),
    [
      csTheme?.style,
      csTheme?.colorStyles?[chipColor],
      csTheme?.variantStyles?[variant],
      chipStyle,
    ],
  );

  // What this chip wants its cast to *do*. `noShadow` withholds the
  // cast and its paired travel outright — both markers go with it: the
  // rest marker is how a chip takes the style's cast at all, and the
  // press marker is the paired travel, which has nothing to move into
  // once the cast is gone. `reverse` keeps the injected cast but hides
  // it at rest instead of at engage, and travels the opposite diagonal —
  // it takes a different path than the marker-class one below (see
  // `isReverse`), because the rest marker's global rule always points at
  // the *real* cast, never a hidden one.
  final chipCastMotion = merged.castMotion ?? CoreChipStyle.defaultCastMotion;
  final castsNever = chipCastMotion == .noShadow;
  // Chip has no authored-shadow slot (unlike Button), so this is a
  // direct read of `castMotion` — nothing to gate on.
  final isReverse = chipCastMotion == .reverse;

  // ─── Token tables ─────────────────────────────────────
  final colorStyle =
      CoreChipStyle.defaultsByColor[chipColor] ??
      CoreChipStyle.defaultsByColor[CoreChipColor.neutral]!;

  // ─── Resolved chrome values ───────────────────────────
  // Every value finished its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly).
  final padding = merged.padding ?? CoreEdgeInsets.zero;
  // Every size row states the floor; `0` is the no-floor fallback for a
  // caller who passes a style with neither (same shape as `padding`).
  final minHeight = merged.minHeight ?? 0;
  // Where the content row sits when the chip is drawn wider than it —
  // the Flutter twin's `Row.mainAxisAlignment`.
  final contentJustify =
      (merged.contentAlignment ?? CoreChipStyle.defaultContentAlignment)
          .tailwindJustify;
  // Nested CoreGapStyle slot — merge the per-size default with the
  // per-instance override and forward (pre-scaling) to a `Gap`
  // rendered between adjacent sibling pairs in `co_chip.dart`. `Gap`
  // runs its own resolve / scaling step. No inline `gap` CSS on the
  // root — the nested slot is the single source of horizontal gap.
  final iconLabelGapStyle = sizeDefault.iconLabelGapStyle!.merge(
    merged.iconLabelGapStyle,
  );
  // Border radius is **always** emitted inline (`.toValue()` of the
  // caller's corner, else the shape's — the size row's for `rounded`, the
  // full rung for `pill`) — no radius Tailwind class. Default and override
  // share this one CSS surface so the resolved chrome reflects
  // `merged.borderRadius` directly. The pill goes out as
  // `var(--coui-radius-9999)` on every corner and the browser scales
  // corners that overlap until they fit — half the box's shorter side, the
  // height on a chip (CSS Backgrounds 3, "Overlapping Curves") — so each
  // end draws a half circle, and a chip that grows past its floor stays
  // one. No resolver computes `height / 2`. The corner stays a Core value
  // here: the focus ring (the composed `Clickable`) follows it too.
  final borderRadius = merged.borderRadius ?? sizeDefault.borderRadius!;
  // State-transition duration — `(merged ?? default)` so a per-instance
  // override wins; emitted as an inline `transition` rule (Epic #1603
  // chaining gate — `transitionDuration` is reflected here).
  final transitionDurationMs =
      (merged.transitionDuration ?? CoreChipStyle.defaultTransitionDuration)
          .inMilliseconds;
  // The engage-squash pair's clock — see [kControlEngageDurationVar] /
  // `ThemeConfig._controlShadowPressRule`'s doc comment (#4407).
  // Deliberately not `transitionDurationMs` — that is the hover/selected
  // speed, and hiding the cast on it would lag the travel.
  final castHideDurationMs =
      (merged.castHideDuration ?? CoreChipStyle.defaultCastHideDuration)
          .inMilliseconds;

  // Nested icon style slots — each design-system size default supplies
  // a populated CoreIconStyle that has already been folded into
  // `merged`, so the resolved slot is non-null after the chain merge.
  final leadingIconStyle = merged.leadingIconStyle ?? const CoreIconStyle();
  final trailingIconStyle = merged.trailingIconStyle ?? const CoreIconStyle();
  final closeIconStyle = merged.closeIconStyle ?? const CoreIconStyle();

  // ─── Variant state base colours ───────────────────────
  // Pick the [CoreColor] base for each surface from the per-state branch
  // (`enabled` / `selected` / custom-seed). These are platform-neutral
  // `CoreColor`s only — never `cs.<token>` directly — so every value
  // flows through `CoreChipStyle.default*` / the per-variant table
  // (layer-mapping.md single-source). The custom-seed branch carries the
  // raw `seedColor` (`token == null`), which `emitColor` routes inline.
  // The fill an unselected, enabled chip wears at `filled` — one grey for
  // every colour, and the border mirrors it (no outline), the way a selected
  // chip's border mirrors its own fill. Meaningless for a selected or a
  // disabled chip, which ignore `variant`.
  final filledFill =
      merged.filledUnselectedBackgroundColor ??
      CoreChipStyle.defaultFilledUnselectedBackgroundColor;
  final filled = variant == .filled;
  final CoreColor bgBase;
  final CoreColor fgBase;
  final CoreColor borderBase;
  // The key in front of the label (`prefixLabel`). Only a resting chip
  // gives it an ink of its own (`CoreChipColorStyle.unselectedPrefixFg` —
  // quieter than the high label, the same as the low one); selected and
  // disabled chips draw it in the label's colour.
  final CoreColor prefixBase;

  // A custom seed speaks only when the chip is selected: an unselected
  // chip states no colour, so an enabled one falls through to the
  // neutral table row below like every other colour (a raw seed cannot
  // promise contrast on the surface behind it, either).
  if (chipColor == .custom && seedColor != null && (selected || !enabled)) {
    if (!enabled) {
      // Disabled drops the seed entirely. Two rows, like the table
      // below (see its comment for why the selected row's border is
      // stated as transparent rather than as the fill colour).
      bgBase = selected
          ? merged.customDisabledBackgroundColor ??
                CoreChipStyle.defaultCustomDisabledBackgroundColor
          : merged.customDisabledUnselectedBackgroundColor ??
                CoreChipStyle.defaultCustomDisabledUnselectedBackgroundColor;
      fgBase =
          merged.customDisabledForegroundColor ??
          CoreChipStyle.defaultCustomDisabledForegroundColor;
      borderBase = selected
          ? merged.disabledSelectedBorderColor ??
                CoreChipStyle.defaultDisabledSelectedBorderColor
          : merged.customDisabledBorderColor ??
                CoreChipStyle.defaultCustomDisabledBorderColor;
    } else if (selected && emphasis == .low) {
      // A raw seed has no container token to tint from — see
      // `CoreChipStyle.defaultCustomLowSelectedBackgroundColor`.
      bgBase =
          merged.customLowSelectedBackgroundColor ??
          CoreChipStyle.defaultCustomLowSelectedBackgroundColor;
      fgBase =
          merged.customLowSelectedForegroundColor ??
          CoreChipStyle.defaultCustomLowSelectedForegroundColor;
      borderBase = bgBase;
    } else {
      // Selected + high — the only row left in this block.
      bgBase = seedColor;
      // The seed's own on-colour — a paired token emits as a class, a raw
      // seed's measured end inline (Core decides, so Flutter agrees).
      fgBase =
          merged.customSelectedForegroundColor ??
          CoreChipStyle.defaultCustomSelectedForegroundColorFor(seedColor);
      borderBase = seedColor;
    }
    // Selected or disabled — the only states this block is entered for.
    prefixBase = fgBase;
  } else {
    if (!enabled) {
      // Two disabled rows: selected keeps a filled container with a
      // transparent border (`defaultDisabledSelectedBorderColor` — see
      // its doc comment: `buildRootInlineStyles` collapses a transparent
      // border's width out of layout, so this reads as "no border" rather
      // than "border == fill"), unselected sits on the surface behind a
      // hairline. Branching on `selected` here is what lets a disabled
      // palette still show which chip was picked.
      bgBase = selected ? colorStyle.disabledSelectedBg : colorStyle.disabledBg;
      fgBase = colorStyle.disabledFg;
      borderBase = selected
          ? merged.disabledSelectedBorderColor ??
                CoreChipStyle.defaultDisabledSelectedBorderColor
          : colorStyle.disabledBorderColor;
      prefixBase = fgBase;
    } else if (selected) {
      // Selected border mirrors the selected background (legacy parity),
      // at either volume.
      bgBase = emphasis == .low
          ? colorStyle.lowSelectedBg
          : colorStyle.selectedBg;
      fgBase = emphasis == .low
          ? colorStyle.lowSelectedFg
          : colorStyle.selectedFg;
      borderBase = bgBase;
      prefixBase = fgBase;
    } else {
      // An unselected chip states no colour: the label is neutral at either
      // volume (darker at high) on a quiet hairline. `filled` swaps the
      // transparent fill and the hairline for the grey fill and its mirror.
      bgBase = filled ? filledFill : colorStyle.unselectedBg;
      fgBase = emphasis == .low
          ? merged.lowUnselectedForegroundColor ?? colorStyle.lowUnselectedFg
          : colorStyle.unselectedFg;
      borderBase = filled
          ? filledFill
          : emphasis == .low
          ? merged.lowUnselectedBorderColor ??
                CoreChipStyle.defaultLowUnselectedBorderColor
          : colorStyle.borderColor;
      prefixBase = colorStyle.unselectedPrefixFg;
    }
  }

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Each colour / typography value routes through the emit family — a
  // single class-XOR-inline decision per design value. Token-bound bases
  // (variant table, a paired seed's on-colour) emit Tailwind classes
  // (dark-mode reactive); raw bases (a raw seed and its measured label)
  // and raw overrides publish an inline var(state, exactBase) background
  // plus canonical state values. No `scheme.resolve` (a no-op on Web). The raw
  // transparent base keeps its exact `.toValue()` see-through rest fill;
  // it no longer blocks the body's ordinary state-colour declarations.
  final backgroundEmit = emitColor(merged.backgroundColor, bgBase, .background);
  // Whether this chip states a real fill right now — the custom-seed
  // unselected branch and a caller override can both resolve to the
  // shared `CoreColor.transparent` sentinel above. A chip with no fill
  // never declared itself a surface, so the active preset's material
  // has nothing to blend under it and would blur a see-through pill
  // (`core/theme-axis-composition.md` — "표면 처리는 표면이 자기를
  // 표면으로 말할 때만 닿는다"). Gates the surface marker below the
  // same way `resolveOutlinedContainer` gates `surfaceBlur`.
  final resolvedBackground = merged.backgroundColor ?? bgBase;
  final hasFill = resolvedBackground != .transparent;
  final foregroundEmit = emitColor(merged.foregroundColor, fgBase, .text);
  final ownedBaseCss = backgroundEmit.inline?['background-color'];
  final resolvedForeground = merged.foregroundColor ?? fgBase;
  final stateLayer = merged.stateLayer ?? CoreChipStyle.defaultStateLayer;
  final ownedFillValues = ownedBaseCss == null
      ? const <String, String>{}
      : <String, String>{
          'background-color': 'var($_kChipStateFillVar, $ownedBaseCss)',
          _kChipHoverFillVar: stateLayerWashCss(
            ink: resolvedForeground,
            base: resolvedBackground,
            weight: stateLayer.hover,
          ),
          _kChipFocusFillVar: stateLayerWashCss(
            ink: resolvedForeground,
            base: resolvedBackground,
            weight: stateLayer.focus,
          ),
          _kChipPressedFillVar: stateLayerWashCss(
            ink: resolvedForeground,
            base: resolvedBackground,
            weight: stateLayer.pressed,
          ),
        };
  // Close-button chrome — bind the chip foreground as the button's idle
  // foreground base so the X glyph (currentColor) tracks the chip
  // colours; hover / per-instance overrides keep flowing through the
  // Button's own per-state classes (mirrors the Flutter resolver).
  final closeButtonStyle = CoreChipStyle.defaultCloseButtonStyle
      .merge(CoreButtonStyle(foregroundColor: resolvedForeground))
      .merge(sizeDefault.closeButtonStyle)
      .merge(merged.closeButtonStyle);
  final borderEmit = emitColor(merged.borderColor, borderBase, .border);
  // A fully transparent resolved border collapses its width to 0 so it
  // stays out of layout — the rule `resolveOutlinedContainer` applies on
  // both platforms, and the Flutter chip composes that container, so a
  // `border-color: transparent` left at width 1 would make this pill 1px
  // wider per side than its Flutter twin (the selected disabled row is
  // where it happens). Read off the raw alpha byte, not the emit family:
  // a raw seed border is token-less too and must keep its hairline.
  final resolvedBorder = merged.borderColor ?? borderBase;
  final borderIsTransparent =
      resolvedBorder.token == null && ((resolvedBorder.argb >> 24) & 0xFF) == 0;
  final borderWidth = borderIsTransparent ? 0.0 : merged.borderWidth;

  // ─── Label typography ─────────────────────────────────
  // Each size row states its own label ROLE (`labelSmall` / `labelMedium`
  // / `labelLarge`, `CoreChipStyle.defaultsBySize`), carried by the
  // token-backed `merged.labelStyle`; any caller overlay layers on top.
  // `emitTypography` is the single canonical path: it emits the role on a
  // `text-{role}` class (dark-mode / accessibility-scale reactive,
  // inherited by the inner `<span>`) AND any explicit scalar overlay
  // (`font-size` / weight / spacing) inline. The fallback default merges
  // the size row's role over `defaultLabelStyle` so a caller who passes a
  // role-less `labelStyle` still lands on the size's role rather than on
  // the ladder's base. No hand-rolled `text-${...token!.name}`.
  final labelEmit = emitTypography(
    merged.labelStyle,
    CoreChipStyle.defaultLabelStyle.merge(sizeDefault.labelStyle),
  );

  // ─── Key typography + colour ──────────────────────────
  // Same single path as the label: the size row's key role
  // (`labelXs` / `labelSmall` / `labelMedium`) on a `text-{role}` class, any
  // caller overlay inline. The fallback merges the row's role over
  // `defaultPrefixLabelStyle` for the same reason the label's does.
  final prefixEmit = emitTypography(
    merged.prefixLabelStyle,
    CoreChipStyle.defaultPrefixLabelStyle.merge(sizeDefault.prefixLabelStyle),
  );
  // The key's colour follows the label's precedence: its own slot colour
  // (already carried by [prefixEmit]), else the `foregroundColor` escape
  // hatch, else its state base. Stated on the key's own `<span>` because a
  // resting key reads its own column, not the root's label colour it would
  // otherwise inherit.
  final prefixColorEmit = merged.prefixLabelStyle?.color != null
      ? null
      : emitColor(merged.foregroundColor, prefixBase, .text);

  // ─── Local builders ───────────────────────────────────

  /// Composes the chip `<div>` Tailwind className — inline-flex chrome,
  /// border, label typography role class ([labelEmit] — inherited by the
  /// inner `<span>`), and the variant colour classes (from the
  /// [emitColor] results, token values only). Interaction chrome
  /// (cursor / focus ring / press) is owned by the composing
  /// `Clickable`. Border radius and the state transition are emitted
  /// inline (single-signature gate); raw colour overrides emit inline
  /// (empty class fragment here).
  String buildRootClassName() {
    return <String>[
      WebLayout.inlineFlexItemsCenter,
      contentJustify,
      // #4362 — marks this chip as a component surface so the active
      // preset's material (backdrop-blur) reaches it (`webSurfaceMarkerFor`,
      // the `alert`/`banner` fallback — literal `OutlinedContainer`
      // composition would out-rank the press/hover cast markers just
      // below on the same `box-shadow` property, so the marker is
      // restated here instead). Gated on [hasFill] — a chip with no
      // fill never declared itself a surface.
      if (hasFill) ...webSurfaceMarkerFor(.content),
      // States no shadow of its own, so it takes the style's — the
      // Flutter twin reads the same cast.
      // Withheld when the chip asks for no cast — the marker *is* how a
      // chip takes the style's cast, so dropping it is how it declines.
      // Also withheld for `reverse`: this marker's global rule
      // (`kControlShadowRestMarker`'s doc comment) always points the
      // *rest* box-shadow at the real cast, and a `reverse` chip's rest
      // value is the ghost twin instead — `buildRootInlineStyles` states
      // that inline rather than through this class.
      if (!castsNever && !isReverse) kControlShadowRestMarker,
      // Press-squash affordance: the pill travels into the space its
      // cast held while the cast hides, on the style's own offsets. The
      // marker alone does nothing — the effect is the style-scoped rule
      // named in `kControlShadowPressMarker`'s doc comment, and it is a
      // genuine no-op under styles that publish no offsets.
      //
      // It also takes the chip's `transition` over: that rule is the
      // sole transition declaration a marked control may have, which is
      // why the chrome clock now travels as `kControlChromeDurationVar`
      // in the inline bundle instead of as an inline `transition`.
      //
      // Gated on `enabled`, and the gate is not optional here the way it
      // is for a button. `:active` is a browser state, not a handler: it
      // fires on whatever the pointer is pressing regardless of what the
      // element listens for. A native `<button disabled>` is exempt
      // because the browser suppresses it — this pill is a `<div>`, so
      // nothing suppresses it and a disabled chip would squash under the
      // cursor while its Flutter twin, which gates on the same flag, sat
      // still.
      if (enabled && !castsNever) kControlShadowPressMarker,
      // 가용 폭에 클램프 — 좁은 컨테이너에서 라벨이 말줄임(truncate)
      // 되도록. Flutter 의 Flexible 라벨(ellipsis)과 동일 동작.
      WebLayout.maxWFull,
      'border',
      backgroundEmit.className,
      foregroundEmit.className,
      labelEmit.className,
      borderEmit.className,
    ].where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the chip `<div>` inline CSS — runtime padding /
  /// border-radius / state transition plus the emit-family inline colour
  /// fragments (raw seed / white-label / raw overrides only — token
  /// values stay on classes) and the per-instance border-width override.
  /// Horizontal gap between siblings is rendered as explicit `Gap`
  /// widgets in `co_chip.dart` — not inline CSS.
  Styles buildRootInlineStyles() {
    final borderWidthCss = borderWidth == null
        ? null
        : strokeWidthCss(borderWidth);
    // Token-routed duration so the reduced-motion / easing-override
    // machinery in `theme_config.dart` reaches this transition (see
    // `durationMsCss` docs).
    final transitionDurationCss = durationMsCss(transitionDurationMs);
    final transitionEasingCss = CoreEasing.move.toVarCss();
    return Styles(
      raw: {
        'padding': padding.toValue(),
        // The size tier's height floor — same rem scale as the padding so
        // it follows the browser's text setting the way Flutter's
        // `theme.scaling` does.
        'min-height': '${minHeight / kRemDivisor}rem',
        // Border radius is always inline — `.toValue()` of the caller's
        // corner else the shape's, composed above. Default and override
        // share this one surface.
        'border-radius': borderRadius.toValue(),
        // #4362 — publishes the fill this pill actually chose, the same
        // way `OutlinedContainer` does, so a style preset can restate it
        // at a different alpha without knowing which token/raw colour it
        // was. Only meaningful alongside the surface marker above, so
        // gated on the same [hasFill].
        if (hasFill) ...surfaceFillVar(resolvedBackground),
        // `reverse`'s rest value — the same-shape, zero-alpha twin of
        // the injected cast (`kControlShadowGhostVar`) rather than
        // leaving `box-shadow` unstated (which would resolve to the
        // literal initial value `none`). Stated inline instead of the
        // `kControlShadowRestMarker` class withheld above, so the
        // transition to the full-alpha value at engage stays a pure
        // colour interpolation instead of risking a mismatched-layer
        // -count flash (`process/verify.md` §7-24). No rim beside it: the
        // ghost is the style's cast, not one this pill authored, and a rim
        // decorates a surface that casts its own shadow — the Flutter twin
        // hands its `OutlinedContainer` an explicitly empty stack, so it
        // never draws one. The rim here lit a reverse pill under
        // claymorphism on this platform alone, and made the rest value one
        // layer longer than the engaged one it transitions to.
        if (isReverse) 'box-shadow': kControlShadowGhostVar,
        // Who owns `transition` follows who carries the press marker, and
        // the two must not both speak.
        //
        // Enabled: the marker rule owns this element's only `transition`
        // and states both halves (press pair + chrome group) in one
        // shorthand, so the clock travels as a value. An inline
        // `transition` here would outrank that rule and silently drop the
        // press half, leaving the travel to snap.
        //
        // Disabled: no marker, so no rule is stating a transition and the
        // chrome group would simply have none. The chip states its own —
        // it can still change (a caller flipping `selected`), and that
        // change should fade the way it does when enabled.
        if (enabled) kControlChromeDurationVar: transitionDurationCss,
        // Engage-squash clock override — read by the same shared rule's
        // press pair. Gated the same as the chrome clock above: only
        // relevant while the marker (and so the shared `transition`
        // declaration reading it) is actually carried.
        if (enabled)
          kControlEngageDurationVar: durationMsCss(castHideDurationMs),
        if (!enabled)
          'transition':
              'background-color $transitionDurationCss $transitionEasingCss, '
              'color $transitionDurationCss $transitionEasingCss, '
              'border-color $transitionDurationCss $transitionEasingCss',
        // Duplicated into a variable so the press rule's `:active` has
        // something to fall back to under a style that publishes no press
        // shadow — same reason the button resolver does it. The chip's
        // rest shadow is the marker's `var(--coui-control-shadow)`, or
        // its ghost twin for `reverse` (unused there in practice — see
        // below — but kept in sync with the inline `box-shadow` above).
        if (enabled)
          '--coui-button-rest-shadow': isReverse
              ? kControlShadowGhostVar
              : kControlShadowVar,
        // `reverse`'s engage half — grows the cast instead of hiding it,
        // and travels the opposite diagonal. This element's own inline
        // declarations for the exact custom properties the global
        // `ThemeConfig._controlShadowPressRule` reads outrank the
        // inherited style-scoped values regardless of specificity, so a
        // `reverse` chip diverges from a `defaultMotion` sibling under
        // the identical style — mirrors the button resolver's identical
        // override. `var(…, none)` / `var(…, 0px)` fallbacks keep this a
        // no-op under a style that states no `shadowOffsetAdd`.
        if (isReverse && enabled) ...{
          '--coui-control-shadow-press': 'var(--coui-control-shadow, none)',
          '--coui-control-shadow-offset-x':
              'var(--coui-control-shadow-offset-x-reverse, 0px)',
          '--coui-control-shadow-offset-y':
              'var(--coui-control-shadow-offset-y-reverse, 0px)',
        },
        // Emit-family inline fragments (raw colour bases / overrides only —
        // token values stay on classes and contribute nothing here).
        ...ownedFillValues,
        ...?foregroundEmit.inline,
        ...?borderEmit.inline,
        'border-width': ?borderWidthCss,
        // The `border` class carries a 1px line the chip always keeps; the
        // material's edge band reaches over it (transparent under a style
        // that draws its own edge), not inside it.
        if (hasFill)
          ...surfaceBleedVar(
            borderWidthCss ?? strokeWidthCss(CoreChipStyle.defaultBorderWidth),
          ),
      },
    );
  }

  /// Composes the label `<span>` Tailwind className — truncation plus
  /// the label typography role / colour classes. The label classes live
  /// on the `<span>` (not the root) so a `labelStyle.color` slot wins
  /// over the root's foreground class deterministically (direct
  /// application beats inheritance — mirrors Flutter's "slot colour
  /// override else foreground" precedence); without a slot colour the
  /// span inherits the root foreground.
  String buildLabelClassName() => <String>[
    WebLayout.minWZero,
    // Dropped when the caller states its own clamp — the `Text` then
    // carries it as inline CSS, and `truncate`'s `nowrap` would pin the
    // result to one line however many the caller asked for.
    if (labelMaxLines == null && labelOverflow == null) WebLayout.truncate,
    'text-inherit',
    labelEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the label `<span>` inline CSS — the explicit typography
  /// overlay (`font-size` / weight / line-height / spacing / raw colour)
  /// emitted by [labelEmit] on top of the role class. The role itself
  /// stays on the root `<div>` className (inherited by this `<span>`).
  /// Returns `null` when the merged label style is a pure role with no
  /// overlay.
  Styles? buildLabelInlineStyles() {
    final inline = labelEmit.inline;
    return inline == null ? null : Styles(raw: inline);
  }

  /// Composes the key `<span>` Tailwind className — it never shrinks and
  /// never wraps (the label beside it is the half that truncates), plus its
  /// own role and colour classes.
  String buildPrefixLabelClassName() => <String>[
    WebLayout.shrinkZero,
    WebLayout.whitespaceNowrap,
    prefixEmit.className,
    ?prefixColorEmit?.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the key `<span>` inline CSS — any explicit typography overlay
  /// and a raw (token-less) colour. `null` for a pure role in a token
  /// colour.
  Styles? buildPrefixLabelInlineStyles() {
    final inline = {...?prefixEmit.inline, ...?prefixColorEmit?.inline};
    return inline.isEmpty ? null : Styles(raw: inline);
  }

  /// Composes the leading slot wrapper Tailwind className.
  String buildLeadingClassName() =>
      '${WebLayout.inlineFlex} ${WebLayout.itemsCenter} '
      '${WebLayout.shrinkZero}';

  /// Composes the trailing slot wrapper Tailwind className.
  String buildTrailingClassName() =>
      '${WebLayout.inlineFlex} ${WebLayout.itemsCenter} '
      '${WebLayout.shrinkZero}';

  /// Composes the close-button wrapper Tailwind className. The actual
  /// `<button>` chrome lives inside the nested `Button`; this wrapper
  /// is a flex item that participates in the row layout.
  String buildCloseButtonClassName() =>
      '${WebLayout.inlineFlex} ${WebLayout.itemsCenter} '
      '${WebLayout.shrinkZero}';

  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest).
  final clickableStyle = CoreChipStyle.defaultClickableStyle
      .merge(CoreClickableStyle(borderRadius: borderRadius))
      .merge(merged.clickableStyle);

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedChip(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    label: WebElementChrome(
      className: buildLabelClassName(),
      inlineStyles: buildLabelInlineStyles(),
    ),
    prefixLabel: WebElementChrome(
      className: buildPrefixLabelClassName(),
      inlineStyles: buildPrefixLabelInlineStyles(),
    ),
    leading: WebElementChrome(className: buildLeadingClassName()),
    trailing: WebElementChrome(className: buildTrailingClassName()),
    closeButton: WebElementChrome(className: buildCloseButtonClassName()),
    iconLabelGapStyle: iconLabelGapStyle,
    leadingIconStyle: leadingIconStyle,
    trailingIconStyle: trailingIconStyle,
    closeIconStyle: closeIconStyle,
    closeButtonStyle: closeButtonStyle,
    clickableStyle: clickableStyle,
  );
}

// ═══════════════════════════════════════════════════
// State layer — scoped pseudo-state rules
// ═══════════════════════════════════════════════════

/// Marker class on the chip's paint root (`chipBody` in `chip.dart`) — the
/// scoped rules below select through it with a `>` child combinator,
/// since `:hover` / `:focus-visible` / `:active` land on the `Clickable`
/// root (the actual focusable, tabindex-bearing element) and `chipBody`
/// is a plain nested `<div>` that never receives focus or press itself.
///
/// Stable and unconditional — like `Clickable`'s own `kWebTouchTargetMarker`
/// — rather than content-addressed, because it only ever needs to be
/// reachable from the sibling `<style>` block's `>` selector, never
/// unique across instances.
const kChipBodyMarker = 'co-chip-body';

/// Scoped CSS text plus the class it is keyed to, for the `<style>` block
/// and the `Clickable` root's classList in `chip.dart`.
///
/// Both empty when the chip states no ramp or is disabled (a disabled
/// chip's rest chrome IS its disabled chrome — nothing to wash toward).
class ResolvedChipRules {
  /// Creates a [ResolvedChipRules].
  const ResolvedChipRules({required this.scopeClass, required this.css});

  /// Class the `Clickable` root wears, and the class the CSS text below
  /// selects on. Empty exactly when [css] is empty — the pair travels
  /// together, never one without the other.
  final String scopeClass;

  /// Raw CSS rule text — empty on the disabled / no-ramp path.
  final String css;
}

/// Resolves the state-layer rules for one chip instance.
///
/// Re-walks the same merge chain and bg/fg resolution [resolveChip] runs
/// — the chrome composed there and the rules composed here have to see
/// the same resolved values, or the chip emits a class the rules don't
/// match (or a rule the class never triggers). That includes the shape's
/// row in the chain head: no rule here reads the corner, but a shape row
/// that ever stated a fill or a state layer would otherwise wash a base
/// the face does not wear.
ResolvedChipRules resolveChipRules(
  BuildContext context, {
  required CoreChipColor chipColor,
  required CoreChipVariant variant,
  required CoreChipSize size,
  required bool selected,
  required CoreChipEmphasis emphasis,
  required bool enabled,
  CoreChipShape shape = CoreChipShape.defaultShape,
  CoreColor? seedColor,
  CoreChipStyle? chipStyle,
}) {
  if (!enabled) return const ResolvedChipRules(scopeClass: '', css: '');

  final csTheme = context.theme.coreComponentTheme?.chip;
  final sizeDefault = CoreChipStyle.defaultsBySize[size]!;
  final merged = resolveStyleChain(
    const CoreChipStyle()
        .merge(sizeDefault)
        .merge(CoreChipStyle.defaultsByShape[shape]),
    [
      csTheme?.style,
      csTheme?.colorStyles?[chipColor],
      csTheme?.variantStyles?[variant],
      chipStyle,
    ],
  );
  final colorStyle =
      CoreChipStyle.defaultsByColor[chipColor] ??
      CoreChipStyle.defaultsByColor[CoreChipColor.neutral]!;

  // Same fill `resolveChip` paints — the rules wash toward whatever the
  // chip actually wears, so the two must read the same value.
  final filledFill =
      merged.filledUnselectedBackgroundColor ??
      CoreChipStyle.defaultFilledUnselectedBackgroundColor;
  final filled = variant == .filled;
  final CoreColor bgBase;
  final CoreColor fgBase;
  // Same split as [resolveChip]: a custom seed speaks only when selected;
  // an unselected one takes the neutral row below.
  if (chipColor == .custom && seedColor != null && selected) {
    if (emphasis == .low) {
      bgBase =
          merged.customLowSelectedBackgroundColor ??
          CoreChipStyle.defaultCustomLowSelectedBackgroundColor;
      fgBase =
          merged.customLowSelectedForegroundColor ??
          CoreChipStyle.defaultCustomLowSelectedForegroundColor;
    } else {
      bgBase = seedColor;
      fgBase =
          merged.customSelectedForegroundColor ??
          CoreChipStyle.defaultCustomSelectedForegroundColorFor(seedColor);
    }
  } else if (selected) {
    bgBase = emphasis == .low
        ? colorStyle.lowSelectedBg
        : colorStyle.selectedBg;
    fgBase = emphasis == .low
        ? colorStyle.lowSelectedFg
        : colorStyle.selectedFg;
  } else {
    bgBase = filled ? filledFill : colorStyle.unselectedBg;
    fgBase = emphasis == .low
        ? merged.lowUnselectedForegroundColor ?? colorStyle.lowUnselectedFg
        : colorStyle.unselectedFg;
  }

  final base = merged.backgroundColor ?? bgBase;
  final ink = merged.foregroundColor ?? fgBase;
  final layer = merged.stateLayer ?? CoreChipStyle.defaultStateLayer;

  // Content-addressed off the exact values the rules below depend on —
  // two chips (or a whole `ChipGroup` of unselected ones) that resolve
  // identically share one class and one rule instead of emitting a
  // duplicate per instance.
  final seed =
      '${ink.token?.name}|${ink.argb}|${base.token?.name}|${base.argb}'
      '|${base.opacity}|${layer.hover}|${layer.focus}|${layer.pressed}';
  final scopeClass =
      'co-chip-sl-${seed.hashCode.toRadixString(36).replaceAll('-', 'n')}';

  // Base keeps its own alpha (it is literally what is painted at rest —
  // `transparent` included, via `.toValue()`'s raw-colour fallback).
  final baseCss = base.toValue();
  // Ink drops its own alpha — the state-layer WEIGHT is what governs the
  // blend ratio below, not whatever alpha the ink happened to carry.
  final inkToken = ink.token?.name;
  final inkCss = inkToken != null
      ? 'rgb(var(--coui-$inkToken))'
      : 'rgb(${ink.red}, ${ink.green}, ${ink.blue})';

  String wash(double weight) =>
      'color-mix(in srgb, $inkCss ${(weight * 100).round()}%, $baseCss)';

  final scope = '.$scopeClass';
  // hover → focus → pressed, so equal-specificity ties resolve to the
  // later rule — a focused chip that is then hovered must not step DOWN
  // to the hover weight. `>` reaches `chipBody` (child), not the scope
  // element itself, because the pseudo-classes land on the Clickable
  // root and the chrome being washed lives one level in.
  final rawBase = base.token == null;
  final hoverFillCss = rawBase ? 'var($_kChipHoverFillVar)' : wash(layer.hover);
  final focusFillCss = rawBase ? 'var($_kChipFocusFillVar)' : wash(layer.focus);
  final pressedFillCss = rawBase
      ? 'var($_kChipPressedFillVar)'
      : wash(layer.pressed);
  final stateProperty = rawBase ? _kChipStateFillVar : 'background-color';
  final buffer = StringBuffer(_kChipStateResetRule)
    ..write('$scope:hover>.$kChipBodyMarker{$stateProperty:$hoverFillCss;}')
    ..write(
      '$scope:focus-visible>.$kChipBodyMarker{$stateProperty:$focusFillCss;}',
    )
    ..write(
      '$scope:active>.$kChipBodyMarker{$stateProperty:$pressedFillCss;}',
    );

  return ResolvedChipRules(scopeClass: scopeClass, css: buffer.toString());
}
