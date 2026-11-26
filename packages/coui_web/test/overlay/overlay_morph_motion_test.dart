// What the Web half contributes to a morph, in the parts a VM can see.
//
// The clip itself needs a browser: the gate reads a live document
// attribute and the bodies come from measured rectangles, neither of which
// exists here. What does exist is the decision that keeps the two from
// fighting — whether the enter keyframe still scales — and the engine
// callback the panel's own box arrives through.
import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/overlay/overlay_motion.dart';
import 'package:coui_web/src/overlay/positioning/overlay_positioner.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:test/test.dart';

const _kOpen = Duration(milliseconds: CoreDuration.normal);
const _kClose = Duration(milliseconds: CoreDuration.fast);

String _animationOf(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties['animation'] ?? '';

void main() {
  group('a morphing panel does not also scale itself in', () {
    test('the box states no keyframe, and the panel still fades in', () {
      // Not a style preference. The clip resolves against the untransformed
      // outer box while this scales the content inside it, so the panel
      // body and its silhouette disagree for the whole enter window — and
      // the neck is made of exactly that disagreement.
      //
      // The box has no keyframe of its own to take the scale from, so it is
      // not given one. What fades is what is inside it: the box only names
      // the fade its child plays.
      final morphing = resolveOverlayMotion(
        positioned: true,
        closing: false,
        openDuration: _kOpen,
        closeDuration: _kClose,
        morphing: true,
      );

      expect(
        _animationOf(morphing),
        isEmpty,
        reason: 'the box is given a keyframe, scaling or not',
      );
      expect(morphing.className, contains(kFadeBoxClass));
      expect(
        morphing.inlineStyles?.properties[kFadeProgressAnimationVar],
        'co-fade-in',
        reason: 'what is inside it does not fade',
      );
    });

    test('and everything else keeps the scale it always had', () {
      // The default is what six current callers get, and they were not
      // asked. A version of this change that flipped the default would
      // silently take the scale-in off DropdownMenu, ContextMenu, Menubar,
      // NavigationMenu and HoverCard.
      final plain = resolveOverlayMotion(
        positioned: true,
        closing: false,
        openDuration: _kOpen,
        closeDuration: _kClose,
      );

      expect(_animationOf(plain), contains('co-overlay-enter'));
      expect(_animationOf(plain), isNot(contains('fade-enter')));
    });

    test('and closing is unaffected either way', () {
      // Only the open is morphed in this cut, so the exit must be the same
      // declaration whichever branch asked for it.
      for (final morphing in [true, false]) {
        expect(
          _animationOf(
            resolveOverlayMotion(
              positioned: true,
              closing: true,
              openDuration: _kOpen,
              closeDuration: _kClose,
              morphing: morphing,
            ),
          ),
          contains('co-overlay-exit'),
        );
      }
    });
  });

  group('the engine reports the panel it already measured', () {
    test('the callback exists on both sides of the conditional import', () {
      // A compile-time claim, and a real one: adding a field to the web
      // implementation alone breaks the server build, and it is the first
      // thing that would break.
      var reported = 0;
      final positioner = OverlayPositioner(
        triggerId: 'trigger',
        popoverId: 'panel',
        placement: CorePopoverPlacement.bottom,
        onPanelMeasured: (_) => reported++,
      );

      // No DOM here, so nothing is measured — the assertion is that this
      // constructs and disposes at all, which is what the SSR path does.
      expect(reported, 0);
      positioner.dispose();
    });
  });
}
