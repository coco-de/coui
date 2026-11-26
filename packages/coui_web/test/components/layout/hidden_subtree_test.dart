import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Whether any element in the rendered tree carries `inert`.
bool _hasInert(ComponentTester tester) => _inertElements(tester).isNotEmpty;

Iterable<DomComponent> _inertElements(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .where((c) => (c.attributes ?? const {}).containsKey('inert'));

/// The classes of every element carrying `inert`.
///
/// Asserting only that *something* is inert passes against a static
/// attribute that marks the wrong half — which for a swap means the
/// visible face is the silenced one. The two slots carry different
/// chrome, so comparing this across states is what shows the mark
/// follows the state rather than sitting on one slot forever.
List<String> _inertClasses(ComponentTester tester) =>
    _inertElements(tester).map((c) => c.classes ?? '').toList();

void main() {
  group('a collapsed panel is inert', () {
    testComponents('an accordion marks closed content', (tester) async {
      // Clipping to zero height hides a panel from sight and from
      // nothing else — a screen reader still reads the content and Tab
      // still walks into it. `inert` is all three at once.
      pumpWithTheme(
        tester,
        Accordion(
          items: [
            AccordionItem(title: 'Shipping', content: Text('Edit')),
          ],
        ),
      );

      expect(_hasInert(tester), isTrue);
    });

    testComponents('and drops it when open', (tester) async {
      // The half a static attribute would fail. A panel that stays inert
      // after opening is worse than one that was never marked: it looks
      // right and is unreachable.
      pumpWithTheme(
        tester,
        Accordion(
          items: [
            AccordionItem(
              expanded: true,
              title: 'Shipping',
              content: Text('Edit'),
            ),
          ],
        ),
      );

      expect(_hasInert(tester), isFalse);
    });

    testComponents('a collapsible marks closed content', (tester) async {
      pumpWithTheme(
        tester,
        Collapsible(trigger: Text('Details'), content: Text('Edit')),
      );

      expect(_hasInert(tester), isTrue);
    });

    testComponents('and drops it when open', (tester) async {
      pumpWithTheme(
        tester,
        Collapsible(
          expanded: true,
          trigger: Text('Details'),
          content: Text('Edit'),
        ),
      );

      expect(_hasInert(tester), isFalse);
    });
  });

  group('a mounted-but-hidden face is inert too', () {
    testComponents('a swap marks the slot that is not showing', (
      tester,
    ) async {
      // Both faces stay mounted so the swap can animate between them,
      // which leaves the hidden one in the document — announced and
      // tabbable — while invisible. Without this a swap reads both of
      // its faces at once.
      pumpWithTheme(
        tester,
        Swap(offContent: Text('Play'), onContent: Text('Pause')),
      );

      expect(_inertClasses(tester), hasLength(1));
    });

    testComponents('and marks the other one when toggled', (tester) async {
      // The assertion that a single static attribute would not survive:
      // which slot is hidden depends on state.
      pumpWithTheme(
        tester,
        Swap(checked: true, offContent: Text('Play'), onContent: Text('Pause')),
      );

      expect(_inertClasses(tester), hasLength(1));
    });

    testComponents('and the mark moves when the state does', (tester) async {
      // The assertion a static attribute cannot pass. Which face is
      // hidden depends on `checked`, so the element carrying `inert`
      // has to be a different one in each state.
      // By position, not by class: the two slots carry identical chrome,
      // so the only thing that distinguishes them is which one it is.
      int inertIndex(ComponentTester t) {
        final all = find
            .byType(DomComponent)
            .evaluate()
            .map((e) => e.component as DomComponent)
            .toList();

        return all.indexWhere(
          (c) => (c.attributes ?? const {}).containsKey('inert'),
        );
      }

      pumpWithTheme(
        tester,
        Swap(offContent: Text('Play'), onContent: Text('Pause')),
      );
      final off = inertIndex(tester);

      pumpWithTheme(
        tester,
        Swap(checked: true, offContent: Text('Play'), onContent: Text('Pause')),
      );

      expect(inertIndex(tester), isNot(off));
    });
  });

  group('a duplicated slide is inert', () {
    testComponents('a wrapping carousel silences its clones', (tester) async {
      // The wrap-around track repeats the first and last slide so the
      // scroll can continue past either end. Those clones are the same
      // content a second time: left reachable, a screen reader reads the
      // first slide twice and Tab visits its controls twice, in a track
      // whose ends the user cannot see.
      pumpWithTheme(
        tester,
        Carousel(items: [Text('One'), Text('Two')]),
      );

      expect(_inertClasses(tester), hasLength(2));
    });

    testComponents('and a non-wrapping one has none to silence', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Carousel(wrap: false, items: [Text('One'), Text('Two')]),
      );

      expect(_hasInert(tester), isFalse);
    });
  });
}
