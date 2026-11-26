/// The Web page transition — the browser's view transition between two
/// documents, timed and shaped by `CorePageTransitionStyle`.
///
/// Mirrors the Flutter `page_transition_style.dart`:
/// [resolvePageTransitionRules] walks the merge chain
/// (`CorePageTransitionStyle.defaultX` → `theme.pageTransition.style` →
/// `pageTransitionStyle`) and ships back the rules `CoUIWeb` puts in the
/// document head.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart'
    show CoreCubicBezierToVarCss, durationMsCss, pinnedLengthCss;
import 'package:jaspr/jaspr.dart' show BuildContext;

/// `id` of the `<style>` `CoUIWeb` puts in the head. Head elements with the
/// same `id` collapse into one, so a page with several `CoUIWeb` roots
/// states the rules once.
const String kPageTransitionStyleId = 'coui-page-transition';

/// `id` of the `<script>` that marks a back navigation — see
/// [kPageTransitionDirectionScript].
const String kPageTransitionScriptId = 'coui-page-transition-direction';

/// Marks a view transition that goes back through history with the `back`
/// type, so the rules can play the closing motion instead of the opening
/// one.
///
/// A document cannot tell from CSS alone which way the user went. The
/// Navigation API can: `navigation.activation` names the entry the page was
/// reached from, and a traversal to a lower index is a step back. Without
/// that API (or without script) every navigation plays the opening motion.
///
/// It has to run before the page is first shown, so it is a classic script
/// in the head. It belongs to the document: the client keeps a server's
/// script, or installs it once for a client-only document. Mounting or
/// unmounting an app root does not add another direction listener.
const String kPageTransitionDirectionScript =
    "addEventListener('pagereveal', function (e) { "
    'var t = e.viewTransition, '
    'a = window.navigation && navigation.activation; '
    "if (!t || !a || !a.from || a.navigationType !== 'traverse') return; "
    "if (a.entry.index < a.from.index) t.types.add('back'); });";

/// Name of the keyframes a new page arrives with.
const String _kEnterKeyframes = 'coui-page-enter';

/// Name of the keyframes a page leaves with on a step back.
const String _kExitKeyframes = 'coui-page-exit';

/// The `<style>` text of the Web page transition.
///
/// ```text
/// @media (prefers-reduced-motion:no-preference) {
///   @view-transition { navigation: auto }      // same-origin page loads
///   old page: stays                            // the page underneath
///   new page: fades in, rising into place      // enter duration · curve
///   back:  old page fades out, sinking back    // exit duration · curve
///          new page: stays
/// }
/// ```
///
/// The Flutter twin draws the same two motions on a push and a pop. One
/// thing differs: while the transition plays, Chrome sends a click to the
/// document rather than to the page under it (`pointer-events: none` on the
/// pictures does not change that), so the page takes clicks again when the
/// transition ends. A Flutter page takes taps while it arrives.
class ResolvedPageTransitionRules {
  /// Creates a [ResolvedPageTransitionRules].
  const ResolvedPageTransitionRules({required this.css});

  /// The rules, or an empty string when the style turns both motions off.
  final String css;
}

/// Resolves [ResolvedPageTransitionRules] for the given [context].
///
/// A reduced-motion request turns the transition off: every rule sits
/// inside `prefers-reduced-motion: no-preference`, so the browser swaps the
/// page at once — the Flutter twin's answer for the same request.
ResolvedPageTransitionRules resolvePageTransitionRules(
  BuildContext context, {
  CorePageTransitionStyle? pageTransitionStyle,
}) {
  final pageTransitionTheme = context.theme.coreComponentTheme?.pageTransition;

  final merged = resolveStyleChain(const CorePageTransitionStyle(), [
    pageTransitionTheme?.style,
    pageTransitionStyle,
  ]);

  final enterMs =
      (merged.enterDuration ?? CorePageTransitionStyle.defaultEnterDuration)
          .inMilliseconds;
  final exitMs =
      (merged.exitDuration ?? CorePageTransitionStyle.defaultExitDuration)
          .inMilliseconds;
  if (enterMs <= 0 && exitMs <= 0) {
    return const ResolvedPageTransitionRules(css: '');
  }

  // ─── Stage 2 EMIT ─────────────────────────────────────
  final enterDuration = durationMsCss(enterMs);
  final exitDuration = durationMsCss(exitMs);
  final enterCurve =
      (merged.enterCurve ?? CorePageTransitionStyle.defaultEnterCurve)
          .toVarCss();
  final exitCurve =
      (merged.exitCurve ?? CorePageTransitionStyle.defaultExitCurve).toVarCss();
  // A length, not a spacing step: the density setting does not move it.
  final slideDistance = pinnedLengthCss(
    merged.slideDistance ?? CorePageTransitionStyle.defaultSlideDistance,
  );

  const back = 'html:active-view-transition-type(back)';
  final css = StringBuffer()
    ..write('@media (prefers-reduced-motion:no-preference){')
    ..write('@view-transition{navigation:auto;}')
    // The page underneath stays put while the new one arrives over it.
    ..write('::view-transition-old(root){animation:none;}')
    ..write(
      '::view-transition-new(root){animation: '
      '$_kEnterKeyframes $enterDuration $enterCurve both;}',
    )
    // A step back plays the pop: the page leaving sinks and fades over the
    // page it returns to, which stays put. The leaving page is drawn on
    // top — by default the new page would cover it.
    ..write(
      '$back::view-transition-old(root){z-index:1;animation: '
      '$_kExitKeyframes $exitDuration $exitCurve both;}',
    )
    ..write('$back::view-transition-new(root){animation:none;}')
    ..write('}')
    ..write(
      '@keyframes $_kEnterKeyframes{from{opacity:0; '
      'transform:translateY($slideDistance);}}',
    )
    ..write(
      '@keyframes $_kExitKeyframes{to{opacity:0; '
      'transform:translateY($slideDistance);}}',
    );

  return ResolvedPageTransitionRules(css: css.toString());
}
