import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// Not a design token — the pill's local stacking order, one layer under the
// content it sits behind. Both pills (the settled one on the active item,
// the flight over the track) are positioned inside a box that opens its own
// stacking context (`isolate`), so the negative value ranks them under that
// box's content and nowhere else. `CoreZIndex` tiers start at 1000 and rank
// overlays against the page; a fill behind its own item is not that question.
const _kCssBehindContentStackingOrder = '-10';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Dock`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="navigation">)            // dock bar container — relative, isolate
///   ├─ flight (<div>)                       // only while the pill is in flight — absolute
///   │                                       // inset-0, carved by the morph clip
///   └─ Clickable (× n)                      // only when item.onPressed != null — tap /
///        │                                  // keyboard / cursor / press scale / focus ring;
///        │                                  // the flex item, so it carries the item's margins
///        └─ item (<div>)                    // per-item wrapper — see resolveDockItem
///             ├─ icon (<div>)               // the icon row — the plate's box
///             │    ├─ indicator (<div>)     // active item, not in flight — the plate
///             │    └─ (caller icon)
///             ├─ Gap (itemIconLabelGapStyle)   // co_dock renders only when label is rendered
///             └─ label (<div>)              // optional — text label below the icon
/// ```
///
/// The container `root` is exposed as a [WebElementChrome] slot. The
/// merged [CoreDockStyle] is carried forward so the per-item resolver
/// ([resolveDockItem]) can compose its slot chrome without
/// re-running the merge chain.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only Cat 1
/// ([WebElementChrome] slots) and Cat 2 (nested `CoreXxxStyle` slots).
/// No raw scalar metadata (minimum height / iconSize / showLabel / colour
/// override strings) is exposed — those values stay folded into the
/// composed chrome. The effective [CoreDockSize] is a behavioural
/// identifier (gates the per-item label slot + picks the per-size
/// defaults), not paint chrome, so it is resolved separately via
/// [resolveDockSize] and threaded into [resolveDockItem] by the
/// widget rather than living on this struct (number_ticker
/// separate-resolver pattern).
class ResolvedDock implements WebResolvedChrome {
  /// Creates a [ResolvedDock].
  const ResolvedDock({
    required this.root,
    required this.flight,
    required this.clickableStyle,
    required this.merged,
  });

  /// Paint-ready chrome for the outer dock bar container `<div>` —
  /// `flex flex-row w-full items-center justify-center` plus
  /// optional `bg-${surface}` / `border-${outline-variant}` token classes
  /// (suppressed when an inline override is supplied) and the corner
  /// class, plus inline `min-height` / `padding-left` / `padding-right` /
  /// `column-gap` / `box-shadow`, the line around the bar, and optional
  /// `background-color` / `border-color` overrides.
  ///
  /// The bar has a minimum height and no height: it is as tall as its item
  /// row asks and never shorter than `CoreDockStyle.height`, with the items
  /// centred in it either way. The room kept clear above and below the row
  /// for the active pill is not the bar's padding but each item's own margin
  /// ([ResolvedDockItem.clickable]).
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the flight `<div>` — the fill the morph clip
  /// carves the travelling pill out of. Absolute over the whole track,
  /// behind the items, inert to pointers. Rendered only while a flight is
  /// running; the settled pill is the active item's own slot.
  final WebElementChrome flight;

  /// Nested [CoreClickableStyle] slot for the `Clickable` composed
  /// around each tappable (`onPressed != null`) dock item —
  /// `CoreDockStyle.defaultClickableStyle` merged with the
  /// per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)` (the Clickable's own resolver fills
  /// the remaining defaults).
  final CoreClickableStyle clickableStyle;

  /// The merged platform-neutral style, including the per-size
  /// defaults from [CoreDockStyle.defaultsBySize]. Forwarded to
  /// [resolveDockItem] so it can compose per-item chrome without
  /// re-running the merge chain.
  final CoreDockStyle merged;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedDock] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (per size)
///   → theme.coreComponentTheme.dock.style
///   → widget.dockStyle
/// ```
ResolvedDock resolveDock(
  BuildContext context, {
  CoreDockSize? size,
  CoreDockStyle? dockStyle,
}) {
  final coreTheme = context.theme.coreComponentTheme?.dock;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreDockStyle(), [
    coreTheme?.style,
    dockStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  // Effective size only feeds the per-size minimum-height default below —
  // it is NOT carried on `ResolvedDock` (behavioural identifier; resolved
  // for the per-item resolver via [resolveDockSize]).
  final effectiveSize = resolveDockSize(context, size: size);
  final sizeStyle = CoreDockStyle.defaultsBySize[effectiveSize]!;

  // ─── Resolved chrome values ───────────────────────────
  // Minimum height — caller override wins, else size-default. A floor, not a
  // height: the bar grows past it when its row needs more room
  // (`CoreDockStyle.height`).
  final minHeight = merged.height ?? sizeStyle.height!;
  // Padding — caller override wins, else the size's. Only the sides land on
  // the bar; above and below, the room rides on the items
  // ([ResolvedDockItem.clickable]).
  final padding = merged.padding ?? sizeStyle.padding!;
  // The apps are packed this far apart and centred.
  final itemSpacing = merged.itemSpacing ?? sizeStyle.itemSpacing!;
  final barRadiusEmit = emitRadius(merged.barRadius, sizeStyle.barRadius!);
  // The bar's shadow. A token base and a scale stack route through
  // `var(--shadow-md)`, which carries the dark theme's strength and the
  // active style's bend; the rim rides beside it in the same list, the
  // way every panel that casts a shadow names it.
  final shadowBase =
      (merged.shadowBaseColor ?? CoreDockStyle.defaultShadowBaseColor)
          .toValue();
  final boxShadowStack = merged.boxShadow ?? CoreDockStyle.defaultBoxShadow;
  // A stated empty stack is a flat bar, and a flat bar takes no rim — the
  // rim decorates a surface that casts, as `resolveSurfaceRim` holds on
  // Flutter.
  final boxShadowValue = boxShadowStack.isEmpty
      ? 'none'
      : '${emitShadow(boxShadowStack, base: shadowBase)}, $kSurfaceRimVar';

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Background / border-top route through the emit family — a single
  // class-XOR-inline decision per design value. Token defaults
  // (`CoreDockStyle.defaultBackgroundColor` / `defaultBorderColor`) emit
  // Tailwind classes (dark-mode reactive); raw overrides go inline. No
  // `scheme.resolve` (a no-op on Web) and no `cs.<token>` direct refs.
  final backgroundEmit = emitColor(
    merged.backgroundColor,
    CoreDockStyle.defaultBackgroundColor,
    .background,
  );
  final borderEmit = emitColor(
    merged.borderColor,
    CoreDockStyle.defaultBorderColor,
    .border,
  );
  final borderWidth = merged.borderWidth ?? CoreDockStyle.defaultBorderWidth;

  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest).
  final clickableStyle = CoreDockStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );
  // The pill's fill, for the flight. The settled pill emits the same
  // value on the item — one emit, two elements, so the two cannot drift.
  final indicatorEmit = emitColor(
    merged.indicatorColor,
    CoreDockStyle.defaultIndicatorColor,
    .background,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer dock bar container `<div>` Tailwind className —
  /// `flex flex-row w-full items-center justify-center` plus the
  /// surface / outline-variant token colour classes ([backgroundEmit] /
  /// [borderEmit] — empty when an override goes inline) and the size's
  /// corner class ([barRadiusEmit]).
  String buildRootClassName() {
    return <String>[
      // Surface hook — the bar is a surface, so a material preset reaches
      // it the same way it reaches a card.
      ...webSurfaceMarkerFor(CoreSurfaceRole.functional),
      WebLayout.flex,
      WebLayout.flexRow,
      WebLayout.wFull,
      WebLayout.itemsCenter,
      WebLayout.justifyCenter,
      // The track the flight is positioned in, and its own stacking
      // context so the flight's negative z-index stays under the items
      // rather than under the page.
      WebLayout.relative,
      'isolate',
      backgroundEmit.className,
      borderEmit.className,
      barRadiusEmit.className,
    ].where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the outer dock bar container `<div>` inline-CSS bundle —
  /// inline `min-height` / `padding-left` / `padding-right` / `column-gap`
  /// and the line around the bar, plus the emit-family inline colour and
  /// corner fragments (raw overrides only — token values stay on
  /// classes).
  ///
  /// `min-height`, never `height`: the flex row sizes the bar and its
  /// `items-center` centres the items in the minimum when it fits. The
  /// bar's own padding stays horizontal — the room the pill needs above and
  /// below the row rides on the items ([ResolvedDockItem.clickable]).
  Styles buildRootInlineStyles() {
    final raw = {
      'min-height': '${minHeight / kRemDivisor}rem',
      // The bar states the line's style itself, so it draws on a page with
      // no reset too — and such a page sizes boxes by their content, which
      // would put the 1px line *on top of* `min-height`: a bar one pixel over
      // the Core minimum. Border-box keeps the minimum the minimum; on a page
      // with a reset this is already the case.
      'box-sizing': 'border-box',
      'padding-left': spaceCss(padding.left),
      'padding-right': spaceCss(padding.right),
      'column-gap': spaceCss(itemSpacing),
      'box-shadow': boxShadowValue,
      ...?backgroundEmit.inline,
      ...?borderEmit.inline,
      ...?barRadiusEmit.inline,
      ...surfaceFillVar(
        merged.backgroundColor ?? CoreDockStyle.defaultBackgroundColor,
      ),
      // Omitted when absent so a bar with no margin emits none.
      'margin': ?merged.barMargin?.toValue(),
      // All round: the bar is rounded, and a line on one edge of a rounded
      // box has nowhere to end. The width and the style are inline, never a
      // width class: the line never depends on Tailwind's preflight for its
      // style, and the width rides the stroke variable a surface style can
      // bend.
      'border-width': strokeWidthCss(borderWidth),
      'border-style': 'solid',
      // The material's band reaches over the line on every edge.
      ...surfaceBleedVar(strokeWidthCss(borderWidth)),
    };
    return Styles(raw: raw);
  }

  /// Composes the flight `<div>` className — the whole track, behind the
  /// items, inert, in the pill's fill.
  String buildFlightClassName() {
    return <String>[
      WebLayout.absolute,
      WebLayout.insetZero,
      'pointer-events-none',
      indicatorEmit.className,
    ].where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the flight `<div>` inline-CSS bundle — the stacking order
  /// under the items, plus the emit-family fill when it is a raw override.
  Styles buildFlightInlineStyles() {
    return Styles(
      raw: {
        'z-index': _kCssBehindContentStackingOrder,
        ...?indicatorEmit.inline,
      },
    );
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedDock(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    flight: WebElementChrome(
      className: buildFlightClassName(),
      inlineStyles: buildFlightInlineStyles(),
    ),
    clickableStyle: clickableStyle,
    merged: merged,
  );
}

/// Client-side config for the active plate's flight.
///
/// Fed to the measurement and the morph clip rather than to any element:
/// the two plates' bodies are the items' measured icon rows widened by the
/// padding, rounded by the radius, and flown at the spring's tempo. The
/// Flutter twin reads the same three values off its resolver.
class ResolvedDockIndicatorRuntime {
  /// Creates the runtime config.
  const ResolvedDockIndicatorRuntime({
    required this.spring,
    required this.padding,
    required this.radius,
  });

  /// The tempo the pill travels at — the morph engine's own type.
  final CoreMorphSpring spring;

  /// How far a pill extends past its item's box, in CSS pixels.
  final CoreEdgeInsets padding;

  /// The pill's corner radius, in CSS pixels.
  final double radius;
}

/// Resolves the flight config for a `Dock` whose chrome is [resolved], at
/// [size] — the plate's padding and corners are the size's (`md` when
/// [size] is null, the dock's own default).
///
/// Off the already-merged style rather than the chain again, so the two
/// resolvers cannot disagree about which override won.
ResolvedDockIndicatorRuntime resolveDockIndicatorRuntime(
  BuildContext context, {
  required ResolvedDock resolved,
  CoreDockSize? size,
}) {
  final merged = resolved.merged;
  final sizeStyle = CoreDockStyle.defaultsBySize[size ?? CoreDockSize.md]!;
  final spring = merged.indicatorSpring ?? CoreDockStyle.defaultIndicatorSpring;
  final padding = merged.indicatorPadding ?? sizeStyle.indicatorPadding!;
  final radius = (merged.indicatorRadius ?? sizeStyle.indicatorRadius!).topLeft;

  return ResolvedDockIndicatorRuntime(
    spring: spring,
    padding: padding,
    radius: radius,
  );
}

/// Resolves the effective [CoreDockSize] for `Dock`.
///
/// Behavioural identifier — gates the per-item label slot visibility
/// (`xs` / `sm` hide labels) and selects the per-size defaults
/// ([CoreDockStyle.defaultsBySize]) consumed by [resolveDockItem].
/// Kept as a separate `resolveCo*` entry point so [ResolvedDock]
/// stays pure paint-ready chrome (number_ticker separate-resolver
/// pattern).
///
/// `size` is a widget-only semantic identifier — the theme cannot
/// override it (render-only.md (c)), so the fallback is the bare
/// design-system default:
///
/// ```text
/// widget.size → CoreDockSize.md
/// ```
CoreDockSize resolveDockSize(
  BuildContext context, {
  CoreDockSize? size,
}) {
  return size ?? .md;
}

// ═══════════════════════════════════════════════════
// Per-item resolver
// ═══════════════════════════════════════════════════

/// Resolver output for a single `Dock` item's chrome.
///
/// DOM shape (per item):
///
/// ```text
/// root (<div>)                              // single item wrapper (icon + optional label column)
///   ├─ icon (<div>)                         // fixed-size icon holder
///   ├─ Gap (itemIconLabelGapStyle)        // co_dock renders only when label is rendered
///   └─ label (<div>)                        // optional — null when the size hides labels
///                                            // (xs/sm) or the item has no label string
/// ```
///
/// Each slot is pre-composed for the current per-item `isActive` /
/// `hasLabel` inputs by [resolveDockItem]; `co_dock` passes the
/// className / inlineStyles pairs straight to the matching `<div>` (the item
/// wrapper, or the `Clickable` around it for [clickable]). Tap / keyboard /
/// cursor / press-feedback / focus-ring chrome lives on the composed
/// `Clickable` wrapper (rendered by `co_dock` when the item is tappable), not
/// on these slots. The icon↔label gap is exposed as a nested `CoreGapStyle`
/// slot (`itemIconLabelGapStyle`) that the widget forwards straight to a
/// `Gap(gapStyle: …)` child — `Gap` runs its own resolve step.
class ResolvedDockItem implements WebResolvedChrome {
  /// Creates a [ResolvedDockItem].
  const ResolvedDockItem({
    required this.root,
    required this.icon,
    required this.iconStyle,
    required this.itemIconLabelGapStyle,
    this.clickable,
    this.label,
    this.indicator,
  });

  /// Paint-ready chrome for the item wrapper `<div>` —
  /// `flex flex-col items-center justify-center select-none` plus an
  /// active / inactive text colour token class (suppressed when an
  /// inline `color` override is supplied). The inline `color` override
  /// (when present) is stored on `inlineStyles`, and so are the cell's
  /// fixed `width` where the size gives one and the vertical margins of an
  /// item that is not tappable ([clickable]). The cursor is owned by the
  /// composed `Clickable` wrapper.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the composed `Clickable`'s root — layout only —
  /// or `null` when the item is not tappable and no `Clickable` wraps it.
  ///
  /// The room above and below the item — the bar's padding, never less than
  /// the active plate's reach past the icon (`CoreDockStyle.rowInsetFor`) —
  /// as vertical margins on the flex item, through the spacing variables: a
  /// density that moves the padding moves this. The flex
  /// item is this `Clickable` root when the item is tappable and the item
  /// wrapper ([root], which then carries the same margins itself) when it is
  /// not, so the room is on exactly one element of each.
  ///
  /// Margins on the flex item rather than padding on the bar, so the bar's
  /// own padding stays what it states and a tappable item's focus ring and
  /// hit area stay on the item (an outline is drawn around the border box,
  /// margins left out).
  final WebElementChrome? clickable;

  /// Paint-ready chrome for the icon row `<div>` — an inline-flex centred
  /// box as tall as the icon and as wide as the cell (the icon where the
  /// cell has no fixed width), and the box the plate is laid against.
  /// Carries the optional `color` override from [CoreDockStyle.iconStyle].
  final WebElementChrome icon;

  /// Nested [CoreIconStyle] slot — the merged icon chrome (size /
  /// colour) for the item glyph. `dock.dart` installs it as the
  /// nearest `IconTheme` around the caller icon so the dock size
  /// outranks the app-root ambient `IconTheme` (the holder's CSS
  /// `font-size` only reaches an `Icon` through CSS inheritance,
  /// which the Dart-channel ambient silently outranks — mirrors the
  /// Flutter twin's per-item `IconTheme.merge`).
  final CoreIconStyle iconStyle;

  /// Nested [CoreGapStyle] slot for the vertical gap between the icon
  /// and the label — forwarded straight to `Gap(gapStyle: …)` on
  /// the rendered child. The receiving `Gap` runs its own resolve
  /// step, so this slot is the merged design-system default +
  /// per-instance override in pre-scaling units (Epic #1603 nested-slot
  /// pattern).
  final CoreGapStyle itemIconLabelGapStyle;

  /// Paint-ready chrome for the label `<div>` — typography token
  /// classes plus any resolved label text-style overrides
  /// (`font-size`, `line-height`, `font-weight`, `letter-spacing`,
  /// `font-family`, `color`). `null` when the label slot is hidden
  /// (xs/sm sizes) or the item has no label string.
  final WebElementChrome? label;

  /// Paint-ready chrome for the settled plate `<div>` behind the item's
  /// icon — absolute, overhanging the icon row by the indicator padding,
  /// under the icon, inert. `null` for every item but the active one, and
  /// for the active one while its plate is in flight.
  final WebElementChrome? indicator;
}

/// Resolves [ResolvedDockItem] for one `Dock` entry.
///
/// Closes over the per-item runtime state (`isActive`, `hasLabel`,
/// `tappable` — whether a `Clickable` wraps the item), the
/// pre-resolved [ResolvedDock] (merged style chain) and the
/// effective `size` (resolved via [resolveDockSize]) so each slot's
/// chrome bundle is pre-composed.
ResolvedDockItem resolveDockItem(
  BuildContext context, {
  required ResolvedDock resolved,
  required CoreDockSize size,
  required bool isActive,
  required bool hasLabel,
  bool showIndicator = false,
  bool tappable = false,
}) {
  final merged = resolved.merged;
  final sizeStyle = CoreDockStyle.defaultsBySize[size]!;
  final showLabel = CoreDockStyle.labelVisibleFor(size);

  // ─── Resolved chrome values ───────────────────────────
  // Icon size — slot override wins, else the size-default
  // `CoreDockStyle.defaultsBySize[size].iconStyle.size`.
  final iconStyle = CoreDockStyle.defaultIconStyle
      .merge(sizeStyle.iconStyle)
      .merge(merged.iconStyle);
  final iconSize = iconStyle.size!;
  final iconColorOverride = merged.iconStyle?.color;
  // Icon-label gap slot — design-system default merged with the
  // per-instance override. Forwarded to `Gap(gapStyle: …)` between
  // the icon and label children — `Gap` self-scales, so this slot
  // is the pre-scaling nested [CoreGapStyle] (Epic #1603 nested-slot
  // pattern — `merged.itemIconLabelGapStyle` wins on each non-null
  // field).
  final itemIconLabelGapStyle = CoreDockStyle.defaultItemIconLabelGapStyle
      .merge(merged.itemIconLabelGapStyle);

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Item foreground colour (icon + label inherit it). Token defaults
  // (`CoreDockStyle.defaultActiveColor` / `defaultInactiveColor`) emit a
  // `text-{token}` class (dark-mode reactive); a raw override goes
  // inline. No `cs.<token>` direct refs, no `scheme.resolve` (a no-op on
  // Web). The per-state default + override are selected by `isActive`.
  final itemColorEmit = emitColor(
    isActive ? merged.activeColor : merged.inactiveColor,
    isActive
        ? CoreDockStyle.defaultActiveColor
        : CoreDockStyle.defaultInactiveColor,
    .text,
  );
  // Icon colour override — emitted only when the `iconStyle.color` slot
  // is set; otherwise the icon inherits the item `color` from the
  // wrapper. Routed through `emitColor` (token → class, raw → inline) so
  // the override behaves like every other colour. `null` → no icon-level
  // colour emitted.
  final iconColorEmit = iconColorOverride == null
      ? null
      : emitColor(iconColorOverride, iconColorOverride, .text);
  // Label typography — fixed `labelXs` role + per-state weight and colour
  // (active = semiBold on-surface, inactive = medium on-surface-variant)
  // carried by the per-state default style; the per-instance
  // `labelTextStyle` overlays on top.
  // `emitTypography` is the single canonical path: it emits the role on a
  // `text-{role}` class (inherited by the inner text) AND any explicit
  // scalar overlay inline — no hand-rolled `text-${...token!.name}` /
  // `font-${weight}` construction.
  final labelDefault = isActive
      ? CoreDockStyle.defaultActiveLabelStyle.merge(merged.activeLabelStyle)
      : CoreDockStyle.defaultInactiveLabelStyle.merge(
          merged.inactiveLabelStyle,
        );
  final labelEmit = emitTypography(merged.labelTextStyle, labelDefault);
  // The settled plate — same fill emit as the flight, its own corners.
  final indicatorEmit = emitColor(
    merged.indicatorColor,
    CoreDockStyle.defaultIndicatorColor,
    .background,
  );
  final indicatorRadiusEmit = emitRadius(
    merged.indicatorRadius,
    sizeStyle.indicatorRadius!,
  );
  final indicatorPadding =
      merged.indicatorPadding ?? sizeStyle.indicatorPadding!;
  final padding = merged.padding ?? sizeStyle.padding!;
  // The cell's fixed width where the size gives one.
  final itemWidth = merged.itemWidth ?? sizeStyle.itemWidth;

  // ─── Local builders — root chrome ─────────────────────

  /// Composes the item wrapper `<div>` Tailwind className — flex column
  /// layout and the item foreground colour class ([itemColorEmit] —
  /// empty when a raw override goes inline; the icon and label both
  /// inherit this `color`). The cursor is owned by the composed
  /// `Clickable` wrapper.
  String buildRootClassName() {
    return <String>[
      WebLayout.flex,
      WebLayout.flexCol,
      WebLayout.itemsCenter,
      WebLayout.justifyCenter,
      'select-none',
      itemColorEmit.className,
    ].where((cls) => cls.isNotEmpty).join(' ');
  }

  // ─── Local builders — indicator chrome ────────────────

  /// Composes the settled plate `<div>` className — absolute under the
  /// content, inert, rounded and filled by the emit family.
  String buildIndicatorClassName() {
    return <String>[
      WebLayout.absolute,
      'pointer-events-none',
      indicatorRadiusEmit.className,
      indicatorEmit.className,
    ].where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the settled plate `<div>` inline-CSS bundle — the stacking
  /// order under the icon, the reach past the icon row on each side, plus
  /// any raw fill or radius.
  ///
  /// The overhang is `indicatorPadding`, a `CoreEdgeInsets` the Flutter
  /// twin converts through the theme geometry before negating it — so a
  /// density moves it there, and each side is negated around its
  /// spacing variable here rather than baked as a literal.
  Styles buildIndicatorInlineStyles() {
    String overhang(double side) => 'calc(-1 * ${spaceCss(side)})';

    return Styles(
      raw: {
        'z-index': _kCssBehindContentStackingOrder,
        'inset':
            '${overhang(indicatorPadding.top)} '
            '${overhang(indicatorPadding.right)} '
            '${overhang(indicatorPadding.bottom)} '
            '${overhang(indicatorPadding.left)}',
        ...?indicatorRadiusEmit.inline,
        ...?indicatorEmit.inline,
      },
    );
  }

  /// The room above and below the item, as margins on the flex item — on
  /// the item wrapper when nothing wraps it, on the `Clickable` when
  /// something does.
  final clearanceRaw = {
    'margin-top': spaceCss(
      CoreDockStyle.rowInsetFor(padding.top, indicatorPadding),
    ),
    'margin-bottom': spaceCss(
      CoreDockStyle.rowInsetFor(padding.bottom, indicatorPadding),
    ),
  };

  /// Composes the item wrapper `<div>` inline-CSS bundle — the
  /// emit-family inline `color` fragment (raw override only — a token
  /// value stays on the class), plus the clearance margins when the item
  /// wrapper is the flex item itself. Returns `null` when nothing goes
  /// inline.
  Styles? buildRootInlineStyles() {
    final raw = {
      ...?itemColorEmit.inline,
      'width': ?(itemWidth == null ? null : '${itemWidth / kRemDivisor}rem'),
      if (!tappable) ...clearanceRaw,
    };
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  // ─── Local builders — icon chrome ─────────────────────

  /// Composes the icon row `<div>` Tailwind className — the box the settled
  /// plate is positioned against, a stacking context of its own so the
  /// plate's negative z-index puts it under the icon and nowhere else, and
  /// the icon colour override class when `iconStyle.color` is a token
  /// ([iconColorEmit]); otherwise the icon inherits the item `color` set
  /// on the wrapper.
  String buildIconClassName() => <String>[
    WebLayout.relative,
    'isolate',
    iconColorEmit?.className ?? '',
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the icon row `<div>` inline-CSS bundle — a box as tall as the
  /// icon and as wide as the cell (the icon where the cell has no fixed
  /// width), with inline-flex centring, plus the emit-family inline
  /// `color` fragment when `iconStyle.color` is a raw override.
  Styles buildIconInlineStyles() {
    final iconExtent = '${iconSize / kRemDivisor}rem';
    return Styles(
      raw: {
        'width': itemWidth == null
            ? iconExtent
            : '${itemWidth / kRemDivisor}rem',
        'height': iconExtent,
        'font-size': iconExtent,
        'display': 'inline-flex',
        'align-items': 'center',
        'justify-content': 'center',
        ...?iconColorEmit?.inline,
      },
    );
  }

  // ─── Local builders — label chrome ────────────────────

  /// Composes the label `<div>` Tailwind className — the `labelXs` role and
  /// per-state colour token classes from [labelEmit] (inherited by the
  /// inner text).
  String buildLabelClassName() => labelEmit.className;

  /// Composes the label `<div>` inline-CSS bundle — the explicit
  /// typography overlay (`font-size` / line-height / letter-spacing /
  /// raw colour) emitted by [labelEmit] on top of the role class.
  /// Returns `null` when the merged label style is a pure role with no
  /// overlay (the icon↔label gap is rendered as a separate `Gap` child
  /// by `co_dock`, so the label wrapper carries no spacing inline-CSS).
  Styles? buildLabelInlineStyles() {
    final inline = labelEmit.inline;
    return inline == null ? null : Styles(raw: inline);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  final shouldRenderLabel = showLabel && hasLabel;
  return ResolvedDockItem(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    clickable: tappable
        ? WebElementChrome(
            className: '',
            inlineStyles: Styles(raw: clearanceRaw),
          )
        : null,
    icon: WebElementChrome(
      className: buildIconClassName(),
      inlineStyles: buildIconInlineStyles(),
    ),
    iconStyle: iconStyle,
    itemIconLabelGapStyle: itemIconLabelGapStyle,
    label: shouldRenderLabel
        ? WebElementChrome(
            className: buildLabelClassName(),
            inlineStyles: buildLabelInlineStyles(),
          )
        : null,
    indicator: showIndicator
        ? WebElementChrome(
            className: buildIndicatorClassName(),
            inlineStyles: buildIndicatorInlineStyles(),
          )
        : null,
  );
}
