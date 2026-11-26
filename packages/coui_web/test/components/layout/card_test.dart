import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/layout/card/card.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

void main() {
  group('Card', () {
    testComponents('renders a <div> root', (tester) async {
      pumpWithTheme(tester, Card(body: const Component.text('Body')));

      expect(find.tag('div'), findsComponents);
      expect(find.text('Body'), findsOneComponent);
    });

    testComponents('renders outlined variant', (tester) async {
      pumpWithTheme(
        tester,
        Card(variant: .outlined, body: const Component.text('Outlined')),
      );

      expect(find.text('Outlined'), findsOneComponent);
    });

    testComponents('renders filled variant (default)', (tester) async {
      pumpWithTheme(tester, Card(body: const Component.text('Filled')));

      expect(find.text('Filled'), findsOneComponent);
    });

    testComponents('renders header, body, and footer slots', (tester) async {
      pumpWithTheme(
        tester,
        Card(
          header: const Component.text('Header'),
          body: const Component.text('Body'),
          footer: const Component.text('Footer'),
        ),
      );

      expect(find.text('Header'), findsOneComponent);
      expect(find.text('Body'), findsOneComponent);
      expect(find.text('Footer'), findsOneComponent);
    });

    testComponents('renders media and overlay slots', (tester) async {
      pumpWithTheme(
        tester,
        Card(
          media: const Component.text('Media'),
          overlay: const Component.text('Overlay'),
        ),
      );

      expect(find.text('Media'), findsOneComponent);
      expect(find.text('Overlay'), findsOneComponent);
    });

    testComponents('renders a custom child, bypassing named slots', (
      tester,
    ) async {
      pumpWithTheme(tester, Card(child: const Component.text('Custom child')));

      expect(find.text('Custom child'), findsOneComponent);
    });

    testComponents('renders custom children, bypassing named slots', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Card(
          children: const [Component.text('First'), Component.text('Second')],
        ),
      );

      expect(find.text('First'), findsOneComponent);
      expect(find.text('Second'), findsOneComponent);
    });

    test('accepts custom id', () {
      final card = Card(id: 'card-1');
      expect(card.id, equals('card-1'));
    });

    test('copyWith preserves properties', () {
      final original = Card(
        variant: .outlined,
        body: const Component.text('Original'),
        id: 'card-orig',
      );

      final copy = original.copyWith(id: 'card-new');

      expect(copy.id, equals('card-new'));
      expect(copy.variant, equals(CoreCardVariant.outlined));
    });

    test('implements CoreCardContract', () {
      final card = Card(variant: .outlined, body: const Component.text('Body'));

      expect(card.variant, equals(CoreCardVariant.outlined));
    });

    test('the default variant is filled', () {
      final card = Card(body: const Component.text('Body'));

      expect(card.variant, equals(CoreCardVariant.filled));
    });
  });

  group('Card edge', () {
    DomComponent rootOf(String text) => find
        .ancestor(of: find.text(text), matching: find.tag('div'))
        .evaluate()
        .map((e) => e.component as DomComponent)
        .firstWhere((d) => (d.classes ?? '').contains('max-w-full'));

    List<String> classesOf(DomComponent d) =>
        (d.classes ?? '').split(' ').where((c) => c.isNotEmpty).toList();

    testComponents('a default Card is the flat fill with no edge', (
      tester,
    ) async {
      pumpWithTheme(tester, Card(body: const Component.text('Body')));

      final root = rootOf('Body');
      final classes = classesOf(root);
      expect(classes, contains('bg-surface-container'));
      expect(classes, isNot(contains('border')));
      expect(classes.where((c) => c.startsWith('border-')), isEmpty);
      expect(root.styles!.properties.containsKey('border-width'), isFalse);
    });

    testComponents('an outlined Card draws the outlineVariant hairline', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Card(variant: .outlined, body: const Component.text('Body')),
      );

      final classes = classesOf(rootOf('Body'));
      expect(classes, contains('bg-surface'));
      expect(classes, contains('border'));
      expect(classes, contains('border-outline-variant'));
    });

    testComponents('a width and a colour on the default Card draw an edge', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Card(
          body: const Component.text('Body'),
          cardStyle: const CoreCardStyle(
            borderWidth: CoreStrokeWidth.stroke2,
            borderColor: CoreColor.token(CoreColors.tertiary),
          ),
        ),
      );

      final root = rootOf('Body');
      final classes = classesOf(root);
      expect(classes, contains('border'));
      expect(classes, contains('border-tertiary'));
      expect(
        root.styles!.properties['border-width'],
        'var(--coui-stroke-width-2)',
      );
    });

    testComponents('a width alone leaves the default Card borderless', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Card(
          body: const Component.text('Body'),
          cardStyle: const CoreCardStyle(borderWidth: CoreStrokeWidth.stroke2),
        ),
      );

      // The variant's edge colour is clear, so the width folds to nothing —
      // the way Flutter's `OutlinedContainer` reads it.
      final root = rootOf('Body');
      expect(classesOf(root), isNot(contains('border')));
      expect(root.styles!.properties.containsKey('border-width'), isFalse);
    });

    testComponents('a colour alone leaves the default Card borderless', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Card(
          body: const Component.text('Body'),
          cardStyle: const CoreCardStyle(
            borderColor: CoreColor.token(CoreColors.tertiary),
          ),
        ),
      );

      final classes = classesOf(rootOf('Body'));
      expect(classes, isNot(contains('border')));
      expect(classes, isNot(contains('border-tertiary')));
    });
  });
}
