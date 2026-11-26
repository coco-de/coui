/// Style-slot single entry point for the Web `Switcher`.
///
/// Mirrors the Flutter `switcher_style.dart`: a `resolveSwitcher`
/// merge function that walks the nested merge chain
/// (`CoreSwitcherStyle.defaultDuration` / `defaultCurve` →
/// `theme.switcher.style` → `widget.switcherStyle`) and ships back a
/// [ResolvedSwitcher] paint-ready chrome bundle.
///
/// All slots — including the sliding track and each per-item slot
/// (their chrome depends on the runtime `direction` / `position` /
/// `itemCount` / `dragging` flags) — flow through the single
/// [resolveSwitcher] entry point so `co_switcher.dart` only reads
/// `resolved.<slot>.className / inlineStyles`, never composing inline
/// CSS itself.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart' show CoreCubicBezierToCss;
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart' show BuildContext;

/// Percentage multiplier for full-width / full-height slides.
///
/// Not a design token — the geometric `100%` of a single track step.
const int _kSlidePercent = 100;

/// Decimal precision used when serialising the fractional fade
/// opacity into an inline CSS string.
///
/// Not a design token — a string-formatting precision.
const int _kOpacityPrecision = 3;

/// Decimal precision used when serialising the per-slot flex-basis
/// (`100 / itemCount %`, which repeats for non-divisor counts) into an
/// inline CSS string.
///
/// Not a design token — a string-formatting precision.
const int _kSlotBasisPrecision = 4;

// ════════════════════════════════════════════════════════════════
// ResolvedSwitcher
// ════════════════════════════════════════════════════════════════

/// Paint-ready chrome for Web `Switcher`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="group" relative overflow-hidden>)   // viewport
///   └─ track (<div display:flex transform>)            // sliding track
///        └─ <div flex:0 0 100%> × n   (slots)          // per-item slots
/// ```
///
/// Every slot is a paint-ready [WebElementChrome] — `co_switcher.dart`
/// reads `resolved.<slot>.className` / `resolved.<slot>.inlineStyles`
/// straight off. Runtime state (`direction` / `position` / `itemCount` /
/// `dragging`) flows into [resolveSwitcher] as arguments; the widget
/// re-invokes the resolver every build.
class ResolvedSwitcher implements WebResolvedChrome {
  /// Creates a [ResolvedSwitcher].
  const ResolvedSwitcher({
    required this.root,
    required this.track,
    required this.slots,
  });

  /// Paint-ready chrome for the viewport `<div role="group">` — clips
  /// the sliding track to the viewport via `relative overflow-hidden`.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the sliding track `<div>` — flex container
  /// translated by `position × -100%` along the slide axis.
  final WebElementChrome track;

  /// Paint-ready chrome for each child slot `<div>` (one entry per
  /// item). Each slot takes the full viewport along the slide axis and
  /// fades based on its distance from the active fractional position.
  final List<WebElementChrome> slots;
}

// ════════════════════════════════════════════════════════════════
// resolveSwitcher — single entry point
// ════════════════════════════════════════════════════════════════

/// Resolves [ResolvedSwitcher] for the given [context].
///
/// Walks the 2-stage merge chain and applies the
/// `CoreSwitcherStyle.defaultX` static const fallbacks so the entry
/// reads only fully-resolved CSS-ready values:
///
/// ```text
/// CoreSwitcherStyle.defaultDuration / defaultCurve   // design system default
///   → theme.coreComponentTheme.switcher.style
///   → widget.switcherStyle
/// ```
ResolvedSwitcher resolveSwitcher(
  BuildContext context, {
  required CoreSwitcherDirection direction,
  required double position,
  required int itemCount,
  required bool dragging,
  CoreSwitcherStyle? switcherStyle,
}) {
  final switcherTheme = context.theme.coreComponentTheme?.switcher;

  final merged = resolveStyleChain(const CoreSwitcherStyle(), [
    switcherTheme?.style,
    switcherStyle,
  ]);

  final durationMs =
      (merged.duration ?? CoreSwitcherStyle.defaultDuration).inMilliseconds;
  // Same `CoreCubicBezier` the Flutter twin turns into a `Curve`; here it
  // becomes the `cubic-bezier(...)` timing function of the inline
  // `transition` shorthand, so one token drives both platforms.
  final timingFunction = (merged.curve ?? CoreSwitcherStyle.defaultCurve)
      .toCss();

  // ─── Local builders ───────────────────────────────────

  /// Composes the viewport `<div role="group">` Tailwind className —
  /// `h-full w-full` fills the parent box (mirroring the Flutter render
  /// object that fills its `SizedBox` constraints) so the slides have a
  /// height to occupy; `relative overflow-hidden` clips the sliding
  /// track so off-screen slides stay hidden.
  String buildRootClassName() =>
      '${WebLayout.relativeOverflowHidden} ${WebLayout.hFull} ${WebLayout.wFull}';

  /// Composes the track `<div>` inline-CSS bundle — flex layout
  /// (row / column depending on the axis), the directional translate
  /// transform, the slide-transition (disabled while dragging), and
  /// the track size that covers `itemCount` slides.
  Styles buildTrackInlineStyles() {
    final isHorizontal = direction.isHorizontal;
    // Paging to slide `position` must bring that slot into the clipped
    // viewport: for `left`/`up` the track advances toward a negative
    // translate (slot `position` sits at `+position * slideWidth`, so we
    // translate by `-position * slideWidth`); `right`/`down` reverse it.
    final sign = (direction == .up || direction == .left) ? 1 : -1;
    // The track is `itemCount * 100%` of the viewport, so one slide is
    // `100 / itemCount %` of the track. Translate and slot sizing are
    // track-relative, so they must use that fraction — not a flat 100%,
    // which sized each slot to the whole track and pushed the centred
    // slide content outside the clipped viewport.
    final slidePercentOfTrack = _kSlidePercent / itemCount;
    final offsetPercent = position * slidePercentOfTrack * sign;
    final transform = isHorizontal
        ? 'translateX(${-offsetPercent}%)'
        : 'translateY(${-offsetPercent}%)';
    final sizePercent = itemCount * _kSlidePercent;

    return Styles(
      raw: {
        'display': 'flex',
        'flex-direction': isHorizontal ? 'row' : 'column',
        'transform': transform,
        'transition': dragging
            ? 'none'
            : 'transform ${durationMs}ms $timingFunction',
        // Main axis covers `itemCount` slides; the cross axis fills the
        // viewport (100%) so each slot — and its `h-full` content —
        // gets the viewport height/width to occupy.
        if (isHorizontal) ...{
          'width': '$sizePercent%',
          'height': '100%',
        } else ...{
          'height': '$sizePercent%',
          'width': '100%',
        },
      },
    );
  }

  /// Composes a single slot `<div>` inline-CSS bundle — `flex: 0 0
  /// 100%` makes each slot take the full viewport along the slide
  /// axis, `opacity` fades the slot proportionally to its distance from
  /// the active position, and the opacity transition (disabled while
  /// dragging) smooths slides between two stable positions.
  Styles buildSlotInlineStyles(int slotIndex) {
    final distance = (slotIndex - position).abs().clamp(0.0, 1.0);
    final opacity = (1 - distance).toStringAsFixed(_kOpacityPrecision);
    return Styles(
      raw: {
        // Each slot spans exactly one viewport = `100 / itemCount %` of
        // the track (which is `itemCount * 100%` wide), so the centred
        // slide content lands inside the clipped viewport.
        WebLayout.flex:
            '0 0 ${(_kSlidePercent / itemCount).toStringAsFixed(_kSlotBasisPrecision)}%',
        'opacity': opacity,
        'transition': dragging
            ? 'none'
            : 'opacity ${durationMs}ms $timingFunction',
      },
    );
  }

  return ResolvedSwitcher(
    root: WebElementChrome(className: buildRootClassName()),
    track: WebElementChrome(
      className: '',
      inlineStyles: buildTrackInlineStyles(),
    ),
    slots: [
      for (var i = 0; i < itemCount; i++)
        WebElementChrome(
          className: '',
          inlineStyles: buildSlotInlineStyles(i),
        ),
    ],
  );
}
