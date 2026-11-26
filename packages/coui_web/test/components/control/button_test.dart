import 'package:coui_web/src/components/control/button/button.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

void main() {
  group('Button', () {
    testComponents('renders with default tag', (tester) async {
      pumpWithTheme(
        tester,
        Button(variant: .primary, child: Component.text('Click me')),
      );

      expect(find.tag('button'), findsOneComponent);
      expect(find.text('Click me'), findsOneComponent);
    });

    testComponents('renders primary variant', (tester) async {
      pumpWithTheme(
        tester,
        Button(variant: .primary, child: Component.text('Primary')),
      );

      expect(find.tag('button'), findsOneComponent);
      expect(find.text('Primary'), findsOneComponent);
    });

    testComponents('renders secondary variant', (tester) async {
      pumpWithTheme(
        tester,
        Button(variant: .secondary, child: Component.text('Secondary')),
      );

      expect(find.tag('button'), findsOneComponent);
      expect(find.text('Secondary'), findsOneComponent);
    });

    testComponents('renders outline variant', (tester) async {
      pumpWithTheme(
        tester,
        Button(variant: .outline, child: Component.text('Outline')),
      );

      expect(find.tag('button'), findsOneComponent);
      expect(find.text('Outline'), findsOneComponent);
    });

    testComponents('renders ghost variant', (tester) async {
      pumpWithTheme(
        tester,
        Button(variant: .ghost, child: Component.text('Ghost')),
      );

      expect(find.tag('button'), findsOneComponent);
      expect(find.text('Ghost'), findsOneComponent);
    });

    testComponents('renders destructive variant', (tester) async {
      pumpWithTheme(
        tester,
        Button(variant: .destructive, child: Component.text('Delete')),
      );

      expect(find.tag('button'), findsOneComponent);
      expect(find.text('Delete'), findsOneComponent);
    });

    test('accepts custom id', () {
      final button = Button(
        variant: .primary,
        id: 'my-btn',
        child: Component.text('Test'),
      );
      expect(button.id, equals('my-btn'));
    });

    test('sets type=button attribute by default', () {
      final button = Button(variant: .primary, child: Component.text('Test'));
      final attrs = button.componentAttributes;

      expect(attrs['type'], equals('button'));
    });

    test('sets disabled attributes when not enabled', () {
      final button = Button(
        variant: .primary,
        enabled: false,
        child: Component.text('Disabled'),
      );
      final attrs = button.componentAttributes;

      expect(attrs.containsKey('disabled'), isTrue);
      expect(attrs['aria-disabled'], equals('true'));
      expect(attrs['tabindex'], equals('-1'));
    });

    testComponents('renders with leading and trailing', (tester) async {
      pumpWithTheme(
        tester,
        Button(
          variant: .primary,
          leading: Component.text('>>'),
          trailing: Component.text('<<'),
          child: Component.text('Content'),
        ),
      );

      expect(find.text('>>'), findsOneComponent);
      expect(find.text('Content'), findsOneComponent);
      expect(find.text('<<'), findsOneComponent);
    });

    test('copyWith preserves properties', () {
      final original = Button(
        variant: .primary,
        id: 'original-id',
        child: Component.text('Original'),
      );

      final copy = original.copyWith(id: 'new-id');

      expect(copy.id, equals('new-id'));
    });

    // `disableTransition` reached the widget's field, its `copyWith` and the
    // contract, and stopped there — nothing in `coui_web` read it. A
    // resolver-level test cannot see that: it passes the flag in itself.
    // These render the real button and read what the element carries.
    testComponents('publishes a chrome transition clock', (tester) async {
      pumpWithTheme(tester, Button(child: Component.text('x')));

      expect(
        _rootStyles(tester)['--coui-control-chrome-duration'],
        startsWith('var(--coui-duration-'),
      );
    });

    testComponents('disableTransition reaches the rendered element', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Button(disableTransition: true, child: Component.text('x')),
      );

      expect(_rootStyles(tester)['--coui-control-chrome-duration'], '0s');
    });
  });
}

/// The inline styles the rendered `<button>` actually carries.
Map<String, String> _rootStyles(ComponentTester tester) {
  final root = find.tag('button').evaluate().single.component;
  return (root as DomComponent).styles?.properties ?? const {};
}
