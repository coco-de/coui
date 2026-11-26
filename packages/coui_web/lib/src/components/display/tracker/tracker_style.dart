library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Tracker`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                          // horizontal flex row
///   ├─ segmentTooltip (Tooltip)       // per-segment wrapper, flex-1 + height
///   │    └─ segments[0] (<div>)         // status-coloured fill
///   ├─ segmentTooltip ...               // next segment
///   │    └─ segments[1] (<div>)
///   └─ ...
/// ```
///
/// All slot chromes are non-null — `co_tracker` reads
/// `resolved.<slot>.className` / `resolved.<slot>.inlineStyles`
/// straight off. The outer flex row's inter-segment `gap` CSS is
/// derived from the resolved `itemSpacing` and lives on
/// [root].`inlineStyles`. The per-segment fill chrome (per-status
/// background colour + optional rounded ends on the first / last
/// segment) is pre-composed by [resolveTracker] into
/// [ResolvedTracker.segments]; the widget iterates the list
/// directly.
///
/// Runtime state (`segments` + `rounded`) flows in as resolver
/// arguments.
class ResolvedTracker implements WebResolvedChrome {
  /// Creates a [ResolvedTracker].
  const ResolvedTracker({
    required this.root,
    required this.segmentTooltip,
    required this.segments,
  });

  /// Paint-ready chrome for the outer `<div>` — horizontal flex
  /// className plus inter-segment `gap` inline CSS.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the per-segment `Tooltip` wrapper —
  /// `flex-1` className plus `height` inline CSS (logical px → rem).
  /// Reused on every segment (the per-segment variation lives in
  /// [segments], not in the tooltip wrapper).
  final WebElementChrome segmentTooltip;

  /// Paint-ready chrome for each segment fill `<div>` — one entry per
  /// input segment, indexed by position. Combines `w-full h-full`
  /// layout, the per-status `bg-${color.tailwindColor}` Tailwind class
  /// (or the caller's `segmentColor` override), and the optional
  /// left/right `border-radius` inline rem rule on the first / last
  /// segments when `rounded` is true (mirrors the Flutter
  /// `BorderRadius.horizontal` — the `endRadius` always renders inline,
  /// never via a Tailwind radius class, per Epic #1603 single
  /// signature gate).
  final List<WebElementChrome> segments;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedTracker] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreTrackerStyle.defaultX /
///   defaultsByStatus[status])
///   → theme.coreComponentTheme.tracker.style
///   → widget.trackerStyle
/// ```
///
/// [segments] / [rounded] are the per-build runtime inputs — the
/// resolver pre-composes per-segment fill chrome bundles into
/// [ResolvedTracker.segments].
ResolvedTracker resolveTracker(
  BuildContext context, {
  required List<CoreTrackerSegment> segments,
  required bool rounded,
  CoreTrackerStyle? trackerStyle,
}) {
  final trackerTheme = context.theme.coreComponentTheme?.tracker;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreTrackerStyle(), [
    trackerTheme?.style,
    trackerStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Each value finished its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly).
  final itemHeight = merged.itemHeight ?? CoreTrackerStyle.defaultItemHeight;
  final itemSpacing = merged.itemSpacing ?? CoreTrackerStyle.defaultItemSpacing;
  // Border radius (logical px) — `(merged ?? default)` resolved once.
  // The outer-end radius is **always** emitted inline via `radiusCss`
  // (a token value rides `var(--coui-radius-N)`, reactive to a
  // strokeFloor/radiusCap surface style; an arbitrary override falls
  // back to a literal), never via a Tailwind radius class, so the
  // override path and the default path share the same CSS surface
  // (Epic #1603 single signature gate — radius is always-inline). The
  // rounded ends are still gated on `rounded`.
  final endRadius = merged.endRadius ?? CoreTrackerStyle.defaultEndRadius;
  final endRadiusRem = radiusCss(endRadius);
  final segmentColorOverride = merged.segmentColor;

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer `<div>` Tailwind className — horizontal flex
  /// row that stretches to fill the parent width.
  String buildRootClassName() => WebLayout.flexFull;

  /// Composes the outer `<div>` inline CSS — horizontal `gap` between
  /// segments (logical px → `spaceCss`). Mirrors the Flutter `Row.spacing`
  /// argument — both consume the same resolved `itemSpacing` raw
  /// double.
  Styles buildRootInlineStyles() => .new(raw: {'gap': spaceCss(itemSpacing)});

  /// Composes the per-segment `Tooltip` wrapper className — `flex-1`
  /// so each segment shares the remaining space equally, plus `grid` so
  /// the tooltip's inner trigger (and the segment fill inside it)
  /// stretches to fill the cell. Without `grid` the `inline-flex`
  /// trigger sizes to its (empty) content and the segment collapses to
  /// 0 width — the bar would be invisible.
  String buildSegmentTooltipClassName() =>
      '${WebLayout.flex1} ${WebLayout.grid}';

  /// Composes the per-segment `Tooltip` wrapper inline CSS —
  /// `height` in rem derived from the resolved itemHeight.
  Styles buildSegmentTooltipInlineStyles() =>
      .new(raw: {'height': '${itemHeight / kRemDivisor}rem'});

  /// Composes a segment fill `<div>` Tailwind className — full-fill
  /// layout and per-status background colour (or the global override).
  /// The outer-end radius is emitted inline (see
  /// [buildSegmentInlineStyles]), never as a Tailwind radius class.
  ///
  /// Status → color tokens come from
  /// [CoreTrackerStyle.defaultsByStatus] single source — Flutter side
  /// maps the same constants via `colorScheme.resolve(...)` so the
  /// two platforms stay in lock-step.
  String buildSegmentClassName(CoreTrackerStatus status) {
    final color =
        segmentColorOverride ??
        CoreTrackerStyle.defaultsByStatus[status]!.segmentColor!;
    return [
      WebLayout.wFull,
      WebLayout.hFull,
      'bg-${color.tailwindColor}',
    ].join(' ');
  }

  /// Composes a segment fill `<div>` inline CSS — the always-inline
  /// outer-end `border-radius` rem rule. Mirrors the Flutter
  /// `BorderRadius.horizontal(left:, right:)`: the first segment rounds
  /// its left corners, the last segment its right corners, the middle
  /// segments stay square. Returns `null` (no inline radius) when
  /// `rounded` is false or the segment is neither first nor last.
  Styles? buildSegmentInlineStyles({
    required bool isFirst,
    required bool isLast,
  }) {
    if (!rounded || (!isFirst && !isLast)) return null;
    final raw = <String, String>{};
    if (isFirst) {
      raw['border-top-left-radius'] = endRadiusRem;
      raw['border-bottom-left-radius'] = endRadiusRem;
    }
    if (isLast) {
      raw['border-top-right-radius'] = endRadiusRem;
      raw['border-bottom-right-radius'] = endRadiusRem;
    }
    return Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  final lastIndex = segments.length - 1;
  final segmentChromes = <WebElementChrome>[
    for (var i = 0; i < segments.length; i++)
      WebElementChrome(
        className: buildSegmentClassName(segments[i].status),
        inlineStyles: buildSegmentInlineStyles(
          isFirst: i == 0,
          isLast: i == lastIndex,
        ),
      ),
  ];

  return ResolvedTracker(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    segmentTooltip: WebElementChrome(
      className: buildSegmentTooltipClassName(),
      inlineStyles: buildSegmentTooltipInlineStyles(),
    ),
    segments: segmentChromes,
  );
}
