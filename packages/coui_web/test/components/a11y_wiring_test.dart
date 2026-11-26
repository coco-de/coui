import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

Iterable<DomComponent> _elements(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent);

Iterable<Map<String, String>> _attributes(ComponentTester tester) =>
    _elements(tester).map((c) => c.attributes ?? const {});

void main() {
  group('a landmark says which landmark it is', () {
    // A page can carry several. Unnamed, a screen reader's landmark list
    // reads "navigation, navigation, contentinfo" and tells the user
    // nothing about which is which. The Flutter twins have fallen back to
    // the locale all along; this side required the caller to pass a label
    // and stayed unnamed when they did not.
    testComponents('a footer names itself without being told to', (
      tester,
    ) async {
      pumpWithTheme(tester, Footer(sections: []));

      final contentInfo = _attributes(
        tester,
      ).where((a) => a['role'] == CoreSemanticRole.contentInfo.ariaRole);

      expect(contentInfo, isNotEmpty);
      expect(contentInfo.first['aria-label'], isNotEmpty);
    });

    testComponents('and a dock does too', (tester) async {
      pumpWithTheme(
        tester,
        Dock(
          items: [
            CoreDockItemData<Component>(
              label: 'Home',
              icon: Icon(LucideIcons.house),
            ),
          ],
        ),
      );

      final nav = _attributes(
        tester,
      ).where((a) => a['role'] == CoreSemanticRole.navigation.ariaRole);

      expect(nav, isNotEmpty);
      expect(nav.first['aria-label'], isNotEmpty);
    });

    testComponents('an explicit label still wins', (tester) async {
      // The fallback is a floor, not an override — a caller who names the
      // landmark keeps their name.
      pumpWithTheme(
        tester,
        Footer(semanticLabel: 'Site information', sections: []),
      );

      final contentInfo = _attributes(
        tester,
      ).where((a) => a['role'] == CoreSemanticRole.contentInfo.ariaRole);

      expect(contentInfo.first['aria-label'], 'Site information');
    });
  });

  group('a pressable card is operable by keyboard', () {
    testComponents('it takes a role and a tab stop', (tester) async {
      // The Flutter twin composes `Button`, so it announces as one and
      // takes Enter and Space. This side had a click handler and nothing
      // else — no role, no tab stop, no keys — so the component was
      // mouse-only on one platform and not the other.
      pumpWithTheme(
        tester,
        CardImage(
          onPressed: () {},
          image: Text('img'),
          title: Text('Cover'),
        ),
      );

      final buttons = _attributes(tester).where((a) => a['role'] == 'button');

      expect(buttons, isNotEmpty);
      expect(buttons.first['tabindex'], '0');
    });

    testComponents('a decorative one takes neither', (tester) async {
      // The half a blanket role would fail: a card with no handler is not
      // a control, and announcing it as one describes an affordance that
      // is not there.
      pumpWithTheme(tester, CardImage(image: Text('img'), title: Text('C')));

      expect(_attributes(tester).any((a) => a['role'] == 'button'), isFalse);
    });
  });

  group('a range date can be reached without a pointer', () {
    testComponents('in-range cells are operable', (tester) async {
      // Every other date in the grid is a `Button`; the in-range and
      // endpoint cells are hand-drawn so the band can run behind the
      // pill, and they were left as bare divs with a click handler — so a
      // keyboard user could pick a range start and had no way to reach
      // its end. The selection could be begun and not finished.
      pumpWithTheme(
        tester,
        Calendar(
          selectionMode: CoreCalendarSelectionMode.range,
          value: CoreCalendarValue.range(
            DateTime(2026, 3, 10),
            DateTime(2026, 3, 20),
          ),
          onChanged: (_) {},
        ),
      );

      final operable = _attributes(
        tester,
      ).where((a) => a['role'] == 'button' && a['tabindex'] == '0');

      expect(operable, isNotEmpty);
    });

    testComponents('a disabled range date says so instead of vanishing', (
      tester,
    ) async {
      // Dropping the role would make an unavailable date
      // indistinguishable from the empty padding cells around the month.
      // "Unavailable" and "not a date at all" are different answers to
      // the same question, and only one of them is true.
      pumpWithTheme(
        tester,
        Calendar(
          selectionMode: CoreCalendarSelectionMode.range,
          // Inside the selected range, so some in-range cells are
          // disabled while still being drawn as range cells.
          minDate: DateTime(2026, 3, 18),
          value: CoreCalendarValue.range(
            DateTime(2026, 3, 16),
            DateTime(2026, 3, 20),
          ),
          onChanged: (_) {},
        ),
      );

      final cells = _attributes(tester).where((a) => a['role'] == 'button');

      expect(cells.any((a) => a['aria-disabled'] == 'true'), isTrue);
    });
  });
}
