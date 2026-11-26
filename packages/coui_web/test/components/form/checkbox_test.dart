import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/form/checkbox/checkbox.dart';
import 'package:coui_web/src/components/form/checkbox/checkbox_style.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const Component.text('');
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

void main() {
  group('Checkbox', () {
    testComponents('renders with default tag', (tester) async {
      pumpWithTheme(tester, const Checkbox());

      // Checkbox renders a <div>-based structure (root + square + slots).
      expect(find.tag('div'), findsComponents);
    });

    test('accepts custom id', () {
      const checkbox = Checkbox(id: 'cb-1');
      expect(checkbox.id, equals('cb-1'));
    });

    test('sets aria-checked=false when unchecked', () {
      const checkbox = Checkbox();
      final attrs = checkbox.componentAttributes;

      expect(attrs['aria-checked'], equals('false'));
    });

    test('sets aria-checked=true when checked', () {
      const checkbox = Checkbox(checked: true);
      final attrs = checkbox.componentAttributes;

      expect(attrs['aria-checked'], equals('true'));
    });

    test('sets aria-checked=mixed when indeterminate', () {
      const checkbox = Checkbox(checked: null);
      final attrs = checkbox.componentAttributes;

      expect(attrs['aria-checked'], equals('mixed'));
    });

    test('sets disabled attributes when not enabled', () {
      const checkbox = Checkbox(enabled: false);
      final attrs = checkbox.componentAttributes;

      expect(attrs['aria-disabled'], equals('true'));
    });

    test('sets name attribute', () {
      const checkbox = Checkbox(name: 'agree');
      expect(checkbox.name, equals('agree'));
    });

    test('copyWith preserves properties', () {
      const original = Checkbox(
        checked: true,
        enabled: false,
        name: 'terms',
        id: 'cb-terms',
      );

      final copy = original.copyWith(id: 'cb-new');

      expect(copy.id, equals('cb-new'));
      expect(copy.checked, isTrue);
      expect(copy.enabled, isFalse);
      expect(copy.name, equals('terms'));
    });

    test('copyWith changes the value only when told to', () {
      const original = Checkbox();

      // `null` is a real value (indeterminate), so it cannot double as
      // "keep mine" — the flag is what says the value was supplied.
      expect(original.copyWith(checked: true).checked, isFalse);
      expect(
        original.copyWith(checked: true, checkedProvided: true).checked,
        isTrue,
      );
      expect(
        original.copyWith(checkedProvided: true).checked,
        isNull,
      );
    });

    test('implements CoreCheckboxContract', () {
      const checkbox = Checkbox(
        checked: true,
        enabled: true,
        label: 'Test',
      );

      expect(checkbox.checked, isTrue);
      expect(checkbox.enabled, isTrue);
      expect(checkbox.label, equals('Test'));
    });
  });

  group('resolveCheckbox — the redesign reaches the DOM', () {
    testComponents(
      'the box wears the 1 px line and radius4 at every size',
      (
        tester,
      ) async {
        // Stroke and corner are size-invariant — the two values a
        // generator on the size axis kept moving.
        final context = _themedContext(tester);
        for (final size in CoreComponentSize.values) {
          final resolved = resolveCheckbox(
            context,
            size: size,
            checked: false,
            enabled: true,
          );
          expect(
            resolved.box.className,
            contains(
              'border-'
              '${CoreCheckboxStyle.defaultBoxBorderWidth.tailwindStroke}',
            ),
            reason: '${size.name} stroke drifted off the 1 px line',
          );
          expect(
            resolved.box.inlineStyles!.properties['border-radius'],
            CoreCheckboxStyle.defaultBoxBorderRadius.toValue(),
            reason: '${size.name} corner drifted off radius4',
          );
        }
      },
    );

    testComponents('an off-scale box stroke rides inline instead of crashing', (
      tester,
    ) async {
      // A caller-supplied width that is not a `CoreStrokeWidth` step has
      // no `border-strokeN` class — reading it through the class getter
      // threw at render. It goes inline, and the default class is dropped
      // so the two never fight over `border-width`.
      final resolved = resolveCheckbox(
        _themedContext(tester),
        size: CoreComponentSize.md,
        checked: false,
        enabled: true,
        checkboxStyle: const CoreCheckboxStyle(boxBorderWidth: 1.25),
      );
      expect(resolved.box.className, isNot(contains('border-stroke')));
      expect(
        resolved.box.inlineStyles!.properties['border-width'],
        '1.25px',
      );
    });

    testComponents('a token box stroke override stays on its variable', (
      tester,
    ) async {
      final resolved = resolveCheckbox(
        _themedContext(tester),
        size: CoreComponentSize.md,
        checked: true,
        enabled: true,
        checkboxStyle: const CoreCheckboxStyle(
          boxBorderWidth: CoreStrokeWidth.stroke2,
        ),
      );
      expect(resolved.box.className, isNot(contains('border-stroke')));
      expect(
        resolved.box.inlineStyles!.properties['border-width'],
        strokeWidthCss(CoreStrokeWidth.stroke2),
      );
    });

    testComponents('the default box stroke emits no inline border-width', (
      tester,
    ) async {
      final resolved = resolveCheckbox(
        _themedContext(tester),
        size: CoreComponentSize.md,
        checked: false,
        enabled: true,
      );
      expect(
        resolved.box.inlineStyles!.properties.containsKey('border-width'),
        isFalse,
      );
    });

    testComponents('a resting box has no fill and an outline stroke', (
      tester,
    ) async {
      final resolved = resolveCheckbox(
        _themedContext(tester),
        size: CoreComponentSize.md,
        checked: false,
        enabled: true,
      );
      expect(resolved.box.className, isNot(contains(' bg-')));
      // Whole classes: `border-outline` is a prefix of
      // `border-outline-variant`, so a substring check cannot tell the
      // control edge from the variant tone.
      final classes = resolved.box.className.split(RegExp(r'\s+')).toSet();
      expect(classes, contains('border-outline'));
      expect(classes, isNot(contains('border-outline-variant')));
      expect(
        CoreCheckboxStyle.defaultBoxBorderColor.tailwindColor,
        'outline',
      );
    });

    testComponents(
      'a disabled checked box paints its mark in the disabled ink',
      (tester) async {
        final resolved = resolveCheckbox(
          _themedContext(tester),
          size: CoreComponentSize.md,
          checked: true,
          enabled: false,
        );
        expect(
          resolved.checkmarkIconStyle.color,
          CoreCheckboxStyle.defaultDisabledCheckmarkColor,
        );
        expect(
          resolved.checkGlyph.className,
          contains(
            'text-'
            '${CoreCheckboxStyle.defaultDisabledCheckmarkColor.tailwindColor}',
          ),
        );
      },
    );

    testComponents('the indeterminate glyph is a dash, not a square', (
      tester,
    ) async {
      final resolved = resolveCheckbox(
        _themedContext(tester),
        size: CoreComponentSize.md,
        checked: null,
        enabled: true,
      );
      final md = CoreCheckboxStyle.defaultsBySize[CoreComponentSize.md]!;
      expect(
        resolved.indicator.inlineStyles!.properties['width'],
        'var(--coui-size-${md.indeterminateLength!.toInt()})',
      );
      expect(
        resolved.indicator.inlineStyles!.properties['height'],
        '${CoreCheckboxStyle.defaultMarkThickness / kRemDivisor}rem',
        reason: 'the dash height is the mark stroke, not the length',
      );
      expect(
        resolved.indicator.inlineStyles!.properties['border-radius'],
        CoreCheckboxStyle.defaultIndeterminateBorderRadius.toValue(),
      );
    });

    testComponents('the label is body copy (bodySmall role)', (tester) async {
      final resolved = resolveCheckbox(
        _themedContext(tester),
        size: CoreComponentSize.md,
        checked: false,
        enabled: true,
      );
      expect(
        resolved.root.className,
        contains('text-${CoreTextStyles.bodySmall.name}'),
      );
    });
  });

  group('resolveCheckboxRules — halo and ring ride scoped rules', () {
    testComponents('enabled: halo on hover / active, ring on focus-visible', (
      tester,
    ) async {
      final rules = resolveCheckboxRules(_themedContext(tester), enabled: true);

      expect(rules.scopeClass, isNotEmpty);
      final scope = '.${rules.scopeClass}';
      expect(rules.css, contains('$scope .$kCheckboxBoxMarker::before'));
      // The halo is absolutely positioned, so its inset is measured from the
      // box's padding box: the box's stroke rides on top of the spread so the
      // halo reaches `spread` beyond the box's outer edge, where the Flutter
      // twin's halo reaches.
      expect(
        rules.css,
        contains(
          'inset:calc(-'
          '${CoreCheckboxStyle.defaultStateLayerSpread / kRemDivisor}rem - '
          '${strokeWidthCss(CoreCheckboxStyle.defaultBoxBorderWidth)})',
        ),
        reason: 'the halo reaches spread beyond the box, stroke included',
      );
      expect(
        rules.css,
        contains('var(--coui-stroke-width-1)'),
        reason: 'the stroke is the active-boundary variable, not a literal',
      );
      expect(
        rules.css,
        contains(
          'border-radius:'
          '${CoreCheckboxStyle.defaultStateLayerBorderRadius.toValue()}',
        ),
        reason: "the halo has its own corner (radius8), not the box's",
      );
      const ink = CoreCheckboxStyle.defaultStateLayerColor;
      const layer = CoreCheckboxStyle.defaultStateLayer;
      final hoverSelector = '$scope:hover .$kCheckboxBoxMarker::before';
      final hoverColor = ink.scaleAlpha(layer.hover).toValue();
      expect(
        rules.css,
        contains('$hoverSelector{background-color:$hoverColor;}'),
      );
      final pressedSelector = '$scope:active .$kCheckboxBoxMarker::before';
      final pressedColor = ink.scaleAlpha(layer.pressed).toValue();
      expect(
        rules.css,
        contains('$pressedSelector{background-color:$pressedColor;}'),
      );
      expect(
        rules.css,
        contains(
          '$scope:focus-visible .$kCheckboxBoxMarker'
          '{outline-color:rgb(var(--coui-focus-ring));',
        ),
        reason: 'the ring lands on the box, not on the focusable root',
      );
      expect(
        rules.css,
        contains(':where($scope .$kCheckboxBoxMarker){outline-style:solid;}'),
        reason:
            'the outline is on at rest (so blur fades it) at zero '
            "specificity, so forced colours' root rule still clears it off "
            'the unfocused box',
      );
      expect(
        rules.css,
        isNot(contains('box-shadow')),
        reason:
            'the default gap band is transparent — the outline offset '
            'is a real gap, so nothing paints the box-shadow and the '
            'resting cast stays',
      );
    });

    testComponents('a stated box stroke moves the halo inset and the scope', (
      tester,
    ) async {
      // The halo's inset is measured from the padding box, so the box's own
      // stroke is read — an override of it must reach the halo, and two
      // boxes that differ only in stroke must not share one rule.
      final context = _themedContext(tester);
      final base = resolveCheckboxRules(context, enabled: true);
      final thick = resolveCheckboxRules(
        context,
        enabled: true,
        checkboxStyle: const CoreCheckboxStyle(
          boxBorderWidth: CoreStrokeWidth.stroke4,
        ),
      );
      expect(
        thick.css,
        contains(
          '-${CoreCheckboxStyle.defaultStateLayerSpread / kRemDivisor}rem - '
          'var(--coui-stroke-width-4)',
        ),
      );
      expect(thick.scopeClass, isNot(base.scopeClass));
    });

    testComponents('disabled: nothing washes and nothing rings', (
      tester,
    ) async {
      final rules = resolveCheckboxRules(
        _themedContext(tester),
        enabled: false,
      );
      expect(rules.scopeClass, isEmpty);
      expect(rules.css, isEmpty);
    });

    testComponents(
      'a stated gap band paints as a box-shadow over the resting cast',
      (tester) async {
        final rules = resolveCheckboxRules(
          _themedContext(tester),
          enabled: true,
          checkboxStyle: const CoreCheckboxStyle(
            focusOutlineStyle: CoreFocusOutlineStyle(
              offsetColor: CoreFocusRing.opaqueOffsetColor,
            ),
          ),
        );
        final scope = '.${rules.scopeClass}';
        expect(
          rules.css,
          contains(
            'box-shadow:0 0 0 calc(4.0px - var(--coui-stroke-width-2)) '
            'rgb(var(--coui-surface)), '
            'var(--coui-control-shadow);}',
          ),
        );
        expect(
          rules.css,
          contains('$scope:focus-visible .$kCheckboxBoxMarker{'),
        );
      },
    );
  });
}
