/// Shared open/close motion chrome for portal-mounted overlay panels
/// (`Popover` + the menu family: `DropdownMenu` / `ContextMenu` /
/// `Menubar` / `NavigationMenu`).
///
/// The motion is a scale `0.9 → 1.0` + fade, mirroring Flutter's
/// `popover_overlay.dart` (`_kScaleAnimationMin` / `_kScaleAnimationMax`).
/// It is driven by a CSS **animation** (the `co-overlay-enter` /
/// `co-overlay-exit` `@keyframes` injected by `OverlayHost`), **not** a
/// transition.
///
/// **The box scales; the panel inside it fades.** The fade is not on the box:
/// an opacity on the box would put the whole panel into one layer, and a glass
/// panel's blur would then read a layer with nothing in it (see `_kFadeCss` in
/// `overlay_host.dart`). The box carries what its child needs to play the fade
/// — the length, the easing and the names of the keyframes
/// ([overlayFadeProperties]) — and the host's stylesheet plays it on the
/// child.
///
/// **Why a keyframes animation, not a transition** — jaspr re-creates the
/// portaled panel's DOM node on every render (the panel is built in the
/// component's subtree but portaled into the root `OverlayHost`, and
/// re-rendered on each open / reposition / close). A CSS `transition`
/// needs the *same* element to persist across the closed→open style
/// change, so it never fires (verified: `ValueKey`, `GlobalKey`, and
/// double-rAF all failed to keep the node identity stable through the
/// portal). A keyframes animation instead plays whenever the element is
/// (re)inserted, so it survives the node re-creation — the same technique
/// Radix / `shadcn_jaspr` use (`animate-in fade-in zoom-in`).
///
/// Applied to the **inner** box, never the positioner-measured outer
/// wrapper: a CSS `transform: scale()` skews `getBoundingClientRect`, so
/// keeping it off the id-carrying outer `<div>` lets the
/// `OverlayPositioner` read the panel's true (unscaled) size.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' show Styles;

/// The attribute that marks the dim a lifted `ContextMenu` source stands over.
/// A forced-colours page replaces a translucent fill with an opaque system
/// colour, which would hide the page the dim only tints, so the host's
/// stylesheet leaves any element carrying it out there.
const String kLiftDimAttribute = 'data-coui-lift-dim';

/// Builds the motion [WebElementChrome] for the inner box of a
/// portal-mounted overlay panel.
///
/// - [closing] — the panel is in its exit window (kept mounted by the
///   consumer's exit timer): play `co-overlay-exit` over [closeDuration],
///   then the consumer unmounts.
/// - else [positioned] — the `OverlayPositioner` has resolved the origin:
///   play `co-overlay-enter` over [openDuration]. The animation plays on
///   the (re)inserted node, so it runs even though the portal re-creates
///   the node when the position commits.
/// - else (open but not yet placed) — hidden (`opacity-0`) with no
///   animation, so the panel never flashes at the unresolved `(0, 0)`
///   origin before placement.
///
/// `both` fill-mode holds the start frame before the animation begins and
/// the end frame after it completes, so there is no pre-roll flash and the
/// panel rests at its final state.
/// Cross-fade travel, as a percentage of the content's own width — one
/// full width, so each half starts / ends completely outside the box.
/// Not a design token: it is the geometric definition of "off to the
/// side", not a tunable distance.
const int _kSwapOffsetPercent = 100;

WebElementChrome resolveOverlayMotion({
  required bool positioned,
  required bool closing,
  required Duration openDuration,
  required Duration closeDuration,
  // Whether a morph is carving this panel, in which case the enter
  // keyframe drops its scale and fades only.
  //
  // Not a style preference: the clip resolves against the untransformed
  // outer box while this scales the content inside it, so the panel body
  // and its silhouette disagree for the whole enter window — and the neck
  // is made of exactly that disagreement. Defaults to false so the six
  // callers that do not morph stay byte-identical.
  bool morphing = false,
}) {
  if (closing) {
    // Leaving the screen — `CoreEasing.exit` (starts at rest,
    // accelerates away), token-routed (`durationMsCss` / `toVarCss` docs)
    // rather than raw `${ms}ms ease-in` literals.
    final duration = durationMsCss(closeDuration.inMilliseconds);
    final easing = CoreEasing.exit.toVarCss();

    return WebElementChrome(
      className: '${WebLayout.pointerEventsNone} $kFadeBoxClass',
      inlineStyles: Styles(
        raw: {
          'animation': 'co-overlay-exit $duration $easing both',
          ...overlayFadeProperties(
            closing: true,
            duration: duration,
            easing: easing,
          ),
        },
      ),
    );
  }
  if (!positioned) {
    return const WebElementChrome(
      className: 'opacity-0 ${WebLayout.pointerEventsNone}',
    );
  }
  // Entering the screen — `CoreEasing.enter` (fast in, settling at
  // rest), token-routed. A morph states no scale: the box has nothing to
  // play, and the panel's fade is all there is.
  final duration = durationMsCss(openDuration.inMilliseconds);
  final easing = CoreEasing.enter.toVarCss();

  return WebElementChrome(
    className: kFadeBoxClass,
    inlineStyles: Styles(
      raw: {
        if (!morphing) 'animation': 'co-overlay-enter $duration $easing both',
        ...overlayFadeProperties(
          closing: false,
          duration: duration,
          easing: easing,
        ),
      },
    ),
  );
}

/// What a fade root states for the panel that plays its fade.
///
/// The length and the easing it plays over, which side of its animation the
/// layers it draws hold on to, and the names of the keyframes (the host's
/// stylesheet reads them: `_kFadeCss` in `overlay_host.dart`). Custom
/// properties are inherited, so a fade root states them once and the panel
/// and the layers in it read them.
///
/// [duration] and [easing] are the CSS values the root's own animation is
/// written with, so the fade is the length and the curve of the motion it
/// belongs to, and `prefers-reduced-motion` (which sets the duration tokens to
/// zero) reaches both.
Map<String, String> overlayFadeProperties({
  required bool closing,
  required String duration,
  required String easing,
}) => {
  kFadeDurationVar: duration,
  kFadeEasingVar: easing,
  // A layer that opens holds its start only until it plays; one that closes
  // holds its end — the panel stays mounted, hidden, until it unmounts.
  kFadeFillVar: closing ? 'forwards' : 'backwards',
  kFadeProgressAnimationVar: closing ? 'co-fade-out' : 'co-fade-in',
  kFadeOpacityNameVar: closing ? 'co-fade-opacity-out' : 'co-fade-opacity-in',
  kFadeGlassPaintNameVar: closing ? 'co-fade-paint-out' : 'co-fade-paint-in',
  kFadeGlassLayerNameVar: closing ? 'co-fade-layer-out' : 'co-fade-layer-in',
};

/// Builds the motion [WebElementChrome] for a panel that stays open while
/// its **anchor moves** — e.g. `NavigationMenu` when the pointer crosses
/// to a sibling trigger.
///
/// This is deliberately not [resolveOverlayMotion]'s enter case. The panel
/// is already on screen, so replaying the enter pop would read as
/// "closed, then reopened somewhere else". Instead the panel travels: the
/// re-created node is already at its new origin, so the keyframe starts it
/// back at the previous one ([fromDx] / [fromDy], the previous origin
/// relative to the new one) and relaxes to zero. No opacity is touched.
///
/// `CoreEasing.move` — the panel moves between two resting places,
/// which is what that alias names.
WebElementChrome resolveOverlaySwitchMotion({
  required double fromDx,
  required double fromDy,
  required Duration duration,
}) {
  return WebElementChrome(
    className: '',
    inlineStyles: Styles(
      raw: {
        '--coui-overlay-switch-x': '${fromDx / kRemDivisor}rem',
        '--coui-overlay-switch-y': '${fromDy / kRemDivisor}rem',
        'animation':
            'co-overlay-switch '
            '${durationMsCss(duration.inMilliseconds)} '
            '${CoreEasing.move.toVarCss()} both',
      },
    ),
  );
}

/// Builds the motion [WebElementChrome] for one half of a panel-content
/// cross-fade: the [incoming] content enters from the side the pointer
/// moved toward, the outgoing half leaves opposite it.
///
/// [direction] is `1` when the menu moved toward a later item and `-1`
/// toward an earlier one. The offset is a percentage of the content's own
/// width, so it needs no measurement — the Flutter twin expresses the
/// same thing as `FractionalTranslation`.
WebElementChrome resolveOverlaySwapMotion({
  required bool incoming,
  required int direction,
  required Duration duration,
}) {
  return WebElementChrome(
    // The outgoing half is lifted out of flow so the incoming half alone
    // sizes the panel — the box takes its new size up front instead of
    // snapping when the fade ends.
    className: incoming ? '' : '${WebLayout.absolute} top-0 left-0',
    inlineStyles: Styles(
      raw: {
        '--coui-overlay-swap-x': '${direction * _kSwapOffsetPercent}%',
        'animation':
            '${incoming ? 'co-overlay-swap-enter' : 'co-overlay-swap-exit'} '
            '${durationMsCss(duration.inMilliseconds)} '
            '${CoreEasing.move.toVarCss()} both',
      },
    ),
  );
}
