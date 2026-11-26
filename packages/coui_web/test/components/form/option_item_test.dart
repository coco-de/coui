import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The DOM children of [element] — the nearest element nodes under it, past
/// the components (`Text`, `Clickable`) that only wrap one.
List<Element> _domChildren(Element element) {
  final out = <Element>[];
  void visit(Element child) {
    if (child.component is DomComponent) {
      out.add(child);
    } else {
      child.visitChildren(visit);
    }
  }

  element.visitChildren(visit);
  return out;
}

DomComponent _dom(Element element) => element.component as DomComponent;

/// The row element of the first [OptionItem] on the page.
Element _row() => _domChildren(find.byType(OptionItem).evaluate().first).single;

/// Every DOM element under [element], depth first.
List<Element> _all(Element element) {
  final out = <Element>[];
  void visit(Element child) {
    if (child.component is DomComponent) out.add(child);
    child.visitChildren(visit);
  }

  element.visitChildren(visit);
  return out;
}

List<String> _classes(Element element) => (_dom(element).classes ?? '')
    .split(' ')
    .where((c) => c.isNotEmpty)
    .toList();

Element? _byClass(Element root, String cls) {
  for (final element in _all(root)) {
    if (_classes(element).contains(cls)) return element;
  }
  return null;
}

String _scopeClass(Element row) =>
    _classes(row).firstWhere((c) => c.startsWith('co-option-item-'));

/// The `<style>` text of the row, or `null` when it draws none.
String? _rule(Element row) {
  for (final element in _all(row)) {
    if (_dom(element).tag == 'style') {
      final out = StringBuffer();
      void visit(Element child) {
        if (child.component case RawText(:final text)) out.write(text);
        child.visitChildren(visit);
      }

      element.visitChildren(visit);
      return out.toString();
    }
  }
  return null;
}

void main() {
  group('Web OptionItem', () {
    OptionItem item({
      CoreOptionItemSelection selection = .single,
      bool selected = false,
      bool? enabled,
      Component? description,
      Component? leading,
      CoreOptionItemStyle? style,
    }) => OptionItem(
      label: const Text('Newest'),
      description: description,
      leading: leading,
      selection: selection,
      selected: selected,
      enabled: enabled,
      onPressed: () {},
      optionItemStyle: style,
    );

    testComponents('the row is a card: 52 tall at least, 12 / 16 from its '
        'outer edge', (tester) async {
      pumpWithTheme(tester, item());
      final row = _row();
      expect(
        _classes(row),
        containsAll([
          'relative',
          'flex',
          'w-full',
          'items-center',
          'text-start',
          'select-none',
        ]),
      );
      final styles = _dom(row).styles!.properties;
      expect(styles['min-height'], pinnedLengthCss(CoreSpace.space52));
      // The border sits inside the padding the style states.
      final border = strokeWidthCss(CoreStrokeWidth.stroke1);
      String inside(double side) => 'calc(${spaceCss(side)} - $border)';
      expect(
        styles['padding'],
        '${inside(CoreSpace.space12)} ${inside(CoreSpace.space16)} '
        '${inside(CoreSpace.space12)} ${inside(CoreSpace.space16)}',
      );
      expect(styles['gap'], spaceCss(CoreSpace.space12));
    });

    testComponents('at rest: outline-variant 1, no fill, corner 12', (
      tester,
    ) async {
      pumpWithTheme(tester, item());
      final row = _row();
      final styles = _dom(row).styles!.properties;
      expect(styles['border-style'], 'solid');
      expect(styles['border-width'], strokeWidthCss(CoreStrokeWidth.stroke1));
      expect(_classes(row), contains('border-outline-variant'));
      expect(_classes(row).where((c) => c.startsWith('bg-')), isEmpty);
      expect(_classes(row), contains('rounded-tl-radius12'));
    });

    testComponents('chosen: primary 1.5 on surface-container-low, the '
        'content where it was', (tester) async {
      for (final selection in CoreOptionItemSelection.values) {
        pumpWithTheme(tester, item(selection: selection, selected: true));
        final row = _row();
        final styles = _dom(row).styles!.properties;
        final border = strokeWidthCss(CoreStrokeWidth.stroke1_5);
        expect(styles['border-width'], border);
        expect(_classes(row), contains('border-primary'));
        expect(_classes(row), contains('bg-surface-container-low'));
        // The padding gives the thicker border back, so the content stays.
        expect(
          styles['padding'],
          'calc(${spaceCss(CoreSpace.space12)} - $border) '
          'calc(${spaceCss(CoreSpace.space16)} - $border) '
          'calc(${spaceCss(CoreSpace.space12)} - $border) '
          'calc(${spaceCss(CoreSpace.space16)} - $border)',
        );
      }
    });

    testComponents('disabled + chosen: surface-container under the rest '
        'border', (tester) async {
      pumpWithTheme(tester, item(selected: true, enabled: false));
      final row = _row();
      final styles = _dom(row).styles!.properties;
      expect(styles['border-width'], strokeWidthCss(CoreStrokeWidth.stroke1));
      expect(_classes(row), contains('border-outline-variant'));
      expect(_classes(row), isNot(contains('border-primary')));
      expect(_classes(row), contains('bg-surface-container'));
    });

    testComponents('disabled, not chosen: the rest border and no fill', (
      tester,
    ) async {
      pumpWithTheme(tester, item(enabled: false));
      final row = _row();
      expect(_classes(row), contains('border-outline-variant'));
      expect(_classes(row).where((c) => c.startsWith('bg-')), isEmpty);
    });

    testComponents('a description top-aligns the row', (tester) async {
      pumpWithTheme(tester, item(description: const Text('Latest')));
      expect(_classes(_row()), contains('items-start'));
      expect(_classes(_row()), isNot(contains('items-center')));
    });

    testComponents('the press feedback is the face: no scale, no dimming', (
      tester,
    ) async {
      pumpWithTheme(tester, item(enabled: false));
      final styles = _dom(_row()).styles!.properties;
      expect(styles.keys, isNot(contains('transform')));
      expect(styles['opacity'], anyOf(isNull, '1', '1.0'));
    });

    testComponents('the face fills the inside of the border', (
      tester,
    ) async {
      pumpWithTheme(tester, item());
      final wash = _byClass(_row(), 'co-option-item-wash')!;
      final styles = _dom(wash).styles!.properties;
      // Absolute against the padding box: no reach past the sides, no gap
      // at the top or bottom.
      expect(styles['inset-inline'], 'calc(-1 * ${spaceCss(0)})');
      expect(styles['inset-block'], spaceCss(0));
      expect(_classes(wash), containsAll(['absolute', 'pointer-events-none']));
      // Over the fill, under the content: the first painted child, held
      // under the text by a negative z-index inside the row's own stacking
      // context.
      expect(_classes(_row()), contains('isolate'));
      final children = _domChildren(
        _row(),
      ).where((e) => _dom(e).tag != 'style').toList();
      expect(children.first, wash);
    });

    testComponents('the face corner is concentric with the border: 12 less '
        'the border in effect', (tester) async {
      String faceRadius() => _dom(
        _byClass(_row(), 'co-option-item-wash')!,
      ).styles!.properties['border-radius']!;
      String inside(double border) {
        final corner =
            'max(0px, calc(${radiusCss(CoreRadius.radius12)} - '
            '${strokeWidthCss(border)}))';
        return '$corner $corner $corner $corner';
      }

      pumpWithTheme(tester, item());
      expect(faceRadius(), inside(CoreStrokeWidth.stroke1));
      pumpWithTheme(tester, item(selected: true));
      expect(faceRadius(), inside(CoreStrokeWidth.stroke1_5));
      // A chosen disabled row draws the resting border, so the resting corner.
      pumpWithTheme(tester, item(selected: true, enabled: false));
      expect(faceRadius(), inside(CoreStrokeWidth.stroke1));
    });

    testComponents('the pressed face is a rule on :active, keyed on the row', (
      tester,
    ) async {
      pumpWithTheme(tester, item());
      final row = _row();
      final rule = _rule(row)!;
      // Opaque surface-container-high, over the fill.
      final colour = const CoreColor.token(
        CoreColors.surfaceContainerHigh,
      ).toValue();
      final scope = _scopeClass(row);
      final declarations = 'background-color:$colour;z-index:-1;';
      expect(
        rule,
        '.$scope:active > .co-option-item-wash{$declarations}',
      );
    });

    testComponents('a disabled row answers no press', (tester) async {
      pumpWithTheme(tester, item(enabled: false));
      expect(_rule(_row()), isNull);
      expect(_dom(_row()).attributes?['aria-disabled'], 'true');
    });

    testComponents('single: a check, only on the chosen row', (tester) async {
      pumpWithTheme(tester, item());
      expect(
        _all(_row()).where((e) => _dom(e).tag == 'svg'),
        isEmpty,
      );
      pumpWithTheme(tester, item(selected: true));
      final svg = _all(_row()).singleWhere((e) => _dom(e).tag == 'svg');
      expect(_dom(svg).attributes?['data-icon'], 'lucide:check');
      expect(_classes(svg), contains('text-primary'));
      expect(_dom(_row()).attributes?['aria-current'], 'true');
    });

    testComponents('multiple: an inert checkbox on every row', (tester) async {
      pumpWithTheme(tester, item(selection: .multiple));
      var box = _all(_row()).firstWhere(
        (e) => _dom(e).attributes?['role'] == 'checkbox',
      );
      expect(_dom(box).attributes?['aria-checked'], 'false');
      final seat = _all(_row()).firstWhere(
        (e) => _dom(e).attributes?.containsKey('inert') ?? false,
      );
      expect(_classes(seat), contains('pointer-events-none'));

      pumpWithTheme(tester, item(selection: .multiple, selected: true));
      box = _all(_row()).firstWhere(
        (e) => _dom(e).attributes?['role'] == 'checkbox',
      );
      expect(_dom(box).attributes?['aria-checked'], 'true');
    });

    testComponents('the label: ink and weight follow the selection', (
      tester,
    ) async {
      Element label() => _all(_row()).firstWhere(
        (e) => _classes(e).contains('text-body-large'),
      );

      pumpWithTheme(tester, item());
      expect(_classes(label()), contains('text-on-surface'));
      expect(_dom(label()).styles!.properties['font-weight'], '500');
      // The role's line box is kept: nothing pins a line height.
      expect(_dom(label()).styles!.properties['line-height'], isNull);

      pumpWithTheme(tester, item(selected: true));
      expect(_classes(label()), contains('text-primary'));
      expect(_dom(label()).styles!.properties['font-weight'], '600');

      pumpWithTheme(tester, item(selection: .multiple, selected: true));
      expect(_classes(label()), contains('text-on-surface'));
      expect(_dom(label()).styles!.properties['font-weight'], '600');

      // A chosen disabled row keeps the chosen weight in the disabled ink.
      pumpWithTheme(tester, item(selected: true, enabled: false));
      expect(_classes(label()), contains('text-disabled-content'));
      expect(_classes(label()), isNot(contains('text-primary')));
      expect(_dom(label()).styles!.properties['font-weight'], '600');

      pumpWithTheme(tester, item(enabled: false));
      expect(_dom(label()).styles!.properties['font-weight'], '500');
    });

    testComponents('the leading glyph sits in the label ink, disabled dims', (
      tester,
    ) async {
      pumpWithTheme(tester, item(leading: const Text('i')));
      final seat = _all(_row()).firstWhere(
        (e) => ['flex', 'shrink-0', 'items-center'].every(_classes(e).contains),
      );
      expect(_classes(seat), contains('text-on-surface'));
      pumpWithTheme(tester, item(leading: const Text('i'), enabled: false));
      final off = _all(_row()).firstWhere(
        (e) => ['flex', 'shrink-0', 'items-center'].every(_classes(e).contains),
      );
      expect(_classes(off), contains('text-disabled-content'));
    });

    testComponents('the style slot states the padding and the gap', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        item(
          style: const CoreOptionItemStyle(
            padding: CoreEdgeInsets.symmetric(vertical: CoreSpace.space8),
            spacing: CoreSpace.space4,
          ),
        ),
      );
      final styles = _dom(_row()).styles!.properties;
      expect(styles['gap'], spaceCss(CoreSpace.space4));
      expect(styles['padding'], contains(spaceCss(CoreSpace.space8)));
    });

    testComponents('a description sits 4 under the label', (tester) async {
      pumpWithTheme(tester, item(description: const Text('Latest')));
      final gap = find.byType(Gap).evaluate().single.component as Gap;
      expect(gap.gapStyle?.size, CoreSpace.space4);
    });

    testComponents('the style slot states the card chrome', (tester) async {
      pumpWithTheme(
        tester,
        item(
          selected: true,
          style: const CoreOptionItemStyle(
            minHeight: CoreSpace.space40,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
            selectedBorderColor: CoreColor.token(CoreColors.error),
            selectedBorderWidth: CoreStrokeWidth.stroke2,
            selectedBackgroundColor: CoreColor.token(CoreColors.surface),
          ),
        ),
      );
      final row = _row();
      final styles = _dom(row).styles!.properties;
      expect(styles['min-height'], pinnedLengthCss(CoreSpace.space40));
      expect(styles['border-width'], strokeWidthCss(CoreStrokeWidth.stroke2));
      expect(_classes(row), containsAll(['border-error', 'bg-surface']));
      // An override rides inline; the default rides the class.
      expect(
        styles['border-radius'],
        const CoreBorderRadius.all(CoreRadius.radius4).toValue(),
      );
      expect(_classes(row), isNot(contains('rounded-tl-radius12')));
    });
  });

  group('Web OptionList', () {
    testComponents('a group: a full-width column, the rows 8 apart', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        OptionList(
          children: [
            item('A'),
            item('B'),
          ],
        ),
      );
      final list = _domChildren(
        find.byType(OptionList).evaluate().single,
      ).single;
      expect(_dom(list).attributes?['role'], 'group');
      expect(_dom(list).classes, 'flex w-full flex-col');
      expect(_dom(list).styles!.properties['gap'], spaceCss(CoreSpace.space8));
      expect(find.byType(OptionItem).evaluate(), hasLength(2));
    });

    testComponents('the style states the space between rows', (tester) async {
      pumpWithTheme(
        tester,
        OptionList(
          optionListStyle: const CoreOptionListStyle(spacing: CoreSpace.space4),
          children: [item('A')],
        ),
      );
      final list = _domChildren(
        find.byType(OptionList).evaluate().single,
      ).single;
      expect(_dom(list).styles!.properties['gap'], spaceCss(CoreSpace.space4));
    });
  });
}

OptionItem item(String label) =>
    OptionItem(label: Text(label), onPressed: () {});
