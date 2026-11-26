import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

const _kTestPadding = 8.0;
const _kTestIconGap = 10.0;
const _kTestDividerHeight = 2.0;
const _kTestDuration = Duration(milliseconds: 300);

void main() {
  group('Accordion', () {
    testWidgets('renders with items list', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          Accordion(
            items: [
              AccordionItem(
                content: const material.Text('Content 1'),
                trigger: const AccordionTrigger(
                  child: material.Text('Trigger 1'),
                ),
              ),
              AccordionItem(
                content: const material.Text('Content 2'),
                trigger: const AccordionTrigger(
                  child: material.Text('Trigger 2'),
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.byType(Accordion), findsOneWidget);
      expect(find.text('Trigger 1'), findsOneWidget);
      expect(find.text('Trigger 2'), findsOneWidget);
    });

    testWidgets('renders with single item', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          Accordion(
            items: [
              AccordionItem(
                content: const material.Text('Single Content'),
                trigger: const AccordionTrigger(
                  child: material.Text('Single Trigger'),
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.byType(Accordion), findsOneWidget);
      expect(find.text('Single Trigger'), findsOneWidget);
    });
  });

  group('AccordionItem', () {
    test('constructor with trigger/content/expanded params', () {
      const trigger = AccordionTrigger(child: material.Text('Title'));
      const content = material.Text('Body');
      const item = AccordionItem(
        content: content,
        trigger: trigger,
      );

      expect(item.trigger, equals(trigger));
      expect(item.content, equals(content));
      expect(item.expanded, isFalse);
    });

    test('expanded defaults to false', () {
      const item = AccordionItem(
        content: material.Text('Content'),
        trigger: AccordionTrigger(child: material.Text('Trigger')),
      );

      expect(item.expanded, isFalse);
    });

    test('expanded can be set to true', () {
      const item = AccordionItem(
        content: material.Text('Content'),
        expanded: true,
        trigger: AccordionTrigger(child: material.Text('Trigger')),
      );

      expect(item.expanded, isTrue);
    });
  });

  group('AccordionTrigger', () {
    test('constructor with child param', () {
      const childWidget = material.Text('Trigger Label');
      const trigger = AccordionTrigger(child: childWidget);

      expect(trigger.child, equals(childWidget));
    });

    testWidgets('renders child inside accordion context', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          Accordion(
            items: [
              AccordionItem(
                content: const material.Text('Content'),
                trigger: const AccordionTrigger(
                  child: material.Text('My Trigger'),
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.text('My Trigger'), findsOneWidget);
    });
  });
}
