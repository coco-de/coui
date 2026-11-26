import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart' show CoreCubicBezierToCss;
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Upper bound used for `max-height`/`max-width` during the expand transition.
///
/// Not a design token — this is a pure CSS workaround. `max-height: auto`
/// cannot be transitioned, so the expand animation interpolates between 0
/// and this sentinel. Kept as a local constant (no token) because its value
/// carries no design intent beyond "larger than any realistic content".
const _kCssExpandedMaxSizePx = 9999;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Resolver output for `Hidden` (Web).
///
/// DOM shape:
///
/// ```text
/// root (<div>)               // transition wrapper (opacity + max-size)
///   └─ child                 // wrapped content
/// ```
///
/// `root` carries the transition wrapper chrome — empty className (the
/// hidden wrapper is purely inline-CSS driven) plus the inline-CSS
/// bundle composed by closure-local builders inside the resolver:
/// `transition` declaration, current `opacity`, and the per-direction
/// `max-height` / `max-width` + `overflow` state for the resolved
/// `hidden` flag.
class ResolvedHidden implements WebResolvedChrome {
  /// Creates a [ResolvedHidden].
  const ResolvedHidden({required this.root});

  /// Paint-ready chrome for the transition wrapper `<div>`. The
  /// className is `''` (no Tailwind classes) and the inline styles
  /// bundle the `transition` + `opacity` + `max-height` / `max-width`
  /// + `overflow` rules for the current `hidden` state.
  @override
  final WebElementChrome root;
}

// ═══════════════════════════════════════════════════
// Resolver — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedHidden] for [Hidden].
///
/// Priority (per-field): widget value > `CoreComponentTheme.hidden`
/// > design-system default.
///
/// The `hidden` flag flips the wrapper between visible and collapsed
/// states each rebuild, so the root chrome is recomposed for the
/// current value here and exposed via [ResolvedHidden.root].
ResolvedHidden resolveHidden(
  BuildContext context, {
  required bool hidden,
  CoreHiddenDirection? direction,
  Duration? duration,
  bool? keepSpace,
  bool? reverse,
  CoreCubicBezier? curve,
}) {
  final coreTheme = context.theme.coreComponentTheme?.hidden;

  // ─── Merge chain ──────────────────────────────────────
  // Folds the project theme's chrome style over the design-system
  // default. The per-instance transition duration / easing are sourced
  // from the merged style — `Hidden` has no per-instance style slot, so
  // the chain carries only the theme override.
  final merged = resolveStyleChain(const CoreHiddenStyle(), [
    coreTheme?.style,
  ]);

  final effectiveDirection = direction ?? coreTheme?.direction ?? .vertical;
  // Transition duration precedence: behavioural `duration` (widget /
  // theme fast-path) wins, else the chrome merge chain
  // (`merged.transitionDuration ?? CoreHiddenStyle
  // .defaultTransitionDuration`). The default is the same token Flutter
  // consumes, keeping both platforms in lockstep.
  final effectiveDuration =
      duration ??
      coreTheme?.duration ??
      merged.transitionDuration ??
      CoreHiddenStyle.defaultTransitionDuration;
  final effectiveKeepSpace = keepSpace ?? coreTheme?.keepSpace ?? false;
  final effectiveReverse = reverse ?? coreTheme?.reverse ?? false;
  // Easing follows the same precedence, and both platforms read the same
  // `CoreCubicBezier` — Flutter converts it to a `Curve`, Web to the
  // `cubic-bezier(...)` timing function below.
  final effectiveCurve =
      curve ??
      coreTheme?.curve ??
      merged.transitionCurve ??
      CoreHiddenStyle.defaultTransitionCurve;
  final timingFunction = effectiveCurve.toCss();

  // ─── Local builders ───────────────────────────────────

  /// Composes the transition wrapper `<div>` inline CSS — the
  /// `transition` declaration (opacity + max-height + max-width over
  /// the resolved duration and easing), the current `opacity`, the
  /// per-direction
  /// `max-height` / `max-width` collapse rule (when `hidden` and
  /// `keepSpace == false`), the matching `overflow: hidden` clip, the
  /// optional `pointer-events: none` while hidden, the optional
  /// `transform-origin` for `reverse`, and the expanded-state
  /// `max-{height|width}` sentinel for the visible state.
  Styles buildRootInlineStyles() {
    final ms = effectiveDuration.inMilliseconds;
    final styleMap = {
      'transition':
          'opacity ${ms}ms $timingFunction, '
          'max-height ${ms}ms $timingFunction, '
          'max-width ${ms}ms $timingFunction',
      'opacity': hidden ? '0' : '1',
    };

    // Reverse collapses from the trailing edge.
    if (effectiveReverse) {
      styleMap['transform-origin'] = effectiveDirection == .vertical
          ? 'bottom'
          : 'right';
    }

    if (hidden) {
      styleMap['pointer-events'] = 'none';
      if (!effectiveKeepSpace) {
        switch (effectiveDirection) {
          case .vertical:
            styleMap['max-height'] = '0';
          case .horizontal:
            styleMap['max-width'] = '0';
        }
        styleMap['overflow'] = WebLayout.hidden;
      }
    } else {
      // `_kCssExpandedMaxSizePx` is a CSS sentinel (not a design token).
      // Divide by 16 so the guard's rem escape-hatch accepts it; the
      // resulting ~625rem is still far larger than any realistic content.
      switch (effectiveDirection) {
        case .vertical:
          styleMap['max-height'] = '${_kCssExpandedMaxSizePx / kRemDivisor}rem';
        case .horizontal:
          styleMap['max-width'] = '${_kCssExpandedMaxSizePx / kRemDivisor}rem';
      }
    }

    return Styles(raw: styleMap);
  }

  return ResolvedHidden(
    root: WebElementChrome(
      className: '',
      inlineStyles: buildRootInlineStyles(),
    ),
  );
}
