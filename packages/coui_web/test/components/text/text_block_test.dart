import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Every attribute on every element in the rendered tree.
Map<String, String> _allAttrs(ComponentTester tester) => {
  for (final e in find.byType(DomComponent).evaluate())
    ...?(e.component as DomComponent).attributes,
};

/// The inline-CSS properties rendered on the element with [tag].
Map<String, String> _styleOf(ComponentTester tester, String tag) {
  final element = find.tag(tag).evaluate().first.component as DomComponent;
  return element.styles?.properties ?? const {};
}

/// The class names rendered on the element with [tag].
Set<String> _classesOf(ComponentTester tester, String tag) {
  final element = find.tag(tag).evaluate().first.component as DomComponent;
  return (element.classes ?? '').split(' ').where((c) => c.isNotEmpty).toSet();
}

void main() {
  group('a heading is stated by the element, not by an attribute', () {
    testComponents('h2 renders as <h2>', (tester) async {
      pumpWithTheme(
        tester,
        const TextBlock(text: 'T', element: CoreTextBlockElement.h2),
      );

      expect(find.tag('h2'), findsOneComponent);
    });

    testComponents('and adds no aria-level or role beside it', (tester) async {
      // The instinct this blocks: Flutter states the heading through
      // `Semantics.headingLevel`, so a reader reaching for parity would
      // add `aria-level` here to match. The browser already puts an
      // `<h2>` in the document outline — the attribute would be a second
      // statement of the same thing, and a wrong one the moment the two
      // disagree.
      //
      // Written as a test rather than a comment because a comment is
      // what the parity guard used to have, and it still reported this
      // component as Web-missing until the guard learned that a native
      // element is an accessibility mechanism.
      pumpWithTheme(
        tester,
        const TextBlock(text: 'T', element: CoreTextBlockElement.h2),
      );
      final attrs = _allAttrs(tester);

      expect(attrs.containsKey('aria-level'), isFalse);
      expect(attrs['role'], isNot('heading'));
    });

    testComponents('a paragraph renders as <p>', (tester) async {
      pumpWithTheme(
        tester,
        const TextBlock(text: 'T'),
      );

      expect(find.tag('p'), findsOneComponent);
    });
  });

  group('the two element roles that carry a box draw it here too', () {
    // The instinct this blocks: reading the Web widget and concluding a
    // text block is "typography only", because that is what the class
    // name says. The Flutter twin wraps `blockquote` in a left-accent
    // `DecoratedBox` and `pre` in a surface-filled one, so a Web root
    // that emits only `text-*` renders a different component under the
    // same call — and `CoreTextBlockStyle` stays dead on this platform
    // while Flutter reads all six of its fields.
    testComponents('blockquote draws the left accent border', (tester) async {
      pumpWithTheme(
        tester,
        const TextBlock(text: 'T', element: CoreTextBlockElement.blockquote),
      );
      final style = _styleOf(tester, 'blockquote');

      // Longhands, so the accent lands on the left edge alone without
      // depending on a reset having zeroed the other three sides.
      expect(style['border-left-style'], 'solid');
      expect(style['border-left-width'], 'var(--coui-stroke-width-3)');
      expect(style['border-left-color'], 'rgb(var(--coui-outline-variant))');
      // `CoreTextBlockStyle.defaultBlockQuotePadding` is a *directional*
      // inset — the indent is a statement about where the text starts — so it
      // emits `padding-inline-start` and the browser mirrors it from `dir`.
      // The physical shorthand is not emitted at all: it has no logical
      // spelling, which is why asking for it throws.
      expect(style['padding-inline-start'], 'var(--coui-space-16)');
      expect(style['padding-inline-end'], 'var(--coui-space-0)');
      expect(style['padding'], isNull);
    });

    testComponents('pre draws the inline-code surface box', (tester) async {
      pumpWithTheme(
        tester,
        const TextBlock(text: 'T', element: CoreTextBlockElement.pre),
      );
      final style = _styleOf(tester, 'pre');

      expect(style['background-color'], 'rgb(var(--coui-surface-container))');
      expect(style['border-radius'], 'var(--coui-radius-4)');
      expect(
        style['padding'],
        '0.0625rem var(--coui-space-6) '
        '0.0625rem var(--coui-space-6)',
      );
    });

    testComponents('and a role with no box emits no chrome', (tester) async {
      pumpWithTheme(
        tester,
        const TextBlock(text: 'T'),
      );

      expect(_styleOf(tester, 'p'), isEmpty);
    });
  });

  group('a textBlockStyle override reaches the rendered element', () {
    // Declaring the slot is not implementing it. These read the value
    // back off the DOM, because a slot that is accepted, merged and then
    // never emitted looks complete from the call site and changes
    // nothing on screen.
    testComponents('a wider accent border', (tester) async {
      pumpWithTheme(
        tester,
        const TextBlock(
          text: 'T',
          element: CoreTextBlockElement.blockquote,
          textBlockStyle: CoreTextBlockStyle(
            blockQuoteBorderWidth: CoreStrokeWidth.stroke4,
          ),
        ),
      );

      expect(
        _styleOf(tester, 'blockquote')['border-left-width'],
        'var(--coui-stroke-width-4)',
      );
    });

    testComponents('a different indent', (tester) async {
      pumpWithTheme(
        tester,
        const TextBlock(
          text: 'T',
          element: CoreTextBlockElement.blockquote,
          textBlockStyle: CoreTextBlockStyle(
            blockQuotePadding: CoreEdgeInsets.all(CoreSpace.space8),
          ),
        ),
      );

      expect(
        _styleOf(tester, 'blockquote')['padding'],
        'var(--coui-space-8) var(--coui-space-8) '
        'var(--coui-space-8) var(--coui-space-8)',
      );
    });

    testComponents('a different code-box fill and radius', (tester) async {
      pumpWithTheme(
        tester,
        const TextBlock(
          text: 'T',
          element: CoreTextBlockElement.pre,
          textBlockStyle: CoreTextBlockStyle(
            inlineCodeBackgroundColor: CoreColor.token(CoreColors.primary),
            inlineCodeRadius: CoreRadius.radius8,
          ),
        ),
      );
      final style = _styleOf(tester, 'pre');

      // A token override stays a CSS variable, so dark mode keeps
      // reacting — the reason these emit inline instead of as a class is
      // preset collision, not the token.
      expect(style['background-color'], 'rgb(var(--coui-primary))');
      expect(style['border-radius'], 'var(--coui-radius-8)');
    });

    testComponents('and the override beats a preset class', (tester) async {
      // `TextBlock.inlineCode` also states the surface fill as a
      // `bg-{token}` utility class. Two statements of one property on a
      // class would race on stylesheet order; the resolved value rides
      // inline CSS so the override wins regardless of that order.
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) => TextBlock(
            text: 'T',
            element: CoreTextBlockElement.pre,
            presets: [TextBlock.inlineCode(context)],
            textBlockStyle: const CoreTextBlockStyle(
              inlineCodeBackgroundColor: CoreColor.token(CoreColors.primary),
            ),
          ),
        ),
      );

      expect(
        _styleOf(tester, 'pre')['background-color'],
        'rgb(var(--coui-primary))',
      );
    });
  });

  group('the two box roles state their own text', () {
    // The box is half of what the design fixes; the text inside it is the
    // other half. A role with no colour of its own inherits whatever the
    // surroundings set, so these read the class list the browser actually
    // receives.
    testComponents('a quote is the body role in on-surface-variant', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const TextBlock(text: 'T', element: CoreTextBlockElement.blockquote),
      );
      final classes = _classesOf(tester, 'blockquote');

      expect(classes, contains('text-body-medium'));
      expect(classes, contains('text-on-surface-variant'));
      expect(classes, isNot(contains('text-on-surface')));
    });

    testComponents('inline code is the fixed-width code role in on-surface', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const TextBlock(text: 'T', element: CoreTextBlockElement.pre),
      );
      final classes = _classesOf(tester, 'pre');

      expect(classes, contains('text-code-md'));
      expect(classes, contains('text-on-surface'));
      // The family comes with the role (its own box and family variables),
      // not from a body role with a family laid over it.
      expect(classes, isNot(contains('text-body-medium')));
      expect(classes.where((c) => c.startsWith('font-')), isEmpty);
    });

    testComponents('a role with no box keeps the plain element role', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const TextBlock(text: 'T'),
      );

      expect(_classesOf(tester, 'p'), {'text-body-medium'});
    });

    testComponents('a colour override replaces the colour, keeps the role', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const TextBlock(
          text: 'T',
          element: CoreTextBlockElement.blockquote,
          textBlockStyle: CoreTextBlockStyle(
            blockQuoteTextStyle: CoreTextStyle(
              color: CoreColor.token(CoreColors.primary),
            ),
          ),
        ),
      );
      final classes = _classesOf(tester, 'blockquote');

      expect(classes, contains('text-body-medium'));
      expect(classes, contains('text-primary'));
      expect(classes, isNot(contains('text-on-surface-variant')));
    });

    testComponents('a size override rides inline over the role class', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const TextBlock(
          text: 'T',
          element: CoreTextBlockElement.pre,
          textBlockStyle: CoreTextBlockStyle(
            inlineCodeTextStyle: CoreTextStyle(fontSize: CoreFontSize.s16),
          ),
        ),
      );

      expect(_classesOf(tester, 'pre'), contains('text-code-md'));
      expect(_styleOf(tester, 'pre')['font-size'], isNotNull);
    });

    testComponents('the defaults emit no inline typography', (tester) async {
      pumpWithTheme(
        tester,
        const TextBlock(text: 'T', element: CoreTextBlockElement.blockquote),
      );

      expect(
        _styleOf(tester, 'blockquote').keys,
        everyElement(isNot('font-size')),
      );
      expect(_styleOf(tester, 'blockquote')['color'], isNull);
    });

    testComponents('a preset is the whole typography contract', (tester) async {
      // The same replace-not-stack rule the element roles follow: a preset
      // brings its own role, so the slot's role does not stack under it.
      pumpWithTheme(
        tester,
        const TextBlock(
          text: 'T',
          element: CoreTextBlockElement.pre,
          presets: [TextBlock.italic],
        ),
      );

      expect(_classesOf(tester, 'pre'), {'italic'});
    });
  });

  group('the level the two platforms state is one value', () {
    test('the element carries it, so neither side can drift', () {
      // Flutter reads `headingLevel` off this enum and Web reads the tag
      // off the same value. A second table on either side is how the
      // outline would end up saying different things.
      expect(CoreTextBlockElement.h1.headingLevel, 1);
      expect(CoreTextBlockElement.h6.headingLevel, 6);
    });

    test('and a non-heading states null, never zero', () {
      // Flutter asserts a stated level is within 1..6, so zero throws at
      // the point the semantics are applied — it does not read as "not a
      // heading".
      for (final element in CoreTextBlockElement.values) {
        final level = element.headingLevel;
        expect(
          level == null || (level >= 1 && level <= 6),
          isTrue,
          reason: '${element.name} states $level',
        );
      }
    });
  });
}
