library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Divider`.
///
/// DOM shape (two branches, `co_divider` picks based on `child`
/// presence):
///
/// ```text
/// // child == null — single line, root is the line itself
/// root (<div>)                                  // single line chrome
///
/// // child != null — a grid hosts leading / child / trailing, one track each
/// root (<div>)                                  // grid, tracks along the axis
///   ├─ lineLeading (<div>)                      // line, start inset as margin in its track
///   ├─ childWrapper (<div>)                     // label, padding along main axis
///   └─ lineTrailing (<div>)                     // line, end inset as margin in its track
/// ```
///
/// The two line elements are grid items, so a segment's box is its track and
/// its inset is the item's margin *inside* that track. The tracks beside the
/// label split what the label leaves by their weights whatever the insets
/// are — an inset only shortens its line — which is how Flutter divides the
/// axis between its two `Flexible` segments, each holding its own `Padding`.
///
/// All slot chromes are non-null — `co_divider` decides which branch
/// actually renders based on the instance `child` slot.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only
/// `WebElementChrome` slots — no scalar metadata
/// (no `hasChild` boolean, no `orientation`). Semantic identifiers
/// stay on the widget prop; the resolver bakes them into the
/// className / inline-CSS strings.
class ResolvedDivider implements WebResolvedChrome {
  /// Creates a [ResolvedDivider].
  const ResolvedDivider({
    required this.root,
    required this.lineLeading,
    required this.lineTrailing,
    required this.childWrapper,
  });

  /// Paint-ready chrome for the outermost `<div>`.
  ///
  /// `co_divider` always renders this element. Its shape depends on
  /// whether the instance has a centred child:
  ///
  /// * `child == null` — `root` carries the single-line className +
  ///   inline-CSS (thickness, leading / trailing indent, optional
  ///   colour override). No children are rendered inside.
  /// * `child != null` — `root` carries the grid-wrapper className
  ///   (`grid items-center w-full`, or `grid justify-items-center
  ///   h-full` for a vertical divider) and the track template inline
  ///   (`grid-template-columns` / `grid-template-rows`). `co_divider`
  ///   renders the [lineLeading] / [childWrapper] / [lineTrailing] slots
  ///   inside.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the leading line `<div>` — `co_divider`
  /// renders this only when `child != null`. Carries the default colour
  /// class plus inline CSS for thickness + leading indent + optional
  /// colour override. The element sits in the first track of the
  /// wrapper's template and fills it less its margin.
  final WebElementChrome lineLeading;

  /// Paint-ready chrome for the trailing line `<div>` — `co_divider`
  /// renders this only when `child != null`. Carries the default colour
  /// class plus inline CSS for thickness + trailing indent + optional
  /// colour override. The element sits in the last track of the
  /// wrapper's template and fills it less its margin.
  final WebElementChrome lineTrailing;

  /// Paint-ready chrome for the centred child wrapper `<div>` —
  /// `co_divider` renders this only when `child != null`. Carries
  /// the inline padding along the main axis (the child gap).
  final WebElementChrome childWrapper;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// A grid track as long as its content (CSS `auto`): the label's, and that of
/// a segment whose weight is zero. Not a design token — a CSS track keyword.
const _kCssContentTrack = 'auto';

/// Resolves [ResolvedDivider] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.divider.style
///   → widget.dividerStyle
/// ```
///
/// The semantic [orientation] and the structural [hasChild] flag are
/// widget-side render context — they thread through to pick the
/// grid / line layout classes here but stay off `ResolvedDivider`
/// (옵션 B 최종 — no scalar metadata in the resolved output).
ResolvedDivider resolveDivider(
  BuildContext context, {
  required CoreDividerOrientation orientation,
  required bool hasChild,
  CoreDividerStyle? dividerStyle,
}) {
  final dividerTheme = context.theme.coreComponentTheme?.divider;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreDividerStyle(), [
    dividerTheme?.style,
    dividerStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Every value finished its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly).
  final thickness = merged.thickness ?? CoreDividerStyle.defaultThickness;
  final indent = merged.indent ?? CoreDividerStyle.defaultIndent;
  final endIndent = merged.endIndent ?? CoreDividerStyle.defaultEndIndent;
  final childPadding =
      merged.childPadding ?? CoreDividerStyle.defaultChildPadding;
  // The two flex weights come off the Core enum rather than a switch
  // here, so Web and Flutter cannot disagree about which segment
  // collapses. `center` yields 1/1 → the two segments share what the
  // label leaves equally.
  final childAlignment =
      merged.childAlignment ?? CoreDividerStyle.defaultChildAlignment;

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  // Line colour routes through the emit family — a single
  // class-XOR-inline decision. A token-bound value (default OR a token
  // override) emits the `bg-{token}` Tailwind class so it stays
  // dark-mode reactive; a raw override goes inline (`background-color`).
  // No `scheme.resolve` (a no-op on Web).
  final colorEmit = emitColor(
    merged.color,
    CoreDividerStyle.defaultColor,
    .background,
  );

  final isHorizontal = orientation == .horizontal;

  // A standalone line inset at either end is the container's length less both
  // insets — the length Flutter's `Divider` has (`width - indent - endIndent`).
  // `100%` plus the margins would instead start the line inside the box and
  // run it out past the far edge. So the fill class gives way to one inline
  // length that already subtracts the insets, and with no inset the class
  // stays: the unindented line is the markup it always was.
  final isInset = indent != 0 || endIndent != 0;

  // ─── Local builders ───────────────────────────────────
  // Closures capture every chrome value above — no named-arg
  // explosion. Local to the resolver, inaccessible from outside.

  /// Composes a line `<div>` Tailwind className.
  ///
  /// A [standalone] line has no sibling to share the axis with and
  /// instead fills it (`w-full` / `h-full`) — unless it is inset, when
  /// [buildLineInlineStyles] states its length inline. A child-mode
  /// segment is a grid item whose length its track and margin decide, so
  /// it carries no sizing class.
  ///
  /// The `bg-{token}` colour class comes from [colorEmit] —
  /// present for a token colour, empty when the colour goes inline (raw
  /// override), in which case [buildLineInlineStyles] emits it instead.
  String buildLineClassName({required bool standalone}) {
    return <String>[
      if (standalone) WebLayout.shrinkZero,
      if (standalone && !isInset && isHorizontal) WebLayout.wFull,
      if (standalone && !isInset && !isHorizontal) WebLayout.hFull,
      if (colorEmit.className.isNotEmpty) colorEmit.className,
    ].join(' ');
  }

  /// Composes a line `<div>` inline-CSS bundle.
  ///
  /// Emits thickness along the cross axis, leading / trailing indent
  /// along the main axis (each gated by the segment's edge), and the
  /// optional background-colour override.
  ///
  /// `showLeadingIndent` / `showTrailingIndent` are emitted only when
  /// the corresponding edge belongs to *this* line segment (e.g. the
  /// leading line in child-mode emits leading indent only, the
  /// trailing line emits trailing indent only; standalone mode emits
  /// both).
  ///
  /// A [standalone] line that is inset also states its length along the
  /// main axis: the container's less both insets, written with the same
  /// spacing steps as the margins so a density change moves them together.
  /// Child-mode segments are grid items stretched across their track, which
  /// leaves their margins out of the length they fill.
  Styles buildLineInlineStyles({
    required bool showLeadingIndent,
    required bool showTrailingIndent,
    bool standalone = false,
  }) {
    final raw = <String, String>{
      // The line's cross-axis extent is a stroke width, not a plain
      // dimension — it shares `CoreStrokeWidth` with border/focus-ring/
      // underline (`core/design-tokens.md`) and the neo-brutalism preset
      // floors it (`CoreSurfaceGeometryConstraint.strokeFloor`). That
      // floor rides the `--coui-stroke-width-N` variables, so this must
      // go through `strokeWidthCss` (token → `var(...)`, arbitrary → px)
      // rather than a literal rem — a literal never reads the variable
      // and silently opts the divider out of every stroke-bending preset.
      if (isHorizontal) 'height': strokeWidthCss(thickness),
      if (!isHorizontal) 'width': strokeWidthCss(thickness),
      if (standalone && isInset)
        isHorizontal ? 'width' : 'height':
            'calc(100% - ${spaceCss(indent)} - ${spaceCss(endIndent)})',
      // Raw colour override (token colours stay on the class above and
      // contribute nothing here).
      ...?colorEmit.inline,
    };
    // `indent` is the inset at the end the line starts from, `endIndent` the
    // one at the end it finishes at. Across a horizontal line those are the
    // reading-direction sides — the right edge under `dir="rtl"` — so they
    // are the logical `margin-inline-*` pair, which the browser resolves
    // against the element's `dir`. A vertical line runs top to bottom in
    // every locale and keeps its physical sides.
    if (showLeadingIndent) {
      raw[isHorizontal ? 'margin-inline-start' : 'margin-top'] = spaceCss(
        indent,
      );
    }
    if (showTrailingIndent) {
      raw[isHorizontal ? 'margin-inline-end' : 'margin-bottom'] = spaceCss(
        endIndent,
      );
    }
    return Styles(raw: raw);
  }

  /// Composes the grid-wrapper Tailwind className (child mode only).
  ///
  /// Items sit centred across the axis (`items-center` for a row,
  /// `justify-items-center` for a column) and the wrapper fills the axis it
  /// runs along.
  String buildWrapperClassName() => isHorizontal
      ? '${WebLayout.gridFull} ${WebLayout.itemsCenter}'
      : '${WebLayout.grid} ${WebLayout.justifyItemsCenter} ${WebLayout.hFull}';

  /// Composes the wrapper's track template (child mode only): the leading
  /// line, the label, the trailing line, along the axis the divider runs on.
  ///
  /// A segment with a positive weight is a flexible track of that many `fr`:
  /// the tracks beside the label share what the label leaves by their weights,
  /// and a segment's margin is inside its track, so an inset never changes its
  /// share — the label stays where the box puts it and the inset only shortens
  /// the line. `minmax(0, …)` lets a track give way to nothing when the label
  /// takes the whole axis, where a bare `fr` would not go below its line's
  /// content. A zero weight is a track as wide as its content, which is the
  /// segment's inset, so the label sits against that edge after the inset.
  Styles buildWrapperInlineStyles() {
    String segmentTrack(int weight) =>
        weight > 0 ? 'minmax(0, ${weight}fr)' : _kCssContentTrack;

    return Styles(
      raw: {
        isHorizontal ? 'grid-template-columns' : 'grid-template-rows':
            '${segmentTrack(childAlignment.leadingFlex)} $_kCssContentTrack '
            '${segmentTrack(childAlignment.trailingFlex)}',
      },
    );
  }

  /// Composes the centred child wrapper inline-CSS — applies the
  /// resolved [childPadding] as symmetric padding along the main axis
  /// (horizontal padding for a horizontal divider, vertical for a
  /// vertical one).
  Styles buildChildWrapperInlineStyles() {
    // `childPadding` is encoded as horizontal-symmetric CoreEdgeInsets
    // (matches the design-system default); horizontal divider applies
    // it directly, vertical divider transposes the axes so the same
    // per-side value flows along its main axis.
    final perSide = spaceCss(childPadding.left);
    return Styles(
      raw: {
        if (isHorizontal) 'padding-left': perSide,
        if (isHorizontal) 'padding-right': perSide,
        if (!isHorizontal) 'padding-top': perSide,
        if (!isHorizontal) 'padding-bottom': perSide,
      },
    );
  }

  // ─── Compose paint-ready chrome ───────────────────────
  //
  // `root` is the only slot whose className / inlineStyles depend on
  // `hasChild` — single-line mode bakes the line chrome into `root`
  // directly, child-mode emits a grid wrapper and renders the three
  // child slots inside. The line / wrapper slots are always built
  // (non-null) — `co_divider` decides which branch to render.
  final rootChrome = hasChild
      ? WebElementChrome(
          className: buildWrapperClassName(),
          inlineStyles: buildWrapperInlineStyles(),
        )
      : WebElementChrome(
          className: buildLineClassName(standalone: true),
          inlineStyles: buildLineInlineStyles(
            showLeadingIndent: true,
            showTrailingIndent: true,
            standalone: true,
          ),
        );

  return ResolvedDivider(
    root: rootChrome,
    lineLeading: WebElementChrome(
      className: buildLineClassName(standalone: false),
      inlineStyles: buildLineInlineStyles(
        showLeadingIndent: true,
        showTrailingIndent: false,
      ),
    ),
    lineTrailing: WebElementChrome(
      className: buildLineClassName(standalone: false),
      inlineStyles: buildLineInlineStyles(
        showLeadingIndent: false,
        showTrailingIndent: true,
      ),
    ),
    childWrapper: WebElementChrome(
      className: '',
      inlineStyles: buildChildWrapperInlineStyles(),
    ),
  );
}
