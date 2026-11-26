// A navigation bar is a single row. Both kinds of trigger in it — the
// link (`href`) and the content trigger (`content`, a `Button`) — have
// to refuse to wrap, or the bar breaks unevenly: one label stays on its
// line while the one beside it splits mid-word.
//
// They did not agree. The link path composes its class list through
// `buildTriggerClassName()`, which includes `whitespace-nowrap`; the
// content path renders a `Button`, which does not. So a bar narrow
// enough to squeeze split **only the button labels**, character by
// character, while the links beside them stayed intact — a shape that
// reads as a rendering bug rather than as a tight fit.
//
// The fix is one class on the `Button`. This file exists because one
// class is exactly the kind of thing a later edit drops without
// noticing, and because the asymmetry is invisible until a bar is
// actually narrow.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

void main() {
  group('NavigationMenu triggers', () {
    testComponents('both kinds refuse to wrap', (tester) async {
      pumpWithTheme(
        tester,
        NavigationMenu(
          items: [
            const CoreNavigationMenuItem(
              label: 'Link item',
              href: '/somewhere',
            ),
            CoreNavigationMenuItem(
              label: 'Content item',
              content: const Text('panel'),
            ),
          ],
        ),
      );
      await tester.pump();

      // Read what reached the DOM, not what the resolver returned — a
      // class can be resolved and still never be emitted.
      //
      // The link path renders an `<a>` and the content path a `<button>`,
      // and the point of this test is that those two agree. Triggers are
      // the bar's own links and buttons (the panel is not open here).
      final triggers = [
        for (final tag in const ['a', 'button'])
          for (final element in find.tag(tag).evaluate())
            if (element.component case final DomComponent dom) (tag, dom),
      ];

      expect(
        triggers.map((t) => t.$1).toSet(),
        {'a', 'button'},
        reason: 'the fixture must exercise both trigger kinds',
      );

      for (final (tag, dom) in triggers) {
        expect(
          // `classes` is its own field on `DomComponent`, not an entry
          // in `attributes` — reading the latter finds nothing and the
          // assertion fails for the wrong reason.
          (dom.classes ?? '').split(RegExp(r'\s+')),
          contains('whitespace-nowrap'),
          reason:
              'the <$tag> trigger may wrap — a bar with both kinds then '
              'splits only one of them',
        );
      }
    });
  });
}
