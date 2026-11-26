import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Timeline`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                                      // flex-col + row gap
///   └─ itemRow (<div>) × items.length              // co_timeline emits one per item
///        ├─ timestamp (<div>)                      // timestamp text + width
///        ├─ Gap (columnGapStyle)                 // nested slot
///        ├─ markerColumn (<div>)                   // flex-col items-center
///        │    ├─ dot (<div>)                       // background + size + radius
///        │    └─ connector (<div>)                 // co_timeline renders only when not last
///        ├─ Gap (columnGapStyle)                 // nested slot
///        └─ contentColumn (<div>)                  // flex-1 min-w-0
///             ├─ title (<div>)                     // typography + foreground
///             └─ description (<div>)               // co_timeline renders only when description != null
/// ```
///
/// Field grouping:
///
/// 1. **Per-row slots** — [itemRow] / [timestamp] / [markerColumn] /
///    [dot] / [connector] / [contentColumn] / [title] / [description]
///    expose paint-ready className + inline CSS the widget drops
///    straight into `Component.element(classes: ..., styles: ...)`.
/// 2. **Nested gap slots** — [columnGapStyle] forwarded raw to
///    `Gap(gapStyle: …)` between the timestamp / markerColumn /
///    contentColumn siblings (Epic #1659 nested-slot pattern — no raw
///    scalar leak, Gap runs its own resolve step).
/// 3. **Outer root** — [root] for the outermost stack.
class ResolvedTimeline implements WebResolvedChrome {
  /// Creates a [ResolvedTimeline].
  const ResolvedTimeline({
    required this.root,
    required this.itemRow,
    required this.timestamp,
    required this.markerColumn,
    required this.dot,
    required this.connector,
    required this.contentColumn,
    required this.title,
    required this.description,
    required this.columnGapStyle,
  });

  /// Paint-ready chrome for the outermost `<div>` element.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for each item row `<div>`.
  final WebElementChrome itemRow;

  /// Paint-ready chrome for the timestamp `<div>`.
  final WebElementChrome timestamp;

  /// Paint-ready chrome for the marker column `<div>`.
  final WebElementChrome markerColumn;

  /// Paint-ready chrome for the dot indicator `<div>`.
  final WebElementChrome dot;

  /// Paint-ready chrome for the connector line `<div>` — always
  /// non-null; `co_timeline` decides whether to render based on item
  /// position.
  final WebElementChrome connector;

  /// Paint-ready chrome for the content column `<div>`.
  final WebElementChrome contentColumn;

  /// Paint-ready chrome for the title `<div>`.
  final WebElementChrome title;

  /// Paint-ready chrome for the description `<div>` — always non-null;
  /// `co_timeline` decides whether to render based on
  /// `item.description != null`.
  final WebElementChrome description;

  /// Nested [CoreGapStyle] slot — forwarded straight to
  /// `Gap(gapStyle: …)` between the timestamp / markerColumn /
  /// contentColumn siblings inside each item row. Carries the merged
  /// design-system default + per-instance override (raw, pre-scaling —
  /// the receiving `Gap` runs its own resolve step) per Epic #1659
  /// nested-slot pattern.
  final CoreGapStyle columnGapStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedTimeline] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.timeline.style
///   → widget.timelineStyle
/// ```
ResolvedTimeline resolveTimeline(
  BuildContext context, {
  CoreTimelineStyle? timelineStyle,
}) {
  final tlTheme = context.theme.coreComponentTheme?.timeline;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreTimelineStyle(), [
    tlTheme?.style,
    timelineStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Radius / padding / gap / size scalars are **always** emitted inline
  // (`(merged.X ?? default)` → rem) — no class-drop branch (Epic #1603
  // single-signature gate). Colour / typography keep the card model
  // (default token class + inline override).
  // Nested gap slots (Epic #1659) — merged Style + design-system
  // default. [columnGapStyle] is forwarded raw to `Gap(gapStyle: …)`
  // between siblings in the widget (no inline CSS leak). The
  // [contentTopGapStyle] still consumes `.size!` for inline `spaceCss`
  // emission on the description's margin-top (CoreGapStyle's `size` is
  // always populated through the default).
  final columnGapStyle = CoreTimelineStyle.defaultColumnGapStyle.merge(
    merged.columnGapStyle,
  );
  final contentTopGapStyle = CoreTimelineStyle.defaultContentTopGapStyle.merge(
    merged.contentTopGapStyle,
  );
  final contentTopGap = contentTopGapStyle.size!;
  final rowSpacing = merged.rowSpacing ?? CoreTimelineStyle.defaultRowSpacing;
  final dotSize = merged.dotSize ?? CoreTimelineStyle.defaultDotSize;
  final dotCornerRadius =
      merged.dotCornerRadius ?? CoreTimelineStyle.defaultDotCornerRadius;
  final dotTopMargin =
      merged.dotTopMargin ?? CoreTimelineStyle.defaultDotTopMargin;
  final connectorThickness =
      merged.connectorThickness ?? CoreTimelineStyle.defaultConnectorThickness;
  final connectorSpacing =
      merged.connectorSpacing ?? CoreTimelineStyle.defaultConnectorSpacing;
  final timeColumnWidth =
      merged.timeColumnWidth ?? CoreTimelineStyle.defaultTimeColumnWidth;
  // Logical longhands when the value is directional — the title is set in
  // from the rail, which is the start side, so a physical `padding`
  // shorthand would indent from the wrong edge in a right-to-left locale.
  final titlePadding =
      (merged.titlePadding ?? CoreTimelineStyle.defaultTitlePadding)
          .toLogicalDeclarations('padding');
  // ─── EMIT family (class XOR inline, theme-free) ───────
  // Each colour / typography value routes through the emit family — a
  // single class-XOR-inline decision per design value. Token-bound
  // defaults emit a Tailwind class (dark-mode reactive); raw overrides
  // go inline via `.toValue()` (token → `var(--coui-X)`). No
  // `scheme.resolve` (a no-op on Web) and no hand-rolled
  // `if (override != null)` / `text-${...token!.name}` branches.
  final dotColorEmit = emitColor(
    merged.dotColor,
    CoreTimelineStyle.defaultDotColor,
    .background,
  );
  final connectorColorEmit = emitColor(
    merged.connectorColor,
    CoreTimelineStyle.defaultConnectorColor,
    .background,
  );
  // Typography — `emitTypography` is the single canonical path: it emits
  // the role on a `text-{role}` class (+ token-colour / weight class) and
  // any explicit scalar / raw-colour overlay inline. The fallback default
  // is the token-backed slot, so the role class is always emitted unless
  // the caller supplies an arbitrary (token-less) override.
  final timestampEmit = emitTypography(
    merged.timestampTextStyle,
    CoreTimelineStyle.defaultTimestampTextStyle,
  );
  final titleEmit = emitTypography(
    merged.titleTextStyle,
    CoreTimelineStyle.defaultTitleTextStyle,
  );
  final descriptionEmit = emitTypography(
    merged.descriptionTextStyle,
    CoreTimelineStyle.defaultDescriptionTextStyle,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the outermost `<div>` Tailwind className.
  String buildRootClassName() =>
      '${WebLayout.relative} ${WebLayout.flex} ${WebLayout.flexCol}';

  /// Composes the outermost `<div>` inline-CSS bundle — `rowSpacing`
  /// is always inline rem (single-signature gate).
  Styles buildRootInlineStyles() => .new(raw: {'gap': spaceCss(rowSpacing)});

  /// Composes the per-item row Tailwind className. The horizontal gap
  /// between the timestamp / markerColumn / contentColumn siblings is
  /// now rendered as explicit `Gap` widgets in `co_timeline.dart`
  /// (Epic #1659 — nested `CoreGapStyle` slot, no inline CSS leak).
  String buildItemRowClassName() => WebLayout.flex;

  /// Composes the timestamp `<div>` Tailwind className. Typography role /
  /// colour class comes from [timestampEmit] (emit family — role class +
  /// token colour, with any explicit overlay routed inline instead).
  String buildTimestampClassName() => <String>[
    '${WebLayout.shrinkZero} text-right',
    timestampEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the timestamp `<div>` inline-CSS bundle — `timeColumnWidth`
  /// is always inline rem (single-signature gate), plus the emit-family
  /// typography overlay (explicit scalar / raw colour only).
  Styles buildTimestampInlineStyles() {
    final raw = {
      'width': '${timeColumnWidth / kRemDivisor}rem',
      ...?timestampEmit.inline,
    };
    return Styles(raw: raw);
  }

  /// Composes the marker column `<div>` Tailwind className.
  String buildMarkerColumnClassName() => WebLayout.flexColItemsCenter;

  /// Composes the dot `<div>` Tailwind className. The fill token follows
  /// the emit family ([dotColorEmit] — class for the token default,
  /// dropped for a raw override which goes inline). Size / corner-radius /
  /// top-margin are always inline (single-signature gate).
  String buildDotClassName() => <String>[
    WebLayout.shrinkZero,
    dotColorEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the dot `<div>` inline-CSS bundle — size / corner-radius /
  /// top-margin always inline; fill emitted inline only on a raw override
  /// (via [dotColorEmit]); the border is a per-instance override (no
  /// preset class) emitted inline theme-free (`.toValue()`).
  ///
  /// The top margin is pinned: it seats the dot against the first line
  /// of the content beside it — a position the Flutter twin leaves out of
  /// the density — so it must not name a spacing variable.
  Styles buildDotInlineStyles() {
    final raw = {
      'width': '${dotSize / kRemDivisor}rem',
      'height': '${dotSize / kRemDivisor}rem',
      'border-radius': radiusCss(dotCornerRadius),
      'margin-top': pinnedLengthCss(dotTopMargin),
      ...?dotColorEmit.inline,
    };
    if (merged.dotBorderColor != null && merged.dotBorderWidth != null) {
      raw['border'] =
          '${merged.dotBorderWidth! / kRemDivisor}rem solid '
          '${merged.dotBorderColor!.toValue()}';
    }
    return Styles(raw: raw);
  }

  /// Composes the connector `<div>` Tailwind className — the colour token
  /// follows the emit family ([connectorColorEmit] — class for the token
  /// default, dropped for a raw override which goes inline); thickness is
  /// always inline.
  String buildConnectorClassName() => <String>[
    '${WebLayout.flex1} mx-auto',
    connectorColorEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the connector `<div>` inline-CSS bundle — the gap below its
  /// own dot (`margin-top`), the reach past the row (`margin-bottom`) and
  /// always-inline thickness, plus the per-instance colour override inline
  /// (via [connectorColorEmit], raw overrides only). Mirrors the Flutter
  /// painter: the line starts [connectorSpacing] below its dot and stops
  /// [connectorSpacing] above the next one, so it runs `rowSpacing +
  /// dotTopMargin - connectorSpacing` past the bottom of its row.
  ///
  /// Summed in CSS rather than in Dart so the row spacing and the gap stay
  /// the same `--coui-space-*` operands as the row `gap`: a re-mapped
  /// variable moves them and the line reaching across them together. The
  /// dot margin is a position the Flutter twin leaves out of the density,
  /// so that part is pinned.
  Styles buildConnectorInlineStyles() {
    final reach =
        'calc(-1 * (${spaceCss(rowSpacing)} + '
        '${pinnedLengthCss(dotTopMargin)} - '
        '${spaceCss(connectorSpacing)}))';
    final raw = {
      // Stroke-axis value (mirrors Flutter's `theme.geometry.stroke` on
      // this same field) — must ride `strokeWidthCss` so the
      // neo-brutalism `strokeFloor` preset reaches it via
      // `--coui-stroke-width-N`, not a literal rem it can't override.
      'width': strokeWidthCss(connectorThickness),
      'margin-top': spaceCss(connectorSpacing),
      'margin-bottom': reach,
      ...?connectorColorEmit.inline,
    };
    return Styles(raw: raw);
  }

  /// Composes the content column `<div>` Tailwind className. `min-w-0`
  /// lets the flex item shrink below its intrinsic width so long titles
  /// / descriptions wrap instead of pushing the row sideways.
  String buildContentColumnClassName() =>
      '${WebLayout.flex1} ${WebLayout.minWZero}';

  /// Composes the title `<div>` Tailwind className. Typography role /
  /// weight / colour class comes from [titleEmit] (emit family — role +
  /// weight + token colour, with any explicit overlay routed inline
  /// instead). `titlePadding` is always inline (single-signature gate).
  String buildTitleClassName() => titleEmit.className;

  /// Composes the title `<div>` inline-CSS bundle — `titlePadding`
  /// (logical longhands, since the inset is a start-side statement) plus
  /// the emit-family typography overlay (explicit scalar / raw colour
  /// only).
  Styles buildTitleInlineStyles() {
    final raw = {
      ...titlePadding,
      ...?titleEmit.inline,
    };
    return Styles(raw: raw);
  }

  /// Composes the description `<div>` Tailwind className. Typography role
  /// / colour class comes from [descriptionEmit] (emit family — role +
  /// token colour, with any explicit overlay routed inline instead).
  /// `contentTopGap` is always inline (single-signature gate).
  String buildDescriptionClassName() => descriptionEmit.className;

  /// Composes the description `<div>` inline-CSS bundle — `contentTopGap`
  /// always inline rem, plus the emit-family typography overlay (explicit
  /// scalar / raw colour only).
  Styles buildDescriptionInlineStyles() {
    final raw = {
      'margin-top': spaceCss(contentTopGap),
      ...?descriptionEmit.inline,
    };
    return Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedTimeline(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    itemRow: WebElementChrome(className: buildItemRowClassName()),
    timestamp: WebElementChrome(
      className: buildTimestampClassName(),
      inlineStyles: buildTimestampInlineStyles(),
    ),
    markerColumn: WebElementChrome(className: buildMarkerColumnClassName()),
    dot: WebElementChrome(
      className: buildDotClassName(),
      inlineStyles: buildDotInlineStyles(),
    ),
    connector: WebElementChrome(
      className: buildConnectorClassName(),
      inlineStyles: buildConnectorInlineStyles(),
    ),
    contentColumn: WebElementChrome(className: buildContentColumnClassName()),
    title: WebElementChrome(
      className: buildTitleClassName(),
      inlineStyles: buildTitleInlineStyles(),
    ),
    description: WebElementChrome(
      className: buildDescriptionClassName(),
      inlineStyles: buildDescriptionInlineStyles(),
    ),
    columnGapStyle: columnGapStyle,
  );
}
