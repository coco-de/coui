// A hover-opened menubar must not make the page inert.
//
// `OverlayController.mount(modal: true)` has exactly one effect: `OverlayHost`
// stamps `inert` on the wrapper around the app. For `NavigationMenu` that
// wrapper contains the menu's own trigger bar, and an inert trigger cannot be
// hovered — so the browser fires `mouseleave` on a pointer that never moved,
// the pointer-intent close arms, the panel unmounts, `inert` drops, the
// motionless pointer re-enters, and the menu oscillates several times a second.
// It also never reaches the trigger-to-trigger travel, because by the time the
// second trigger is entered the panel has already gone.
//
// This is a behavioural contract, not a styling detail, so it is asserted on
// the rendered attribute rather than on the controller flag.
library;

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/overlay/overlay_host.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, Text;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:jaspr_test/jaspr_test.dart';

Finder _backdrop({bool inert = false}) => find.byComponentPredicate(
  (c) =>
      c is div &&
      (c.attributes?.containsKey('data-coui-backdrop') ?? false) &&
      (!inert || (c.attributes?.containsKey('inert') ?? false)),
);

Component _menu({int? activeIndex}) => NavigationMenu(
  activeIndex: activeIndex,
  items: const [
    CoreNavigationMenuItem(
      label: 'Products',
      content: Text('Products content'),
    ),
    CoreNavigationMenuItem(
      label: 'Solutions',
      content: Text('Solutions content'),
    ),
  ],
);

void main() {
  group('NavigationMenu modal containment', () {
    testComponents('an open panel does not mark the page inert', (
      tester,
    ) async {
      tester.pumpComponent(
        OverlayHost(child: Theme.defaults(child: _menu(activeIndex: 0))),
      );
      await tester.pump();
      await tester.pump();

      // Sanity: the host rendered its backdrop wrapper at all, so a
      // `findsNothing` below means "not inert", not "not found".
      expect(_backdrop(), findsOneComponent);
      // The contract. If this ever flips back to inert, the trigger bar
      // stops being hoverable and the menu strobes.
      expect(_backdrop(inert: true), findsNothing);
    });

    testComponents('a closed menu leaves the page alone too', (tester) async {
      tester.pumpComponent(
        OverlayHost(child: Theme.defaults(child: _menu())),
      );
      await tester.pump();
      await tester.pump();

      expect(_backdrop(inert: true), findsNothing);
    });
  });
}
