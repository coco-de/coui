import 'package:coui_web/coui_web.dart';
// card_image_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/layout/card_image/card_image_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

ResolvedCardImage _resolve(
  ComponentTester tester, {
  CoreCardImageStyle? cardImageStyle,
  bool disabled = false,
}) => resolveCardImage(
  _themedContext(tester),
  interactive: true,
  hovered: false,
  disabled: disabled,
  cardImageStyle: cardImageStyle,
);

List<String> _classes(WebElementChrome chrome) => chrome.className.split(' ');

void main() {
  _redesignTests();

  group(
    'CardImage resolver — the card is stretched, like the Flutter twin',
    () {
      // Flutter lays the card out as a `Flex` with `crossAxisAlignment:
      // stretch`, so the text slot fills the card and `Basic`'s trailing
      // chevron sits at the card's end. With `items-start` the slot shrank to
      // its text and the chevron sat right beside it.
      testComponents('a vertical card stretches its children across', (
        tester,
      ) async {
        final classes = _classes(_resolve(tester).body);

        expect(classes, containsAll(['flex', 'flex-col', 'items-stretch']));
        expect(classes, isNot(contains('items-start')));
      });

      testComponents('a horizontal card stretches its children down', (
        tester,
      ) async {
        final classes = _classes(
          _resolve(
            tester,
            cardImageStyle: const CoreCardImageStyle(
              direction: CoreAxis.horizontal,
            ),
          ).body,
        );

        expect(classes, containsAll(['flex', 'flex-row', 'items-stretch']));
        expect(classes, isNot(contains('items-start')));
      });

      // `Basic`'s root is `inline-flex`, so inside a plain block it hugs its
      // content whatever the width of the block. As a flex item of a stretching
      // column it is stretched, which is what lets its title column fill and
      // push the trailing slot to the end.
      testComponents('the text slot is a stretching column holding Basic', (
        tester,
      ) async {
        final classes = _classes(_resolve(tester).textSlot);

        expect(classes, containsAll(['flex', 'flex-col', 'items-stretch']));
        // Long titles still wrap inside it.
        expect(classes, contains('min-w-0'));
      });
    },
  );
}

// ─── The redesigned card, read off the rendered DOM ─────────────────────────
//
// Every value below is read from what reached the markup, and every expected
// value is built from the Core default it comes from — never a literal — so a
// retuned token moves the expectation with it, and a value that is resolved
// but never emitted still fails.

/// Every rendered element, in document order.
List<DomComponent> _elements() => [
  for (final e
      in find.byComponentPredicate((c) => c is DomComponent).evaluate())
    e.component as DomComponent,
];

/// The rendered root of the [index]-th composed `OutlinedContainer` — 0 is
/// the card's box, 1 the image frame.
DomComponent _box(int index) => _elements()
    .where((c) => (c.classes ?? '').split(' ').contains('coui-surface'))
    .elementAt(index);

Map<String, String> _css(DomComponent c) => c.styles?.properties ?? const {};

void _pumpCard(ComponentTester tester, {bool? enabled}) => pumpWithTheme(
  tester,
  CardImage(
    image: const img(src: 'x.png'),
    title: const Component.text('산 풍경'),
    subtitle: const Component.text('해 뜰 무렵 촬영'),
    enabled: enabled,
    onPressed: () {},
  ),
);

void _redesignTests() {
  group('CardImage — the card is a box', () {
    testComponents('the box is surface with an outline-variant edge, 16 '
        'corners and a clip', (tester) async {
      _pumpCard(tester);
      final box = _box(0);
      final classes = (box.classes ?? '').split(' ');

      const fill = CoreOutlinedContainerStyle.defaultBackgroundColor;
      const edge = CoreOutlinedContainerStyle.defaultBorderColor;
      expect(
        classes,
        containsAll([
          'bg-${fill.tailwindColor}',
          'border-${edge.tailwindColor}',
        ]),
      );
      expect(
        _css(box)['border-width'],
        strokeWidthCss(CoreOutlinedContainerStyle.defaultBorderWidth),
      );
      expect(
        _css(box)['border-radius'],
        CoreOutlinedContainerStyle.defaultBorderRadius.toValue(),
      );
      expect(_css(box)['overflow'], 'hidden');
    });

    testComponents('the box leaves 14 under the text row and nothing on the '
        'other sides', (tester) async {
      _pumpCard(tester);
      final padding = _css(_box(0))['padding']!.split(') calc(');

      final bottom = CoreCardImageStyle.defaultContainerStyle.padding!.bottom;
      expect(bottom, CoreSpace.space14);
      expect(padding[2], startsWith(spaceCss(bottom)));
      for (final side in [padding[0], padding[1], padding[3]]) {
        expect(side.replaceFirst('calc(', ''), startsWith(spaceCss(0)));
      }
    });

    testComponents('the image frame is a square surface-container fill with '
        'no edge', (tester) async {
      _pumpCard(tester);
      final frame = _box(1);

      expect(
        (frame.classes ?? '').split(' '),
        contains('bg-${CoreColors.surfaceContainer.name}'),
      );
      expect(
        _css(frame)['border-radius'],
        CoreBorderRadius.zero.toValue(),
      );
      expect(_css(frame)['border-width'], strokeWidthCss(0));
    });

    testComponents('the text row is set 14 from the start and 10 from the '
        'end, following the reading direction', (tester) async {
      _pumpCard(tester);
      final row = _elements().firstWhere(
        (c) => _css(c).containsKey('padding-inline-start'),
      );

      expect(_css(row)['padding-inline-start'], spaceCss(CoreSpace.space14));
      expect(_css(row)['padding-inline-end'], spaceCss(CoreSpace.space10));
    });

    testComponents('the title is label-xl at semibold, the subtitle '
        'body-small in on-surface-variant', (tester) async {
      _pumpCard(tester);
      final title = _elements().firstWhere(
        (c) => (c.classes ?? '').contains('text-label-xl'),
      );
      final subtitle = _elements().firstWhere(
        (c) => (c.classes ?? '').contains('text-body-small'),
      );

      expect(_css(title)['font-weight'], '${CoreFontWeight.semiBold}');
      expect(
        (subtitle.classes ?? '').split(' '),
        contains('text-${CoreColors.onSurfaceVariant.name}'),
      );
    });

    testComponents('a disabled card dims the image and the text row, not '
        'the box', (tester) async {
      _pumpCard(tester, enabled: false);
      final dimmed = _elements()
          .where((c) => _css(c).containsKey('opacity'))
          .toList();

      expect(dimmed, hasLength(2));
      for (final c in dimmed) {
        expect(_css(c)['opacity'], '${CoreOpacity.disabled}');
      }
      expect(_css(_box(0)).containsKey('opacity'), isFalse);
    });

    testComponents('an enabled card dims nothing', (tester) async {
      _pumpCard(tester);

      expect(
        _elements().where((c) => _css(c).containsKey('opacity')),
        isEmpty,
      );
    });

    testComponents('a card with no onPressed is content, and enabled: false '
        'does not dim it', (tester) async {
      pumpWithTheme(
        tester,
        const CardImage(image: img(src: 'x.png'), enabled: false),
      );

      expect(
        _elements().where((c) => _css(c).containsKey('opacity')),
        isEmpty,
      );
    });

    testComponents('an enabled card casts the xs stack from its box', (
      tester,
    ) async {
      _pumpCard(tester);

      expect(
        CoreCardImageStyle.defaultContainerStyle.boxShadow,
        CoreShadow.xs,
      );
      expect(
        _css(_box(0))['box-shadow'],
        startsWith('var(--shadow-${CoreShadow.scale.xs})'),
      );
    });

    testComponents('a disabled card drops its cast', (tester) async {
      _pumpCard(tester, enabled: false);

      expect(_css(_box(0))['box-shadow'], 'none');
    });

    testComponents('the disabled opacity is overridable', (tester) async {
      final resolved = _resolve(
        tester,
        disabled: true,
        cardImageStyle: const CoreCardImageStyle(disabledContentOpacity: 0.5),
      );

      expect(resolved.imageLayer.inlineStyles?.properties['opacity'], '0.5');
      expect(resolved.textSlot.inlineStyles?.properties['opacity'], '0.5');
    });
  });
}
