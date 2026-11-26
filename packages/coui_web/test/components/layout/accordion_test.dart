import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/layout/accordion/accordion.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

void main() {
  group('Accordion', () {
    testComponents('renders every item title', (tester) async {
      pumpWithTheme(
        tester,
        Accordion(
          items: [
            AccordionItem(
              title: 'First',
              content: Component.text('First body'),
            ),
            AccordionItem(
              title: 'Second',
              content: Component.text('Second body'),
            ),
          ],
        ),
      );

      expect(find.text('First'), findsOneComponent);
      expect(find.text('Second'), findsOneComponent);
    });

    testComponents('renders a custom trigger, bypassing title', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Accordion(
          items: [
            AccordionItem(
              trigger: Component.text('Custom trigger'),
              content: Component.text('Body'),
            ),
          ],
        ),
      );

      expect(find.text('Custom trigger'), findsOneComponent);
    });

    test('accepts custom id', () {
      final accordion = Accordion(
        id: 'accordion-1',
        items: [
          AccordionItem(title: 'A', content: Component.text('body')),
        ],
      );
      expect(accordion.id, equals('accordion-1'));
    });

    test('copyWith preserves properties', () {
      final items = [
        AccordionItem(title: 'A', content: Component.text('body')),
      ];
      final original = Accordion(
        items: items,
        allowMultiple: true,
        id: 'accordion-orig',
      );

      final copy = original.copyWith(id: 'accordion-new');

      expect(copy.id, equals('accordion-new'));
      expect(copy.allowMultiple, isTrue);
      expect(copy.items, equals(items));
    });

    test('implements CoreAccordionContract', () {
      final accordion = Accordion(
        items: [AccordionItem(title: 'A', content: Component.text('body'))],
        allowMultiple: true,
      );

      expect(accordion.allowMultiple, isTrue);
    });
  });

  group('AccordionItem', () {
    test('defaults to collapsed', () {
      final item = AccordionItem(title: 'A', content: Component.text('body'));
      expect(item.expanded, isFalse);
    });

    test('accepts expanded=true', () {
      final item = AccordionItem(
        title: 'A',
        content: Component.text('body'),
        expanded: true,
      );
      expect(item.expanded, isTrue);
    });
  });

  group('the trigger fill', () {
    // `triggerStyle.backgroundColor` fills the trigger row on both
    // platforms (`accordion_trigger_fill_test.dart` is the Flutter half).
    // A token colour used to be dropped here: only the inline half of the
    // emit was kept, and a token has no inline half.
    DomComponent triggerRow() => find
        .tag('div')
        .evaluate()
        .map((element) => element.component as DomComponent)
        .firstWhere(
          (div) => (div.classes ?? '').split(' ').contains('hover:underline'),
        );

    Accordion withFill(CoreColor? fill) => Accordion(
      accordionStyle: fill == null
          ? null
          : CoreAccordionStyle(
              triggerStyle: CoreButtonStyle(backgroundColor: fill),
            ),
      items: [
        AccordionItem(title: 'Shipping', content: Component.text('Two days')),
      ],
    );

    testComponents('a token fill lands as its class', (tester) async {
      pumpWithTheme(
        tester,
        withFill(const CoreColor.token(CoreColors.surfaceContainer)),
      );

      expect(
        (triggerRow().classes ?? '').split(' '),
        contains('bg-surface-container'),
      );
      expect(
        triggerRow().styles?.properties['background-color'],
        isNull,
      );
    });

    testComponents('a raw fill lands inline', (tester) async {
      pumpWithTheme(tester, withFill(const CoreColor(0xFF112233)));

      expect(
        triggerRow().styles?.properties['background-color'],
        isNotNull,
      );
      expect(
        (triggerRow().classes ?? '')
            .split(' ')
            .where((c) => c.startsWith('bg-')),
        isEmpty,
      );
    });

    testComponents('without one the row paints no fill', (tester) async {
      pumpWithTheme(tester, withFill(null));

      expect(
        (triggerRow().classes ?? '')
            .split(' ')
            .where((c) => c.startsWith('bg-')),
        isEmpty,
      );
      expect(
        triggerRow().styles?.properties['background-color'],
        isNull,
      );
    });
  });
}
