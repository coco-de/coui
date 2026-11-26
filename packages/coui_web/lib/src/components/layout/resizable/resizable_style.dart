library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Ratio → percent conversion factor. Not a design token — pure math for
/// the cumulative-flex seam position of each divider overlay.
const _kRatioToPercent = 100;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Resizable`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                                 // relative flex container (direction + sizing)
///   ├─ panes[i] (<div>)                        // per-pane flex wrapper, flush (no divider gutter)
///   └─ dividerWrappers[i] (<div>)              // absolute overlay on the seam (group + hit area + cursor)
///        ├─ dividerLine (<div>)                // thin hairline, full cross-axis (group-hover colour)
///        └─ handlePill (<div>)                 // centred pill grab handle (showDragHandle only)
///             └─ handleIconWrapper (<div>)     // rotate wrapper for the drag dots (showDragHandle only)
///                  └─ Icon                   // drag dots (handleIconStyle, showDragHandle only)
/// ```
///
/// The panes fill the container with no reserved divider gutter so the
/// content area stays maximal. Each divider is an **absolutely positioned
/// overlay** centred on the pane boundary (`left|top: {percent}%`), so it
/// floats above the content without stealing layout width — only the
/// hairline [dividerLine] sits over the seam, and the [handlePill] floats
/// above for comfortable touch dragging. Hover crossfades both the line
/// and the pill together via Tailwind `group` / `group-hover:` on the
/// wrapper.
///
/// [dividerWrappers] is a parallel list (one entry per gap) because each
/// wrapper's seam position differs; [dividerLine] / [handlePill] are
/// uniform (state is CSS-driven) so a single instance is reused. When
/// `showDragHandle` is `false`, [handlePill] / [handleIconStyle] /
/// [handleIconWrapper] are null and the wrapper's hit area shrinks to the
/// divider hit extent — the hairline itself carries the drag.
class ResolvedResizable implements WebResolvedChrome {
  /// Creates a [ResolvedResizable].
  const ResolvedResizable({
    required this.root,
    required this.panes,
    required this.dividerWrappers,
    required this.dividerLine,
    required this.dividerLineDragging,
    required this.focusOutlineStyle,
    this.handlePill,
    this.handleIconStyle,
    this.handleIconWrapper,
  });

  /// Paint-ready chrome for the outer flex container `<div>` — inline
  /// `position: relative` + `flex` + direction class + `w-full h-full`.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for each pane wrapper `<div>` — one entry per
  /// pane in input order. Each carries inline `flex: <flex> 1 0` +
  /// `overflow: hidden` + axis-specific `min-width|min-height: 0` +
  /// `word-break: break-all` (Flutter `Expanded` parity). Panes are
  /// flush — no divider gutter between them.
  final List<WebElementChrome> panes;

  /// Paint-ready chrome for each divider's absolute overlay wrapper
  /// `<div>` — one entry per gap. Carries `position: absolute` + the
  /// per-seam `left|top: {percent}%` + `transform: translate(-50%)` so it
  /// is centred on the boundary, the per-direction hit area
  /// (width|height) + matching CSS cursor, flex centering, and the
  /// `group` class so hover crossfades the contained line + pill.
  final List<WebElementChrome> dividerWrappers;

  /// Paint-ready chrome for the thin hairline `<div>` inside each wrapper —
  /// uniform across gaps. Carries the cross-axis thickness, full
  /// main-axis extent, the idle colour ([emitColor] token `bg-{outline}`
  /// class or inline override), the `group-hover:bg-{primary}` crossfade
  /// class, and the colour `transition`.
  final WebElementChrome dividerLine;

  /// [dividerLine] for the divider currently under a drag.
  ///
  /// Identical except that `optionalDivider` does not hide it. A drag has
  /// no CSS pseudo-class to ride — it outlives hover, because the divider
  /// pins at its bound while the pointer keeps travelling and because a
  /// touch pointer never hovers — so the widget picks between the two
  /// instead of the stylesheet doing it.
  final WebElementChrome dividerLineDragging;

  /// Keyboard focus ring of a divider, forwarded to `FocusOutline`.
  final CoreFocusOutlineStyle focusOutlineStyle;

  /// Paint-ready chrome for the centred pill grab handle `<div>` — non-null
  /// only when `showDragHandle` is set. Carries the pill dimensions
  /// (`handleBreadth × handleLength`, stadium radius), the idle handle
  /// colour, the `group-hover:bg-{primary}` crossfade class, the
  /// `transition`, and flex centering for the drag dots.
  final WebElementChrome? handlePill;

  /// Drag-dot icon style inside the grab handle — non-null only when
  /// `showDragHandle` is set. Fed straight to `Icon(iconStyle: …)`.
  final CoreIconStyle? handleIconStyle;

  /// Wrapper `<div>` chrome around the drag dots — non-null only when
  /// `showDragHandle` is set and the dots need rotating upright (a
  /// horizontal split's vertical divider). Carries the `rotate(90deg)`
  /// transform plus flex centering.
  final WebElementChrome? handleIconWrapper;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedResizable] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.resizable.style
///   → widget.resizableStyle
/// ```
///
/// [paneFlexes] is the per-build sequence of integer flex ratios
/// (ratio × precision) for each pane — the resolver bakes them into the
/// inline `flex` rule on each entry of [ResolvedResizable.panes] and
/// derives each divider overlay's seam position (cumulative flex %).
/// [showDragHandle] enlarges the divider hit area and adds a pill grab
/// handle with drag dots floating over the seam (touch platforms).
ResolvedResizable resolveResizable(
  BuildContext context, {
  required CoreResizableDirection direction,
  required List<int> paneFlexes,
  required bool showDragHandle,
  required bool optionalDivider,
  CoreResizableStyle? resizableStyle,
}) {
  final theme = context.theme.coreComponentTheme?.resizable;

  final merged = resolveStyleChain(const CoreResizableStyle(), [
    theme?.style,
    resizableStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  final isHorizontal = direction == .horizontal;
  final thickness =
      merged.dividerThickness ?? CoreResizableStyle.defaultDividerThickness;
  final draggingThickness =
      merged.dividerDraggingThickness ??
      CoreResizableStyle.defaultDividerDraggingThickness;
  final hitExtent =
      merged.dividerHitExtent ?? CoreResizableStyle.defaultDividerHitExtent;
  // Enlarged hit area + pill dimensions for the grab handle.
  final handleHitExtent =
      merged.handleHitExtent ?? CoreResizableStyle.defaultHandleHitExtent;
  final handleLength =
      merged.handleLength ?? CoreResizableStyle.defaultHandleLength;
  final handleBreadth =
      merged.handleBreadth ?? CoreResizableStyle.defaultHandleBreadth;
  final handleIconSize =
      merged.handleIconSize ?? CoreResizableStyle.defaultHandleIconSize;
  // Effective overlay hit extent — widened when the grab handle is shown.
  final effectiveHitExtent = showDragHandle ? handleHitExtent : hitExtent;
  // Hairline idle colour — class XOR inline via the emit family (token →
  // `bg-{outlineVariant}` class, raw override → inline `background-color`).
  // Single source of truth is `CoreResizableStyle.defaultDividerColor`,
  // matching the Flutter resolver.
  // `optionalDivider` decides the IDLE colour here, not in the widget — a
  // build-time semantic prop belongs on the resolver input the way
  // `showDragHandle` above already is. The hover / focus classes below are
  // untouched, which is what makes the divider appear on interaction.
  //
  // `CoreColor.transparent` rather than a raw rgba literal — the shared
  // sentinel for "no fill", so both platforms name the same thing.
  final lineEmit = optionalDivider
      ? emitColor(CoreColor.transparent, CoreColor.transparent, .background)
      : emitColor(
          merged.dividerColor,
          CoreResizableStyle.defaultDividerColor,
          .background,
        );
  // What a divider being dragged shows — the heavier `primary` line. A drag
  // is not expressible as a CSS pseudo-class: it outlives hover (the divider
  // pins at its bound while the pointer keeps travelling, and a touch
  // pointer never hovers at all), so the widget selects between two
  // resolved chromes rather than the stylesheet deciding. This chrome
  // carries no hover class — a hovered, dragged line stays `primary`.
  final draggingLineEmit = emitColor(
    merged.dividerDraggingColor,
    CoreResizableStyle.defaultDividerDraggingColor,
    .background,
  );
  final focusOutlineStyle = CoreResizableStyle.defaultFocusOutlineStyle.merge(
    merged.focusOutlineStyle,
  );

  // Pill idle colour — reuses `handleColor` (also `outline` by default).
  final pillEmit = emitColor(
    merged.handleColor,
    CoreResizableStyle.defaultHandleColor,
    .background,
  );
  // Hover colour — `CoreResizableStyle.defaultDividerHoverColor` (`primary`
  // token) unless overridden (Flutter parity). Emitted as a
  // `group-hover:bg-{token}` pseudo-state class so the wrapper's hover
  // crossfades both the hairline and the pill together (CSS `:hover` can
  // only be expressed through a class).
  final hoverColor =
      merged.dividerHoverColor ?? CoreResizableStyle.defaultDividerHoverColor;
  // Colour crossfade duration between the idle / hover states — design
  // default unless overridden. Emitted as an inline `transition`.
  final transitionDuration =
      merged.transitionDuration ?? CoreResizableStyle.defaultTransitionDuration;
  // Token-routed duration + easing (`durationMsCss` / `toVarCss` docs).
  final transitionTiming =
      '${durationMsCss(transitionDuration.inMilliseconds)} '
      '${CoreEasing.move.toVarCss()}';

  // Seam positions as cumulative flex percentages of the container main
  // axis — the overlay wrappers are centred on these boundaries.
  final totalFlex = paneFlexes.fold<int>(0, (sum, f) => sum + f);
  final seamPercents = <double>[];
  if (totalFlex > 0) {
    var cumulative = 0;
    for (int i = 0; i < paneFlexes.length - 1; i++) {
      cumulative += paneFlexes[i];
      seamPercents.add(cumulative * _kRatioToPercent / totalFlex);
    }
  }

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer flex container `<div>` Tailwind className —
  /// `flex` + direction class + `w-full h-full`. `position: relative` is
  /// inline so the absolute divider overlays anchor to it.
  String buildRootClassName() {
    final directionClass = isHorizontal ? WebLayout.flexRow : WebLayout.flexCol;
    return '${WebLayout.flex} $directionClass ${WebLayout.wFull} ${WebLayout.hFull}';
  }

  /// Composes a single pane wrapper `<div>` inline CSS — `flex` +
  /// `overflow: hidden` + axis-specific `min-*: 0` + `word-break:
  /// break-all`.
  Styles buildPaneInlineStyles(int flex) => .new(
    raw: {
      WebLayout.flex: '$flex 1 0',
      'overflow': 'hidden',
      // Required for children with intrinsic min-size to shrink and
      // allow text wrapping (Flutter `Expanded` parity).
      if (isHorizontal) 'min-width': '0' else 'min-height': '0',
      // Flutter `Text` wraps per-grapheme; match that by allowing breaks
      // anywhere instead of CSS default word-level wrapping.
      'word-break': 'break-all',
    },
  );

  /// Composes a divider overlay wrapper `<div>` Tailwind className —
  /// flex centering + `group` (so hover crossfades the contained line +
  /// pill together).
  String buildDividerWrapperClassName() =>
      '${WebLayout.flex} ${WebLayout.itemsCenter} ${WebLayout.justifyCenter} group';

  /// Composes a divider overlay wrapper `<div>` inline CSS — absolute
  /// position centred on [seamPercent], the per-direction hit area, and
  /// the matching CSS cursor.
  Styles buildDividerWrapperInlineStyles(double seamPercent) {
    final raw = {
      'position': 'absolute',
      if (isHorizontal) ...{
        'left': '$seamPercent%',
        'top': '0',
        'bottom': '0',
        'width': '${effectiveHitExtent / kRemDivisor}rem',
        'transform': 'translateX(-50%)',
        'cursor': 'col-resize',
      } else ...{
        'top': '$seamPercent%',
        'left': '0',
        'right': '0',
        'height': '${effectiveHitExtent / kRemDivisor}rem',
        'transform': 'translateY(-50%)',
        'cursor': 'row-resize',
      },
    };
    return Styles(raw: raw);
  }

  /// Composes the hairline `<div>` Tailwind className — idle colour token
  /// class (when not overridden inline) + the `group-hover:bg-{token}`
  /// crossfade, also triggered by `group-focus-visible:` so a keyboard
  /// user tabbing to the divider (`role="separator"` wrapper) sees the
  /// same highlight a mouse hover gives — WCAG 2.4.7, and Flutter parity
  /// with `_activeDivider` reacting to `FocusableActionDetector.
  /// onShowFocusHighlight` there.
  String buildDividerLineClassName({required bool dragging}) {
    final emit = dragging ? draggingLineEmit : lineEmit;
    final classList = <String>[];
    if (emit.className.isNotEmpty) {
      classList.add(emit.className);
    }
    if (dragging) return classList.join(' ');
    // A focused divider keeps the resting line and wears the shared focus
    // ring instead (`FocusOutline`). An `optionalDivider` has no resting
    // line, so keyboard focus still reveals it the way hover does.
    classList.add('group-hover:bg-$hoverColor');
    if (optionalDivider) classList.add('group-focus-visible:bg-$hoverColor');
    return classList.join(' ');
  }

  /// Composes the hairline `<div>` inline CSS — cross-axis thickness, full
  /// main-axis extent, optional `background-color` override, and the
  /// colour crossfade `transition`.
  Styles buildDividerLineInlineStyles({required bool dragging}) {
    final emit = dragging ? draggingLineEmit : lineEmit;
    final lineThickness = dragging ? draggingThickness : thickness;
    final raw = {
      // Stroke-axis value — ride `strokeWidthCss` (token → `var(...)`,
      // arbitrary → px) so a `strokeFloor` surface-style preset reaches
      // it, and so it stays px-fixed rather than growing with the
      // text-scaling `rem` axis a border must be immune to. Mirrors
      // `Divider`'s own `divider_style.dart`.
      if (isHorizontal) ...{
        'width': strokeWidthCss(lineThickness),
        'height': '100%',
      } else ...{
        'height': strokeWidthCss(lineThickness),
        'width': '100%',
      },
      ...?emit.inline,
      'transition': 'background-color $transitionTiming',
    };
    return Styles(raw: raw);
  }

  /// Composes the pill grab handle `<div>` Tailwind className — idle
  /// colour token class + `group-hover:bg-{token}`/`group-focus-visible:
  /// bg-{token}` crossfade (see [buildDividerLineClassName]) + flex
  /// centering for the drag dots.
  String buildHandlePillClassName() {
    final classList = <String>[];
    if (pillEmit.className.isNotEmpty) {
      classList.add(pillEmit.className);
    }
    classList
      ..add('group-hover:bg-$hoverColor')
      ..add('group-focus-visible:bg-$hoverColor')
      ..add(WebLayout.flex)
      ..add(WebLayout.itemsCenter)
      ..add(WebLayout.justifyCenter);
    return classList.join(' ');
  }

  /// Composes the pill grab handle `<div>` inline CSS — pill dimensions
  /// (`breadth × length`, stadium radius), absolute centering over the
  /// hairline, optional colour override, and the colour `transition`.
  Styles buildHandlePillInlineStyles() {
    final raw = {
      'position': 'absolute',
      'width':
          '${(isHorizontal ? handleBreadth : handleLength) / kRemDivisor}rem',
      'height':
          '${(isHorizontal ? handleLength : handleBreadth) / kRemDivisor}rem',
      // A derived pill: half the breadth is 'fully rounded'. Routed through
      // the shared emitter so a style that squares corners reaches it too.
      'border-radius': radiusCss(handleBreadth / 2),
      ...?pillEmit.inline,
      'transition': 'background-color $transitionTiming',
    };
    return Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedResizable(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: const Styles(raw: {'position': 'relative'}),
    ),
    panes: [
      for (final flex in paneFlexes)
        WebElementChrome(
          className: '',
          inlineStyles: buildPaneInlineStyles(flex),
        ),
    ],
    dividerWrappers: [
      for (final seamPercent in seamPercents)
        WebElementChrome(
          className: buildDividerWrapperClassName(),
          inlineStyles: buildDividerWrapperInlineStyles(seamPercent),
        ),
    ],
    dividerLine: WebElementChrome(
      className: buildDividerLineClassName(dragging: false),
      inlineStyles: buildDividerLineInlineStyles(dragging: false),
    ),
    dividerLineDragging: WebElementChrome(
      className: buildDividerLineClassName(dragging: true),
      inlineStyles: buildDividerLineInlineStyles(dragging: true),
    ),
    focusOutlineStyle: focusOutlineStyle,
    handlePill: showDragHandle
        ? WebElementChrome(
            className: buildHandlePillClassName(),
            inlineStyles: buildHandlePillInlineStyles(),
          )
        : null,
    handleIconStyle: showDragHandle
        ? CoreIconStyle(
            size: handleIconSize,
            color:
                merged.handleIconColor ??
                CoreResizableStyle.defaultHandleIconColor,
          )
        : null,
    handleIconWrapper: showDragHandle && isHorizontal
        ? WebElementChrome(
            className:
                '${WebLayout.flex} ${WebLayout.itemsCenter} ${WebLayout.justifyCenter}',
            // Vertical divider (horizontal split) needs the dots upright.
            inlineStyles: const Styles(raw: {'transform': 'rotate(90deg)'}),
          )
        : null,
  );
}
