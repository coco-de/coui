import 'package:coui_web/src/base/ui_events.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:universal_web/web.dart' as web;

// `EventHandlers.chain` exists because the obvious spelling of "listen for
// keydown" silently deletes the caller's `onKeyDown`: the base already put a
// handler under that key, and a map literal naming it again replaces rather
// than adds. Nothing about the rendered component looks different when that
// happens, so it is pinned here instead.

void main() {
  group('event chaining', () {
    test('both the caller and the component see the event', () {
      final seen = <String>[];
      final chained = EventHandlers.chain(
        (_) => seen.add('caller'),
        (_) => seen.add('own'),
      );

      chained(web.Event('keydown'));

      expect(seen, ['caller', 'own']);
    });

    test('the caller runs first, so it can claim the event', () {
      // Ordering is the whole contract: the component checks
      // `defaultPrevented` to decide whether to act, which only works if
      // the caller has already had its turn.
      final order = <String>[];
      final chained = EventHandlers.chain(
        (_) => order.add('caller'),
        (_) => order.add('own'),
      );

      chained(web.Event('keydown'));

      expect(order.first, 'caller');
    });

    test('with no caller handler the component handler is used unchanged', () {
      var calls = 0;
      void own(web.Event _) => calls++;
      final chained = EventHandlers.chain(null, own);

      expect(identical(chained, own), isTrue);
      chained(web.Event('keydown'));
      expect(calls, 1);
    });
  });
}
