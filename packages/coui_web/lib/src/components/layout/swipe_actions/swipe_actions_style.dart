import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// Structural vocabulary — pure layout, no chrome (web-specifics: named-const
// layout vocabulary). `clip` rather than `hidden`: a clipped box is not a
// scroll container, so focusing an action inside a platter that is narrower
// than its strip cannot scroll the strip out of place.
const String _kOverflowClip = 'overflow-clip';
const String _kOverflowXClip = 'overflow-x-clip';
const String _kStartZero = 'start-0';
const String _kEndZero = 'end-0';
const String _kSelectNone = 'select-none';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `SwipeActions`.
///
/// DOM shape (`swipe_actions.dart` decides which optional branches render):
///
/// ```text
/// root (<div>)                              // clips the row's travel
///   ├─ leadingPlatter (<div>)               // start edge, width = reveal
///   │    └─ strip (<div>)                   // natural width, outer edge first
///   │         └─ cell (<div>)  × n          // fixed width
///   │              ├─ Button(actionButtonStyle)   // aria-label = label
///   │              ├─ Gap(labelGapStyle)
///   │              └─ label (<div>)         // aria-hidden, one line
///   ├─ row (<div>)                          // translateX(offset)
///   │    ├─ child
///   │    └─ tapCatcher (<div>)              // only while open
///   └─ trailingPlatter (<div>)              // end edge, width = reveal
///        └─ strip (<div>)                   // DOM order = visual order
/// ```
///
/// Only the carriers are exposed: every length is already folded into the
/// chrome slots, and the two nested slots go raw to the composed `Button`
/// and `Gap`, which resolve themselves.
class ResolvedSwipeActions implements WebResolvedChrome {
  /// Creates a [ResolvedSwipeActions].
  const ResolvedSwipeActions({
    required this.root,
    required this.row,
    required this.leadingPlatter,
    required this.trailingPlatter,
    required this.strip,
    required this.cell,
    required this.outerCell,
    required this.label,
    required this.tapCatcher,
    required this.labelGapStyle,
    required this.actionButtonStyle,
  });

  /// Outer `<div>` — clips the row where it slides past the edge and claims
  /// vertical panning for the browser (`touch-action: pan-y`).
  @override
  final WebElementChrome root;

  /// The sliding row `<div>` — `translateX(offset)`, no transition while a
  /// pointer moves it.
  final WebElementChrome row;

  /// The platter at the start edge: as wide as the row has uncovered, holding
  /// its strip against the outer edge.
  final WebElementChrome leadingPlatter;

  /// The platter at the end edge.
  final WebElementChrome trailingPlatter;

  /// The strip of cells inside a platter, at its natural width — the width
  /// the row model measures as how far that side opens.
  final WebElementChrome strip;

  /// One action cell: a fixed-width column holding a button and its label.
  final WebElementChrome cell;

  /// The cell of a side's first (outermost) action — a [cell] that also
  /// carries the full-swipe cue (`fullSwipeScale`) while the pull is far
  /// enough to run it.
  final WebElementChrome outerCell;

  /// The label under a button: the label role's classes, one line, cut with
  /// an ellipsis at the cell's width.
  final WebElementChrome label;

  /// The overlay over an open row: a tap on it closes the row instead of
  /// reaching the row's content.
  final WebElementChrome tapCatcher;

  /// Nested [CoreGapStyle] slot — raw-forwarded to the `Gap` between a
  /// button and its label.
  final CoreGapStyle labelGapStyle;

  /// Nested [CoreButtonStyle] slot — raw-forwarded to each composed
  /// `Button`; `null` when nothing was stated, and the button resolves its
  /// own chrome.
  final CoreButtonStyle? actionButtonStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedSwipeActions] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.swipeActions.style
///   → widget.swipeActionsStyle
/// ```
///
/// The row's runtime state flows in as args: [offset] is where the row is
/// painted (physical px, positive toward the right), [revealedSide] is the
/// platter that position uncovers, [dragging] is whether a pointer is moving
/// the row, and [inFullSwipeZone] whether releasing now would run the first
/// action.
ResolvedSwipeActions resolveSwipeActions(
  BuildContext context, {
  required double offset,
  required CoreSwipeSide? revealedSide,
  required bool dragging,
  required bool inFullSwipeZone,
  required bool interactive,
  CoreSwipeActionsStyle? swipeActionsStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.swipeActions;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreSwipeActionsStyle(), [
    csTheme?.style,
    swipeActionsStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  final actionWidth =
      merged.actionWidth ?? CoreSwipeActionsStyle.defaultActionWidth;
  final actionSpacing =
      merged.actionSpacing ?? CoreSwipeActionsStyle.defaultActionSpacing;
  final platterInset =
      merged.platterInset ?? CoreSwipeActionsStyle.defaultPlatterInset;
  final platterColor =
      merged.platterColor ?? CoreSwipeActionsStyle.defaultPlatterColor;
  final fullSwipeScale =
      merged.fullSwipeScale ?? CoreSwipeActionsStyle.defaultFullSwipeScale;
  final labelGapStyle = CoreSwipeActionsStyle.defaultLabelGapStyle.merge(
    merged.labelGapStyle,
  );
  // Default-less on purpose (Core): an unset slot forwards nothing and each
  // composed `Button` resolves its own chrome; a stated one goes through raw.
  final actionButtonStyle = merged.actionButtonStyle;

  // Token-routed duration + easing: the `--coui-duration-*` variable is what
  // `prefers-reduced-motion` zeroes, so the settle needs no branch of its own.
  // The settle is the one motion the platforms draw differently (Flutter rides
  // a spring, here a CSS ease), so it has its own curve; the full-swipe cue is
  // the same scale animation on both and takes the `move` curve Flutter does.
  final settleMs =
      CoreSwipeActionsContract.defaultSettleDuration.inMilliseconds;
  final settleTiming =
      '${durationMsCss(settleMs)} ${CoreEasing.enter.toVarCss()}';
  final cueTiming = '${durationMsCss(settleMs)} ${CoreEasing.move.toVarCss()}';

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────
  final labelEmit = emitTypography(
    merged.labelStyle,
    CoreSwipeActionsStyle.defaultLabelStyle,
  );
  // A transparent platter paints nothing — omit the fill rather than emit a
  // `transparent` that would only sit in the way of a caller's own class.
  final platterEmit = platterColor.isTransparent
      ? null
      : emitColor(platterColor, platterColor, .background);

  // ─── Local builders ───────────────────────────────────

  /// The `<div>` that clips the row's travel. `overflow-x` only, so a focus
  /// ring that spills over the row's top or bottom edge stays visible.
  WebElementChrome buildRootChrome() => .new(
    className: <String>[
      WebLayout.relative,
      _kOverflowXClip,
      if (dragging) _kSelectNone,
    ].join(' '),
    inlineStyles: interactive
        ? const Styles(raw: {'touch-action': 'pan-y'})
        : null,
  );

  /// The sliding row. Both the transform and the platters' widths settle on
  /// the same duration and curve, so a platter's edge keeps meeting the row's.
  WebElementChrome buildRowChrome() => .new(
    className: WebLayout.relative,
    inlineStyles: Styles(
      raw: {
        'transform': offset == 0
            ? 'none'
            : 'translateX(${measuredPxCss(offset)})',
        'transition': dragging ? 'none' : 'transform $settleTiming',
      },
    ),
  );

  /// A platter anchored at the outer edge of [side] and clipped to what the
  /// row has uncovered there.
  WebElementChrome buildPlatterChrome(CoreSwipeSide side) {
    final leading = side == CoreSwipeSide.leading;
    final reveal = revealedSide == side ? offset.abs() : 0.0;

    return WebElementChrome(
      className: <String>[
        WebLayout.absolute,
        WebLayout.insetYZero,
        _kOverflowClip,
        WebLayout.flex,
        if (leading) ...[_kStartZero, WebLayout.justifyStart],
        if (!leading) ...[_kEndZero, WebLayout.justifyEnd],
        ?platterEmit?.className,
      ].where((cls) => cls.isNotEmpty).join(' '),
      inlineStyles: Styles(
        raw: {
          'width': measuredPxCss(reveal),
          'transition': dragging ? 'none' : 'width $settleTiming',
          ...?platterEmit?.inline,
        },
      ),
    );
  }

  /// The strip at its natural width, so the platter clips it rather than
  /// squeezing it: its width is `2 × inset + n × cell + (n − 1) × spacing`.
  WebElementChrome buildStripChrome() => .new(
    className: <String>[
      WebLayout.flexRowItemsCenter,
      WebLayout.shrinkZero,
      WebLayout.hFull,
      WebLayout.wMax,
    ].join(' '),
    inlineStyles: Styles(
      raw: {
        'padding-inline': spaceCss(platterInset),
        'gap': spaceCss(actionSpacing),
      },
    ),
  );

  /// One cell. The outermost carries the full-swipe cue, with a transition of
  /// its own (the `move` curve, as Flutter's `AnimatedScale`): the row's
  /// `transition: none` while dragging must not reach it, since the cue
  /// happens during the drag.
  WebElementChrome buildCellChrome({required bool outermost}) {
    final cue = outermost && fullSwipeScale != 1;

    return WebElementChrome(
      className: '${WebLayout.flexColItemsCenter} ${WebLayout.shrinkZero}',
      inlineStyles: Styles(
        raw: {
          'width': controlHeightCss(actionWidth),
          if (cue) ...{
            'transform': inFullSwipeZone ? 'scale($fullSwipeScale)' : 'none',
            'transition': 'transform $cueTiming',
          },
        },
      ),
    );
  }

  /// The label wrapper: the label role's classes, which the `Text` inside
  /// inherits, then one centred line cut at the cell's width.
  WebElementChrome buildLabelChrome() => .new(
    className: <String>[
      labelEmit.className,
      WebLayout.truncate,
      WebLayout.wFull,
    ].where((cls) => cls.isNotEmpty).join(' '),
    inlineStyles: Styles(
      raw: {'text-align': 'center', ...?labelEmit.inline},
    ),
  );

  /// Covers the open row. It lives inside the row, so it moves with it, and
  /// sits above the row's own content.
  WebElementChrome buildTapCatcherChrome() => const .new(
    className: WebLayout.absoluteFull,
    inlineStyles: Styles(raw: {'z-index': '${CoreZIndex.z0}'}),
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedSwipeActions(
    root: buildRootChrome(),
    row: buildRowChrome(),
    leadingPlatter: buildPlatterChrome(CoreSwipeSide.leading),
    trailingPlatter: buildPlatterChrome(CoreSwipeSide.trailing),
    strip: buildStripChrome(),
    cell: buildCellChrome(outermost: false),
    outerCell: buildCellChrome(outermost: true),
    label: buildLabelChrome(),
    tapCatcher: buildTapCatcherChrome(),
    labelGapStyle: labelGapStyle,
    actionButtonStyle: actionButtonStyle,
  );
}
