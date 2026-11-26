// Pins the Web half of the Join focus ring.
//
// The wrapper's `overflow: hidden` is emitted INLINE
// (`buildItemInlineStyles`), and CSS `overflow: hidden` clips descendant
// painting including `outline` — which is what the focus ring is here. So
// the Web strip erased its ring exactly the way the Flutter twin did.
//
// `!important` is not a style preference: no selector specificity beats an
// inline declaration, so a rule without it is inert. The same file already
// documents this for its radius rules. `the rule can beat the inline
// overflow` is the case that fails if someone "cleans it up".
//
// `z-index` needs `position` alongside it — a z-index on a statically
// positioned box does nothing — which is the other half of the pair.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The scoped `<style>` text the strip emits.
String _css(ComponentTester tester) {
  final styles = find.tag('style').evaluate();
  expect(styles, isNotEmpty, reason: 'the strip emits a scoped style block');

  final buffer = StringBuffer();
  for (final element in styles) {
    for (final child in (element.component as DomComponent).children ?? []) {
      if (child is RawText) buffer.write(child.text);
    }
  }

  return buffer.toString();
}

Component _strip({int count = 3}) => Join(
  children: [
    for (var i = 0; i < count; i++) Button(onPressed: () {}, child: Text('$i')),
  ],
);

void main() {
  group('Join focus ring rules', () {
    testComponents('a focus-within rule is emitted', (tester) async {
      pumpWithTheme(tester, _strip());

      expect(_css(tester), contains(':focus-within'));
    });

    for (final count in [1, 3]) {
      testComponents('the focus-within rule names the strip it belongs to '
          '($count item${count == 1 ? '' : 's'})', (tester) async {
        // The selector must interpolate the strip's id. A `#\$scopeId`
        // escape once wrote the six characters `$scopeId` verbatim — a
        // selector that matches nothing, so the ring stayed clipped while
        // a bare `contains(':focus-within')` still passed.
        pumpWithTheme(tester, _strip(count: count));
        final css = _css(tester);
        final scope = RegExp(r'#(\S+) > div > \*').firstMatch(css)?.group(1);

        expect(scope, isNotNull, reason: 'the strip pins its rules to an id');
        expect(scope, isNot(r'$scopeId'));
        expect(css, contains('#$scope > div:focus-within {'));
        expect(css, isNot(contains(r'#$scopeId')));
      });
    }

    testComponents('the rule can beat the inline overflow', (tester) async {
      pumpWithTheme(tester, _strip());
      final css = _css(tester);

      expect(
        css,
        contains('overflow: visible !important'),
        reason:
            'the wrapper carries overflow inline, which no selector '
            'specificity can override without !important',
      );
    });

    testComponents('the item is lifted over its next sibling', (tester) async {
      pumpWithTheme(tester, _strip());
      final css = _css(tester);

      expect(css, contains('z-index'));
      expect(
        css,
        contains('position: relative'),
        reason: 'z-index does nothing on a statically positioned box',
      );
    });

    testComponents('a single-item strip still lets its ring out', (
      tester,
    ) async {
      // No neighbour to cover it, but its own wrapper still clips.
      pumpWithTheme(tester, _strip(count: 1));

      expect(_css(tester), contains('overflow: visible !important'));
    });

    testComponents('the ring rides the element whose radius is squared', (
      tester,
    ) async {
      // The Web half of "a middle item's ring is square at its seams". The
      // Flutter twin had to be taught this — its ring radius is resolved
      // separately from the chrome — but here the ring is an `outline`,
      // and an outline takes its corners from the element that carries
      // it. So the ring is square exactly when the squaring rule lands on
      // the SAME element that carries the ring classes. Pin both halves:
      // the rule targets the wrapper's direct child, and that child is the
      // one with the ring.
      pumpWithTheme(tester, _strip());

      expect(
        _css(tester),
        contains(
          '> div > * { border-radius: '
          '${CoreBorderRadius.zero.toValue()} !important',
        ),
        reason: "the seam rule squares the wrapper's direct child",
      );

      final wrappers = find.tag('div').evaluate().where((element) {
        final dom = element.component as DomComponent;

        return (dom.styles?.properties ?? const {})['overflow'] == 'hidden';
      }).toList();
      expect(wrappers, hasLength(3));

      for (final wrapper in wrappers) {
        final directChildren = <DomComponent>[];
        void firstDom(Element element) {
          if (element.component is DomComponent) {
            directChildren.add(element.component as DomComponent);
          } else {
            element.visitChildren(firstDom);
          }
        }

        wrapper.visitChildren(firstDom);

        expect(directChildren, hasLength(1));
        expect(
          directChildren.single.classes,
          contains('focus-visible:outline-'),
          reason:
              'if the ring moved to an inner or overlay element, it would '
              'keep its own rounded corners under a squared box',
        );
      }
    });

    testComponents('the wrapper really does carry overflow inline', (
      tester,
    ) async {
      // Pins the premise the !important rests on. If the emit ever moves to
      // a class, the rule can drop !important — and this case says so by
      // failing.
      pumpWithTheme(tester, _strip());

      final hasInlineOverflow = find.tag('div').evaluate().any((element) {
        final dom = element.component as DomComponent;

        return (dom.styles?.properties ?? const {})['overflow'] == 'hidden';
      });

      expect(hasInlineOverflow, isTrue);
    });
  });
}
