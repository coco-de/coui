import 'package:coui_web/coui_web.dart';
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

List<String> _classes(WebElementChrome chrome) => chrome.className.split(' ');

String? _inline(WebElementChrome chrome, String property) =>
    chrome.inlineStyles?.properties[property];

/// Every text the rendered stat draws, in tree (reading) order.
List<String?> _texts() => find
    .byType(Text)
    .evaluate()
    .map((e) => e.component as Text)
    .map((t) => t.data)
    .toList();

/// The DOM elements above the [Text] that draws [data], nearest first: the
/// element that carries that line's chrome, then the rows that contain it.
///
/// This reads what `stat.dart` actually put on each element, so it fails
/// when a slot lands on the wrong element — which `resolveStat` alone
/// cannot see.
List<DomComponent> _domAbove(String data) {
  final text = find
      .byComponentPredicate((c) => c is Text && c.data == data)
      .evaluate()
      .single;
  final above = <DomComponent>[];
  text.visitAncestorElements((element) {
    final component = element.component;
    if (component is DomComponent) above.add(component);
    return true;
  });
  return above;
}

Set<String> _ownClasses(DomComponent element) =>
    (element.classes ?? '').split(' ').where((c) => c.isNotEmpty).toSet();

void main() {
  group('Stat variant', () {
    test('outlined is the default', () {
      expect(
        const Stat(label: 'Users', value: '128').variant,
        CoreStatVariant.outlined,
      );
    });

    testComponents('filled is a surfaceContainerLow face with no line', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveStat(context, variant: .filled);

      expect(
        resolved.containerStyle.backgroundColor?.token,
        CoreColors.surfaceContainerLow,
      );
      expect(resolved.containerStyle.borderWidth, 0);
      expect(resolved.containerStyle.borderColor, CoreColor.transparent);
    });

    testComponents('outlined is the page face with a 1px outline-variant', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveStat(context, variant: .outlined);

      expect(
        resolved.containerStyle.backgroundColor?.token,
        CoreColors.surface,
      );
      expect(resolved.containerStyle.borderWidth, CoreStrokeWidth.stroke1);
      expect(
        resolved.containerStyle.borderColor?.token,
        CoreColors.outlineVariant,
      );
    });
  });

  group('Stat value row, unit, description, empty value', () {
    testComponents('the value row aligns value and unit on the baseline', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveStat(context, variant: .filled);

      expect(
        _classes(resolved.valueRow),
        containsAll(['flex', 'items-baseline', 'gap-space4']),
      );
      // The figure may shrink and break (Flutter's `Flexible` twin); the
      // unit keeps its width.
      expect(
        _classes(resolved.valueText),
        containsAll(['min-w-0', 'break-words']),
      );
      expect(
        _classes(resolved.emptyValueText),
        containsAll(['min-w-0', 'break-words']),
      );
      expect(_classes(resolved.unitText), contains('shrink-0'));
    });

    testComponents('the unit is titleMedium at 500 in the second tier', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveStat(context, variant: .filled);

      expect(
        _classes(resolved.unitText),
        containsAll(['text-title-medium', 'text-on-surface-variant']),
      );
      // The role class carries the role's 600; the component's 500 rides
      // inline over it.
      expect(_inline(resolved.unitText, 'font-weight'), '500');
    });

    testComponents('the description is bodySmall in the third tier', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveStat(context, variant: .filled);

      expect(
        _classes(resolved.descriptionText),
        containsAll(['text-body-small', 'text-on-surface-subtle']),
      );
      expect(resolved.descriptionText.inlineStyles, isNull);
    });

    testComponents('the empty value keeps the value role, not its colour', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveStat(context, variant: .filled);

      expect(
        _classes(resolved.emptyValueText),
        containsAll(['text-headline-large', 'text-on-surface-variant']),
      );
      expect(_classes(resolved.valueText), contains('text-on-surface'));
      expect(
        _classes(resolved.emptyValueText),
        isNot(contains('text-on-surface')),
      );
    });

    testComponents('statStyle overrides reach the new slots', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveStat(
        context,
        variant: .filled,
        statStyle: const CoreStatStyle(
          valueUnitGapStyle: CoreGapStyle(size: CoreSpace.space12),
          unitColor: CoreColor.token(CoreColors.primary),
          emptyValueColor: CoreColor.token(CoreColors.error),
          descriptionColor: CoreColor.fromRGB(255, 0, 0),
          descriptionTextStyle: CoreTextStyle.token(CoreTextStyles.labelSmall),
        ),
      );

      expect(_classes(resolved.valueRow), contains('gap-space12'));
      expect(_classes(resolved.unitText), contains('text-primary'));
      expect(_classes(resolved.emptyValueText), contains('text-error'));
      // A raw colour has no class: it goes inline and the default class
      // drops.
      expect(
        _classes(resolved.descriptionText),
        isNot(contains('text-on-surface-subtle')),
      );
      expect(_inline(resolved.descriptionText, 'color'), isNotNull);
      expect(
        _classes(resolved.descriptionText),
        contains('text-label-small'),
      );
    });

    testComponents('rows render label → value + unit → change → '
        'description', (tester) async {
      pumpWithTheme(
        tester,
        const Stat(
          label: 'Revenue',
          value: '45,231',
          unit: 'KRW',
          change: '+20.1%',
          changeType: .positive,
          description: 'Last 30 days',
        ),
      );

      expect(_texts(), [
        'Revenue',
        '45,231',
        'KRW',
        '\u{2191}',
        '+20.1%',
        'Last 30 days',
      ]);
    });

    testComponents('a null value renders the dash and drops the unit', (
      tester,
    ) async {
      pumpWithTheme(tester, const Stat(label: 'Pending', unit: 'KRW'));

      expect(_texts(), ['Pending', CoreStatContract.defaultEmptyValue]);
    });

    testComponents('no description renders no description line', (
      tester,
    ) async {
      pumpWithTheme(tester, const Stat(label: 'Revenue', value: '45,231'));

      expect(_texts(), ['Revenue', '45,231']);
    });
  });

  // Where a wrapped figure puts its unit is layout, which jaspr_test does not
  // run; the Flutter twin pins that placement. What this group pins is the
  // markup that produces it in a browser: the unit and the figure are siblings
  // in one `items-baseline` row, and each slot's classes sit on the element
  // that draws that line.
  group('Stat rendered elements carry the slots they belong to', () {
    testComponents('the dash sits in its own element, in the empty colour', (
      tester,
    ) async {
      pumpWithTheme(tester, const Stat(label: 'Pending', unit: 'KRW'));

      final dash = _ownClasses(
        _domAbove(CoreStatContract.defaultEmptyValue).first,
      );
      expect(
        dash,
        containsAll(['text-headline-large', 'text-on-surface-variant']),
      );
      // The value's role, not the value's colour.
      expect(dash, isNot(contains('text-on-surface')));
    });

    testComponents('a figure keeps the value colour, not the empty one', (
      tester,
    ) async {
      pumpWithTheme(tester, const Stat(label: 'Revenue', value: '45,231'));

      final figure = _ownClasses(_domAbove('45,231').first);
      expect(
        figure,
        containsAll(['text-headline-large', 'text-on-surface']),
      );
      expect(figure, isNot(contains('text-on-surface-variant')));
    });

    testComponents("the unit shares the figure's baseline row", (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Stat(label: 'Revenue', value: '45,231', unit: 'KRW'),
      );

      final unit = _domAbove('KRW');
      final figure = _domAbove('45,231');
      expect(
        _ownClasses(unit.first),
        containsAll([
          'shrink-0',
          'text-title-medium',
          'text-on-surface-variant',
        ]),
      );
      expect(unit.first.styles?.properties['font-weight'], '500');
      // Unit and figure are siblings in one row: the flex row that aligns
      // them on the baseline and spaces them by the value-unit gap.
      expect(identical(unit[1], figure[1]), isTrue);
      expect(
        _ownClasses(unit[1]),
        containsAll(['flex', 'items-baseline', 'gap-space4']),
      );
      // …and the row is not the card's own content wrapper.
      expect(identical(unit[1], unit[2]), isFalse);
    });

    testComponents('the description is its own line below the change row', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Stat(
          label: 'Revenue',
          value: '45,231',
          unit: 'KRW',
          change: '+20.1%',
          changeType: .positive,
          description: 'Last 30 days',
        ),
      );

      final description = _domAbove('Last 30 days');
      expect(
        _ownClasses(description.first),
        containsAll(['text-body-small', 'text-on-surface-subtle']),
      );
      // A direct child of the content wrapper — the same one that holds the
      // value row — not nested in the value row or the change row.
      final unit = _domAbove('KRW');
      expect(identical(description[1], unit[2]), isTrue);
      expect(
        _ownClasses(description[1]),
        contains('space-y-space10'),
      );
      // The change text sits in a bare span; its row (the next element up)
      // keeps its own colour and is a different line from the description.
      final change = _domAbove('+20.1%');
      expect(identical(change[1], description.first), isFalse);
      expect(_ownClasses(change[1]), contains('text-on-success-container'));
      expect(
        _ownClasses(description.first),
        isNot(contains('text-on-success-container')),
      );
    });
  });

  group('Stat value role and chrome slots', () {
    testComponents(
      'displaySmall replaces headlineSmall on the value',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveStat(
          context,
          variant: CoreStatVariant.outlined,
          statStyle: const CoreStatStyle(
            valueTextStyle: CoreTextStyle.token(CoreTextStyles.displaySmall),
          ),
        );

        final classes = resolved.valueText.className.split(' ');
        expect(classes, contains('text-display-small'));
        expect(classes, isNot(contains('text-headline-small')));
      },
    );

    testComponents(
      'border width, radius, and fill are the style slots',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveStat(
          context,
          variant: CoreStatVariant.outlined,
          statStyle: const CoreStatStyle(
            borderWidth: CoreStrokeWidth.stroke0,
            borderRadius: CoreBorderRadius.zero,
            backgroundColor: CoreColor.transparent,
          ),
        );

        expect(
          resolved.containerStyle.borderWidth,
          CoreStrokeWidth.stroke0,
        );
        expect(
          resolved.containerStyle.borderRadius,
          CoreBorderRadius.zero,
        );
        expect(resolved.containerStyle.backgroundColor, CoreColor.transparent);
      },
    );
  });

  group('Stat size', () {
    testComponents('md is the default size', (tester) async {
      expect(
        const Stat(label: 'Users', value: '128').size,
        CoreComponentSize.md,
      );
    });

    testComponents('sm is 14 / 16 padded with a titleLarge figure', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveStat(context, variant: .outlined, size: .sm);

      expect(
        resolved.containerStyle.padding,
        const CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space16,
          vertical: CoreSpace.space14,
        ),
      );
      expect(_classes(resolved.valueText), contains('text-title-large'));
      // The role class carries the weight — no inline overlay.
      expect(_inline(resolved.valueText, 'font-weight'), isNull);
      expect(_classes(resolved.descriptionText), contains('text-body-xs'));
    });
  });
}
