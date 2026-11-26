import 'package:coui_web/src/components/control/button/button.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Every attribute on every element in the rendered tree.
Map<String, String> _allAttrs(ComponentTester tester) => {
  for (final e in find.byType(DomComponent).evaluate())
    ...?(e.component as DomComponent).attributes,
};

void main() {
  group('a button with a destination is an anchor', () {
    // What this locks: `Button` used to render `<button>` in every
    // case, and a missing `onPressed` painted it disabled. A marketing
    // CTA then had to leave CoUI — a `<button>` is not crawlable, and
    // middle-click / open-in-new-tab do nothing.
    testComponents('renders <a href> and stays enabled without a callback', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Button(href: '/contact', child: const Component.text('Contact')),
      );

      expect(find.tag('a'), findsOneComponent);
      expect(find.tag('button'), findsNothing);

      final attrs = _allAttrs(tester);
      expect(attrs['href'], '/contact');
      expect(attrs.containsKey('disabled'), isFalse);
      expect(attrs['type'], isNull);
      expect(attrs['aria-disabled'], isNull);
    });

    testComponents('does not invent target/rel for a same-tab link', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Button(href: '/pricing', child: const Component.text('Pricing')),
      );

      final attrs = _allAttrs(tester);
      expect(attrs['target'], isNull);
      expect(attrs['rel'], isNull);
    });

    testComponents('an external link opens safely in a new tab', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Button(
          href: 'https://example.com',
          external: true,
          child: const Component.text('Example'),
        ),
      );

      final attrs = _allAttrs(tester);
      expect(attrs['target'], '_blank');
      expect(attrs['rel'], 'noopener noreferrer');
    });

    testComponents('keeps the anchor when a callback is also set', (
      tester,
    ) async {
      // Analytics must not demote the control back to a `<button>`.
      // A callback that replaces the anchor is the bug this exists to
      // close — crawlers and middle-click would lose the URL again.
      var pressed = false;
      pumpWithTheme(
        tester,
        Button(
          href: '/contact',
          onPressed: () => pressed = true,
          child: const Component.text('Contact'),
        ),
      );

      expect(find.tag('a'), findsOneComponent);
      expect(_allAttrs(tester)['href'], '/contact');

      await tester.click(find.tag('a'));
      expect(pressed, isTrue);
    });

    testComponents('a blank href is not a link', (tester) async {
      pumpWithTheme(
        tester,
        Button(href: '   ', child: const Component.text('Nope')),
      );

      expect(find.tag('button'), findsOneComponent);
      expect(find.tag('a'), findsNothing);
      expect(_allAttrs(tester).containsKey('disabled'), isTrue);
    });
  });

  group('an explicitly disabled link-button stays a button', () {
    // `:disabled` chrome is a button pseudo. An `<a>` cannot carry it,
    // and a disabled CTA must not publish a URL for crawlers.
    testComponents('drops the href and disables the button', (tester) async {
      pumpWithTheme(
        tester,
        Button(
          href: '/contact',
          enabled: false,
          child: const Component.text('Closed'),
        ),
      );

      expect(find.tag('button'), findsOneComponent);
      expect(find.tag('a'), findsNothing);

      final attrs = _allAttrs(tester);
      expect(attrs['href'], isNull);
      expect(attrs.containsKey('disabled'), isTrue);
      expect(attrs['aria-disabled'], 'true');
      expect(attrs['type'], 'button');
    });
  });

  group('a plain action button is unchanged', () {
    testComponents('still renders a button when only onPressed is set', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Button(onPressed: () {}, child: const Component.text('Save')),
      );

      expect(find.tag('button'), findsOneComponent);
      expect(find.tag('a'), findsNothing);
      expect(_allAttrs(tester)['href'], isNull);
      expect(_allAttrs(tester)['type'], 'button');
    });
  });
}
