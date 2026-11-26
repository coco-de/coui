import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/form/radio_group/radio_group.dart';
import 'package:jaspr/dom.dart' show RawText;
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Every rendered radio, in option order.
Finder _radios() => find.byComponentPredicate(
  (component) =>
      component is DomComponent && component.attributes?['role'] == 'radio',
);

/// Positions of the radios rendering as checked, in option order.
///
/// Read off `aria-checked` rather than internal state — that attribute is
/// what a screen reader and the selected-radio styling both key on, so it
/// is the thing that has to move.
List<int> _checkedIndices() {
  final finder = _radios();

  final checked = <int>[];
  var index = 0;
  for (final element in finder.evaluate()) {
    final attributes = (element.component as DomComponent).attributes!;
    if (attributes['aria-checked'] == 'true') checked.add(index);
    index++;
  }

  return checked;
}

/// Inline styles of every rendered radio circle, in option order.
List<Map<String, String>> _allRadioStyles() => [
  for (final element in _radios().evaluate())
    (element.component as DomComponent).styles!.properties,
];

/// Inline styles of the single rendered radio circle.
Map<String, String> _radioStyles() => _allRadioStyles().single;

/// Inline styles of the single rendered inner dot.
Map<String, String> _dotStyles(ComponentTester tester) {
  final dot = find.byComponentPredicate(
    (c) =>
        c is DomComponent && (c.classes ?? '').contains('transition-transform'),
  );

  return (dot.evaluate().single.component as DomComponent).styles!.properties;
}

void main() {
  group('RadioGroup', () {
    testComponents('renders one radio option per entry', (tester) async {
      pumpWithTheme(
        tester,
        const RadioGroup(
          value: 'a',
          options: [
            (value: 'a', label: 'Option A'),
            (value: 'b', label: 'Option B'),
          ],
        ),
      );

      expect(find.text('Option A'), findsOneComponent);
      expect(find.text('Option B'), findsOneComponent);
    });

    testComponents('renders a custom child, bypassing options', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const RadioGroup(child: Component.text('Custom radios')),
      );

      expect(find.text('Custom radios'), findsOneComponent);
    });

    test('accepts custom id', () {
      const group = RadioGroup(
        id: 'radio-1',
        options: [(value: 'a', label: 'A')],
      );
      expect(group.id, equals('radio-1'));
    });

    test('sets name attribute', () {
      const group = RadioGroup(
        name: 'plan',
        options: [(value: 'a', label: 'A')],
      );
      expect(group.name, equals('plan'));
    });

    test('copyWith preserves properties', () {
      const original = RadioGroup(
        value: 'a',
        enabled: false,
        name: 'plan',
        orientation: .horizontal,
        id: 'radio-orig',
        options: [(value: 'a', label: 'A')],
      );

      final copy = original.copyWith(id: 'radio-new');

      expect(copy.id, equals('radio-new'));
      expect(copy.value, equals('a'));
      expect(copy.enabled, isFalse);
      expect(copy.name, equals('plan'));
      expect(copy.orientation, equals(CoreRadioGroupOrientation.horizontal));
    });

    test('implements CoreRadioGroupContract', () {
      const group = RadioGroup(
        value: 'a',
        size: CoreComponentSize.lg,
        orientation: .horizontal,
        options: [(value: 'a', label: 'A')],
      );

      expect(group.value, equals('a'));
      expect(group.size, equals(CoreComponentSize.lg));
      expect(group.orientation, equals(CoreRadioGroupOrientation.horizontal));
    });

    // `initialValue` is the mode where the group owns its selection. A test
    // that only checked the field exists would pass while the group still
    // read `value` and rendered nothing selected.
    testComponents('initialValue selects that option on first render', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        RadioGroup(
          onChanged: (_) {},
          initialValue: 'b',
          options: const [
            (value: 'a', label: 'Option A'),
            (value: 'b', label: 'Option B'),
          ],
        ),
      );
      await tester.pump();

      expect(_checkedIndices(), equals([1]));
    });

    testComponents('an uncontrolled group moves on its own', (tester) async {
      // Nobody hands the value back in this mode, so if the group does not
      // record the pick itself the selection never moves — the callback
      // fires and the screen stays put.
      final picked = <String?>[];
      pumpWithTheme(
        tester,
        RadioGroup(
          onChanged: picked.add,
          initialValue: 'a',
          options: const [
            (value: 'a', label: 'Option A'),
            (value: 'b', label: 'Option B'),
          ],
        ),
      );
      await tester.pump();

      await tester.click(_radios().at(1));

      expect(picked, equals(['b']));
      expect(_checkedIndices(), equals([1]));
    });

    testComponents('a controlled group still waits for its owner', (
      tester,
    ) async {
      // The other half of the exclusivity: without `initialValue` the group
      // must not start selecting on its own, or a caller driving `value`
      // would see the selection move twice.
      final picked = <String?>[];
      pumpWithTheme(
        tester,
        RadioGroup(
          onChanged: picked.add,
          value: 'a',
          options: const [
            (value: 'a', label: 'Option A'),
            (value: 'b', label: 'Option B'),
          ],
        ),
      );
      await tester.pump();

      await tester.click(_radios().at(1));

      expect(picked, equals(['b']));
      expect(_checkedIndices(), equals([0]));
    });
  });

  group('Radio redesign chrome', () {
    // Every element that carries `role="radio"`, plus a class lookup helper.
    String classesOf(Finder finder) =>
        (finder.evaluate().single.component as DomComponent).classes ?? '';

    // The dot is not drawn by default — the selected ring carries the
    // selection — so a disabled selected radio is told from a disabled
    // unselected one by its ring alone: the selected width in the
    // disabled-content colour, over the disabled container.
    testComponents('a disabled selected radio wears the selected width in '
        'disabled-content on its ring and draws no dot', (tester) async {
      pumpWithTheme(
        tester,
        const Radio(value: 'a', groupValue: 'a', label: 'A', enabled: false),
      );
      await tester.pump();

      final button = classesOf(_radios());
      expect(button, contains('bg-disabled-container'));
      expect(button, contains('border-disabled-content'));
      // The negative control: the colour a disabled unselected ring rests
      // on must not be what the selected one wears.
      expect(button, isNot(contains('border-disabled-outline')));
      // Disabled rows wear no state-layer scope and ship no rule.
      expect(button, isNot(contains('co-radio-sl-')));
      expect(find.tag('style'), findsNothing);
      expect(_dotStyles(tester)['width'], '0.0rem');
      expect(_dotStyles(tester)['height'], '0.0rem');
      // A disabled selected ring keeps the selected width (the Flutter
      // twin's `disabledSelectedRingContainerStyle`).
      expect(
        _radioStyles()['border-width'],
        'var(--coui-stroke-width-4)',
      );
    });

    testComponents('a disabled unselected radio rests on disabled-outline at '
        'the resting width', (tester) async {
      pumpWithTheme(
        tester,
        const Radio(value: 'b', groupValue: 'a', label: 'B', enabled: false),
      );
      await tester.pump();

      final button = classesOf(_radios());
      expect(button, contains('bg-disabled-container'));
      expect(button, contains('border-disabled-outline'));
      expect(button, isNot(contains('border-disabled-content')));
      expect(
        _radioStyles()['border-width'],
        'var(--coui-stroke-width-1)',
      );
    });

    testComponents('the disabled selected width follows the size ladder', (
      tester,
    ) async {
      Future<List<String?>> widthsAt(CoreComponentSize size) async {
        pumpWithTheme(
          tester,
          RadioGroup(
            value: 'a',
            enabled: false,
            size: size,
            options: const [
              (value: 'a', label: 'A'),
              (value: 'b', label: 'B'),
            ],
          ),
        );
        await tester.pump();

        return [for (final s in _allRadioStyles()) s['border-width']];
      }

      expect(await widthsAt(.xs), [
        'var(--coui-stroke-width-3)',
        'var(--coui-stroke-width-1)',
      ]);
      expect(await widthsAt(.xl2), [
        'var(--coui-stroke-width-6)',
        'var(--coui-stroke-width-1)',
      ]);
    });

    testComponents(
      'a restated dot on a disabled selected radio sits in disabled-content',
      (tester) async {
        pumpWithTheme(
          tester,
          const RadioGroup(
            value: 'a',
            enabled: false,
            radioGroupStyle: CoreRadioGroupStyle(
              innerDotSize: CoreSize.size8,
            ),
            options: [(value: 'a', label: 'A')],
          ),
        );
        await tester.pump();

        final dot = find.byComponentPredicate(
          (c) =>
              c is DomComponent &&
              (c.classes ?? '').contains('scale-100') &&
              (c.classes ?? '').contains('bg-disabled-content'),
        );
        expect(dot, findsOneComponent);
        expect(_dotStyles(tester)['width'], '${CoreSize.size8 / 16}rem');
      },
    );

    // The selection is the ring: a selected ring is heavier than a resting
    // one. Read off the inline `border-width`, which rides the stroke
    // variable so a surface style's stroke floor reaches it.
    testComponents('the selected ring is heavier than the resting one', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        RadioGroup(
          value: 'a',
          onChanged: (_) {},
          options: const [
            (value: 'a', label: 'A'),
            (value: 'b', label: 'B'),
          ],
        ),
      );
      await tester.pump();

      expect(
        [for (final styles in _allRadioStyles()) styles['border-width']],
        [
          'var(--coui-stroke-width-4)',
          'var(--coui-stroke-width-1)',
        ],
      );
      // The halo's inset takes each state's own stroke, so its outer edge
      // sits `spread` beyond the circle whatever the ring's weight.
      final halos = find
          .byComponentPredicate(
            (c) =>
                c is DomComponent &&
                (c.classes ?? '').contains('co-radio-halo'),
          )
          .evaluate()
          .map((e) => (e.component as DomComponent).styles!.properties);
      expect(halos.map((h) => h['inset']), [
        'calc(-${CoreSpace.space4 / 16}rem - var(--coui-stroke-width-4))',
        'calc(-${CoreSpace.space4 / 16}rem - var(--coui-stroke-width-1))',
      ]);
      // No dot by default: both dot boxes are zero-sized.
      final dots = find
          .byComponentPredicate(
            (c) =>
                c is DomComponent &&
                (c.classes ?? '').contains('transition-transform'),
          )
          .evaluate()
          .map((e) => (e.component as DomComponent).styles!.properties);
      expect(dots.map((d) => d['width']), ['0.0rem', '0.0rem']);
    });

    testComponents('the selected width follows the size ladder, every size '
        'states one', (tester) async {
      Future<List<String?>> widthsAt(CoreComponentSize size) async {
        pumpWithTheme(
          tester,
          RadioGroup(
            value: 'a',
            size: size,
            onChanged: (_) {},
            options: const [
              (value: 'a', label: 'A'),
              (value: 'b', label: 'B'),
            ],
          ),
        );
        await tester.pump();

        return [for (final s in _allRadioStyles()) s['border-width']];
      }

      expect(await widthsAt(.xs), [
        'var(--coui-stroke-width-3)',
        'var(--coui-stroke-width-1)',
      ]);
      expect(await widthsAt(.sm), [
        'var(--coui-stroke-width-4)',
        'var(--coui-stroke-width-1)',
      ]);
      expect(await widthsAt(.md), [
        'var(--coui-stroke-width-4)',
        'var(--coui-stroke-width-1)',
      ]);
      expect(await widthsAt(.xl2), [
        'var(--coui-stroke-width-6)',
        'var(--coui-stroke-width-1)',
      ]);
      expect(await widthsAt(.lg), [
        'var(--coui-stroke-width-5)',
        'var(--coui-stroke-width-1)',
      ]);
      expect(await widthsAt(.xl), [
        'var(--coui-stroke-width-5)',
        'var(--coui-stroke-width-1)',
      ]);
    });

    testComponents('restating one width leaves the other on its size row', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        RadioGroup(
          value: 'a',
          onChanged: (_) {},
          radioGroupStyle: const CoreRadioGroupStyle(
            indicatorBorderWidth: CoreStrokeWidth.stroke3,
          ),
          options: const [
            (value: 'a', label: 'A'),
            (value: 'b', label: 'B'),
          ],
        ),
      );
      await tester.pump();

      expect(
        [for (final s in _allRadioStyles()) s['border-width']],
        ['var(--coui-stroke-width-4)', 'var(--coui-stroke-width-3)'],
      );
    });

    // The ring grows on the selection, so the width rides the colour clock
    // — Flutter interpolates it through the same `AnimatedContainer`. The
    // class names the colours alone; the inline property list adds the
    // width and keeps the resolved duration and class's curve.
    testComponents('the ring width transitions with the ring colour', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Radio(value: 'a', groupValue: 'a', label: 'A'),
      );
      await tester.pump();

      final button = _radios().evaluate().single.component as DomComponent;
      expect(button.classes, contains('transition-colors'));
      expect(
        button.styles?.properties['transition-duration'],
        'var(--coui-duration-100)',
      );
      expect(
        button.styles?.properties['transition-property'],
        contains('border-width'),
      );
      expect(
        button.styles?.properties['transition-property'],
        contains('border-color'),
      );
    });

    testComponents('label role is body-small at the size ladder step', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Radio(
          value: 'a',
          groupValue: 'b',
          label: 'A',
          groupSize: CoreComponentSize.xl2,
        ),
      );
      await tester.pump();

      final label = find.byComponentPredicate(
        (c) => c is DomComponent && c.tag == 'label',
      );
      expect(classesOf(label), contains('text-body-small'));
      expect(classesOf(label), contains('text-on-surface'));
      final styles = (label.evaluate().single.component as DomComponent)
          .styles
          ?.properties;
      expect(styles?['font-size'], '${CoreFontSize.s16 / 16}rem');
    });

    testComponents('the halo is mounted at rest and the root carries the '
        'hover / active rules', (tester) async {
      pumpWithTheme(
        tester,
        Radio(value: 'a', groupValue: 'b', label: 'A', onChanged: (_) {}),
      );
      await tester.pump();

      final halo = find.byComponentPredicate(
        (c) => c is DomComponent && (c.classes ?? '').contains('co-radio-halo'),
      );
      expect(halo, findsOneComponent);
      final haloDom = halo.evaluate().single.component as DomComponent;
      expect(haloDom.classes, contains('bg-on-surface'));
      // Rests at 0 through a class. An inline `opacity` beats every rule
      // without `!important`, so it would pin the halo at rest under the
      // scoped `:hover` / `:active` rules below.
      expect(haloDom.classes!.split(' '), contains('opacity-0'));
      expect(haloDom.styles?.properties.containsKey('opacity'), isFalse);
      // `spread` beyond the circle's outer edge: the inset is measured from
      // the padding box, so the ring's own stroke rides on top of the spread.
      expect(
        haloDom.styles?.properties['inset'],
        'calc(-${CoreSpace.space4 / 16}rem - var(--coui-stroke-width-1))',
      );
      // The inset moves with the ring stroke on its clock, so the halo's
      // outer edge holds still while the ring grows under it.
      expect(
        haloDom.styles?.properties['transition-property'],
        'opacity, inset',
      );

      final label = find.byComponentPredicate(
        (c) => c is DomComponent && c.tag == 'label',
      );
      final scope = RegExp(
        'co-radio-sl-[0-9a-z]+',
      ).firstMatch(classesOf(label))?.group(0);
      expect(scope, isNotNull);
      final style = find.tag('style');
      expect(style, findsOneComponent);
      final css = (style.evaluate().single.component as DomComponent).children!
          .whereType<RawText>()
          .single
          .text;
      expect(css, contains('.$scope:hover .co-radio-halo{opacity:0.08;}'));
      expect(css, contains('.$scope:active .co-radio-halo{opacity:0.16;}'));
    });

    testComponents(
      'the unselected ring rests on outline with no fill',
      (
        tester,
      ) async {
        pumpWithTheme(tester, const Radio(value: 'a', groupValue: 'b'));
        await tester.pump();

        final button = _radios().evaluate().single.component as DomComponent;
        // Whole classes: `border-outline` is a prefix of
        // `border-outline-variant`, so a substring check cannot tell the
        // control edge from the hairline tone.
        final classes = button.classes!.split(RegExp(r'\s+')).toSet();
        expect(classes, contains('border-outline'));
        expect(classes, isNot(contains('border-outline-variant')));
        expect(button.classes, isNot(contains('bg-surface-container')));
        // The transparent sentinel is token-less, so it goes inline.
        expect(
          button.styles?.properties['background-color'],
          'rgba(0, 0, 0, 0.00)',
        );
      },
    );
  });

  group('Radio', () {
    testComponents('renders label', (tester) async {
      pumpWithTheme(tester, const Radio(value: 'x', label: 'Choice X'));

      expect(find.text('Choice X'), findsOneComponent);
    });

    test('accepts custom id', () {
      const radio = Radio(value: 'x', id: 'radio-x');
      expect(radio.id, equals('radio-x'));
    });

    test('implements CoreRadioItemContract', () {
      const radio = Radio(value: 'x', groupValue: 'x', enabled: false);

      expect(radio.value, equals('x'));
      expect(radio.groupValue, equals('x'));
      expect(radio.enabled, isFalse);
    });

    // Outside a group there are no arrow keys to reach a sibling with, so
    // a roving tab stop would leave every unselected radio unreachable.
    testComponents('on its own, an unselected radio keeps its tab stop', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Radio(value: 'b', groupValue: 'a', label: 'B', onChanged: (_) {}),
      );
      await tester.pump();

      final circle = _radios().evaluate().single.component as DomComponent;
      expect(circle.attributes!['aria-checked'], 'false');
      expect(circle.attributes!['tabindex'], '0');
    });

    testComponents('inside a group, an unselected radio leaves the tab order', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        RadioGroup(
          value: 'a',
          onChanged: (_) {},
          options: const [
            (value: 'a', label: 'A'),
            (value: 'b', label: 'B'),
          ],
        ),
      );
      await tester.pump();

      final tabIndices = [
        for (final element in _radios().evaluate())
          (element.component as DomComponent).attributes!['tabindex'],
      ];
      expect(tabIndices, ['0', '-1']);
    });
  });
}
