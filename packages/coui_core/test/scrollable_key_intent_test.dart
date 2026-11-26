import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

// The key map is the one part of the keyboard story that can drift
// without anything rendering differently: two switch statements agreeing
// today diverge the first time one of them gains a key. It lives in Core
// so both platforms read it, and it is pinned here so a change to it is
// a decision rather than an accident.

const _kViewportHeight = 400.0;

CoreScrollableKeyIntent _intent(
  String key, {
  double height = _kViewportHeight,
}) => resolveScrollableKeyIntent(key, viewportHeight: height);

void main() {
  group('scroll key map', () {
    test('arrows move one line along their own axis', () {
      const line = CoreScrollableClientContract.keyboardLineStep;

      const move = CoreScrollableKeyAction.moveBy;

      expect(_intent('ArrowDown'), (action: move, dx: 0.0, dy: line));
      expect(_intent('ArrowUp'), (action: move, dx: 0.0, dy: -line));
      expect(_intent('ArrowRight'), (action: move, dx: line, dy: 0.0));
      expect(_intent('ArrowLeft'), (action: move, dx: -line, dy: 0.0));
    });

    test('a horizontal arrow never asks for vertical movement', () {
      // The reason this widget routes keys itself: Flutter's own
      // `ScrollAction` resolves the nearest `Scrollable` — always the
      // inner horizontal one here — and returns zero for the other axis.
      // Each arrow has to name exactly one axis for that to be fixable.
      expect(_intent('ArrowRight').dy, 0);
      expect(_intent('ArrowLeft').dy, 0);
      expect(_intent('ArrowDown').dx, 0);
      expect(_intent('ArrowUp').dx, 0);
    });

    test('page keys move a fraction of the viewport, not all of it', () {
      const fraction = CoreScrollableClientContract.keyboardPageStepFraction;
      final expected = _kViewportHeight * fraction;

      expect(_intent('PageDown').dy, expected);
      expect(_intent('PageUp').dy, -expected);
      // Overlap is the point — a full-viewport jump leaves a reader with
      // no line in common between the two screens.
      expect(expected, lessThan(_kViewportHeight));
    });

    test('an unmeasured viewport makes a page key a no-op, not a jump to '
        'nowhere', () {
      // Before the first layout the viewport reports zero. A zero-height
      // page step would resolve to "move by 0" and still be consumed,
      // swallowing the key from whatever else could have handled it.
      expect(
        _intent('PageDown', height: 0).action,
        CoreScrollableKeyAction.none,
      );
      expect(_intent('PageUp', height: 0).action, CoreScrollableKeyAction.none);
    });

    test('home and end ask for the extents, carrying no delta', () {
      expect(_intent('Home').action, CoreScrollableKeyAction.jumpToStart);
      expect(_intent('End').action, CoreScrollableKeyAction.jumpToEnd);
      expect(_intent('Home').dy, 0);
      expect(_intent('End').dy, 0);
    });

    test('the step sizes are the documented numbers, not just whatever the '
        'constants say', () {
      // Every other assertion compares against the same constants the
      // implementation reads, which pins wiring but not values — the
      // contract could be retuned to 5px and the suite would stay green.
      // These two literals are the contract: 50px is the line increment
      // Flutter's own `ScrollAction` uses, and 0.8 is its page fraction,
      // so a `ScrollableClient` moves like every other scroll view.
      expect(CoreScrollableClientContract.keyboardLineStep, 50.0);
      expect(CoreScrollableClientContract.keyboardPageStepFraction, 0.8);
    });

    test('a key outside the map is left alone', () {
      // Not "handled as nothing" — untouched, so it reaches whatever else
      // was listening. A scroll region that eats Tab or Enter is worse
      // than one that scrolls nowhere.
      for (final key in ['Tab', 'Enter', ' ', 'a', 'Escape', 'F5']) {
        expect(
          _intent(key).action,
          CoreScrollableKeyAction.none,
          reason: '"$key" must not be claimed by the scroll map',
        );
      }
    });
  });
}
