import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const ValueKey<String> _label = ValueKey('label');
const ValueKey<String> _leading = ValueKey('leading');
const ValueKey<String> _row = ValueKey('row');

const double _width = 350;

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  TextDirection textDirection = .ltr,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await pumpTestApp(
    tester,
    SizedBox(width: _width, child: child),
    theme: ThemeData.fromCore(CoreThemePresets.light),
    textDirection: textDirection,
  );
}

OptionItem _item({
  CoreOptionItemSelection selection = .single,
  bool selected = false,
  bool? enabled,
  VoidCallback? onPressed,
  Widget? description,
  Widget? leading,
  CoreOptionItemStyle? style,
}) => OptionItem(
  key: _row,
  label: const Text('Newest', key: _label),
  description: description,
  leading: leading,
  selection: selection,
  selected: selected,
  enabled: enabled,
  onPressed: onPressed ?? () {},
  optionItemStyle: style,
);

/// The card: the nearest bordered box around the row's stack — the one the
/// row draws its border and fill on.
final Finder _card = find
    .ancestor(
      of: find.descendant(of: find.byKey(_row), matching: find.byType(Stacks)),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).border != null,
      ),
    )
    .first;

/// The pressed face: the rounded box without a border inside the card.
final Finder _face = find.descendant(
  of: find.byKey(_row),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is DecoratedBox &&
        widget.decoration is BoxDecoration &&
        (widget.decoration as BoxDecoration).border == null &&
        (widget.decoration as BoxDecoration).borderRadius != null,
  ),
);

BoxDecoration _cardDecoration(WidgetTester tester) =>
    tester.widget<DecoratedBox>(_card).decoration as BoxDecoration;

TextStyle _labelStyle(WidgetTester tester) =>
    DefaultTextStyle.of(tester.element(find.byKey(_label))).style;

Color _ink(WidgetTester tester, CoreColor token) => Theme.of(
  tester.element(find.byKey(_row)),
).colorScheme.resolve(token).toValue();

void main() {
  group('OptionItem geometry', () {
    testWidgets('a one-line card is 52 tall, its label 16 in and centred', (
      tester,
    ) async {
      await _pump(tester, _item());
      final row = tester.getRect(find.byKey(_row));
      final label = tester.getRect(find.byKey(_label));
      expect(row.width, _width);
      // The floor wins over 12 + the label's line + 12.
      expect(label.height + 2 * CoreSpace.space12, lessThan(52));
      expect(row.height, CoreSpace.space52);
      // 16 from the card's outer edge — the border takes no layout.
      expect(label.left - row.left, CoreSpace.space16);
      expect(label.center.dy, closeTo(row.center.dy, 0.01));
    });

    testWidgets('the label keeps its role line box (bodyLarge)', (
      tester,
    ) async {
      await _pump(tester, _item());
      final theme = Theme.of(tester.element(find.byKey(_row)));
      final role = const CoreTextStyle.token(
        CoreTextStyles.bodyLarge,
      ).toValue(theme: theme);
      expect(_labelStyle(tester).fontSize, role.fontSize);
      expect(_labelStyle(tester).height, role.height);
    });

    testWidgets('a chosen card does not move its content', (tester) async {
      await _pump(tester, _item());
      final rest = tester.getRect(find.byKey(_label)).topLeft;
      await _pump(tester, _item(selected: true));
      expect(tester.getRect(find.byKey(_label)).topLeft, rest);
    });

    testWidgets('the leading glyph and the label are 12 apart', (
      tester,
    ) async {
      await _pump(
        tester,
        _item(leading: const SizedBox.square(key: _leading, dimension: 20)),
      );
      final leading = tester.getRect(find.byKey(_leading));
      final label = tester.getRect(find.byKey(_label));
      expect(label.left - leading.right, CoreSpace.space12);
    });

    testWidgets('a description grows the card and sits 4 under the label', (
      tester,
    ) async {
      await _pump(
        tester,
        _item(description: const Text('Latest', key: Key('d'))),
      );
      final label = tester.getRect(find.byKey(_label));
      final description = tester.getRect(find.byKey(const Key('d')));
      expect(description.top - label.bottom, CoreSpace.space4);
      final row = tester.getRect(find.byKey(_row));
      expect(label.top - row.top, CoreSpace.space12);
      expect(
        row.height,
        label.height +
            CoreSpace.space4 +
            description.height +
            2 * CoreSpace.space12,
      );
    });
  });

  group('OptionItem selection marks', () {
    testWidgets('single: a check only on the chosen row, 20 at the end', (
      tester,
    ) async {
      await _pump(tester, _item());
      expect(find.byType(Icon), findsNothing);
      await _pump(tester, _item(selected: true));
      final check = tester.getRect(find.byType(Icon));
      final row = tester.getRect(find.byKey(_row));
      expect(check.size, const Size.square(20));
      expect(row.right - check.right, CoreSpace.space16);
    });

    testWidgets(
      'multiple: a large checkbox on every row, checked by selected',
      (
        tester,
      ) async {
        await _pump(tester, _item(selection: .multiple));
        expect(tester.widget<Checkbox>(find.byType(Checkbox)).checked, isFalse);
        expect(
          tester.widget<Checkbox>(find.byType(Checkbox)).size,
          CoreComponentSize.lg,
        );
        await _pump(tester, _item(selection: .multiple, selected: true));
        expect(tester.widget<Checkbox>(find.byType(Checkbox)).checked, isTrue);
      },
    );

    testWidgets('the checkbox takes no tap of its own', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        _item(selection: .multiple, onPressed: () => taps++),
      );
      await tester.tap(find.byType(Checkbox), warnIfMissed: false);
      expect(taps, 1);
    });
  });

  group('OptionItem card', () {
    testWidgets('at rest: outline-variant 1, no fill, corner 12', (
      tester,
    ) async {
      await _pump(tester, _item());
      final d = _cardDecoration(tester);
      final border = d.border! as Border;
      expect(
        border.top.color,
        _ink(tester, const CoreColor.token(CoreColors.outlineVariant)),
      );
      expect(border.top.width, CoreStrokeWidth.stroke1);
      expect(d.color, isNull);
      expect(d.borderRadius, BorderRadius.circular(CoreRadius.radius12));
    });

    testWidgets('chosen: primary 1.5 border on surface-container-low', (
      tester,
    ) async {
      for (final selection in CoreOptionItemSelection.values) {
        await _pump(tester, _item(selection: selection, selected: true));
        final d = _cardDecoration(tester);
        final border = d.border! as Border;
        expect(
          border.top.color,
          _ink(tester, const CoreColor.token(CoreColors.primary)),
        );
        expect(border.top.width, CoreStrokeWidth.stroke1_5);
        expect(
          d.color,
          _ink(tester, const CoreColor.token(CoreColors.surfaceContainerLow)),
        );
      }
    });

    testWidgets('disabled + chosen: surface-container under the rest border', (
      tester,
    ) async {
      await _pump(tester, _item(selected: true, enabled: false));
      final d = _cardDecoration(tester);
      final border = d.border! as Border;
      expect(
        border.top.color,
        _ink(tester, const CoreColor.token(CoreColors.outlineVariant)),
      );
      expect(border.top.width, CoreStrokeWidth.stroke1);
      expect(
        d.color,
        _ink(tester, const CoreColor.token(CoreColors.surfaceContainer)),
      );
    });

    testWidgets('disabled, not chosen: the rest border and no fill', (
      tester,
    ) async {
      await _pump(tester, _item(enabled: false));
      final d = _cardDecoration(tester);
      final border = d.border! as Border;
      expect(
        border.top.color,
        _ink(tester, const CoreColor.token(CoreColors.outlineVariant)),
      );
      expect(border.top.width, CoreStrokeWidth.stroke1);
      expect(d.color, isNull);
    });
  });

  group('OptionItem ink', () {
    testWidgets('a rest label is on-surface and medium', (tester) async {
      await _pump(tester, _item());
      expect(
        _labelStyle(tester).color,
        _ink(tester, const CoreColor.token(CoreColors.onSurface)),
      );
      expect(_labelStyle(tester).fontWeight, FontWeight.w500);
    });

    testWidgets('a chosen single label is accent and semibold', (
      tester,
    ) async {
      await _pump(tester, _item(selected: true));
      expect(
        _labelStyle(tester).color,
        _ink(tester, const CoreColor.token(CoreColors.primary)),
      );
      expect(_labelStyle(tester).fontWeight, FontWeight.w600);
    });

    testWidgets('a chosen multiple label keeps the ink and goes semibold', (
      tester,
    ) async {
      await _pump(tester, _item(selection: .multiple, selected: true));
      expect(
        _labelStyle(tester).color,
        _ink(tester, const CoreColor.token(CoreColors.onSurface)),
      );
      expect(_labelStyle(tester).fontWeight, FontWeight.w600);
    });

    testWidgets('a disabled row reads disabled-content, chosen or not', (
      tester,
    ) async {
      for (final selected in [false, true]) {
        await _pump(tester, _item(selected: selected, enabled: false));
        expect(
          _labelStyle(tester).color,
          _ink(tester, const CoreColor.token(CoreColors.disabledContent)),
        );
      }
    });

    testWidgets('a disabled chosen row keeps the chosen weight', (
      tester,
    ) async {
      for (final selection in CoreOptionItemSelection.values) {
        await _pump(
          tester,
          _item(selection: selection, selected: true, enabled: false),
        );
        expect(_labelStyle(tester).fontWeight, FontWeight.w600);
        expect(
          _labelStyle(tester).color,
          _ink(tester, const CoreColor.token(CoreColors.disabledContent)),
        );
        await _pump(tester, _item(selection: selection, enabled: false));
        expect(_labelStyle(tester).fontWeight, FontWeight.w500);
      }
    });

    testWidgets('a disabled multiple row disables its checkbox', (
      tester,
    ) async {
      await _pump(tester, _item(selection: .multiple, enabled: false));
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).enabled, isFalse);
    });
  });

  group('OptionItem press', () {
    testWidgets('onPressed fires on a tap, and not when disabled', (
      tester,
    ) async {
      var taps = 0;
      await _pump(tester, _item(onPressed: () => taps++));
      await tester.tap(find.byKey(_row));
      expect(taps, 1);
      await _pump(tester, _item(onPressed: () => taps++, enabled: false));
      await tester.tap(find.byKey(_row));
      expect(taps, 1);
    });

    testWidgets('pressed paints a surface-container-high face inside the '
        'border', (tester) async {
      for (final selected in [false, true]) {
        await _pump(tester, _item(selected: selected));
        final row = tester.getRect(find.byKey(_row));
        expect(_face, findsNothing);
        final border = selected
            ? CoreStrokeWidth.stroke1_5
            : CoreStrokeWidth.stroke1;

        final gesture = await tester.startGesture(row.center);
        await tester.pump();
        expect(_face, findsOneWidget);
        final rect = tester.getRect(_face);
        // No reach past the sides, no gap at the top or bottom: the face
        // fills the card to the inside of its border.
        expect(rect.left, row.left + border);
        expect(rect.right, row.right - border);
        expect(rect.top, row.top + border);
        expect(rect.bottom, row.bottom - border);
        final decoration =
            tester.widget<DecoratedBox>(_face).decoration as BoxDecoration;
        expect(
          decoration.color,
          _ink(tester, const CoreColor.token(CoreColors.surfaceContainerHigh)),
        );
        // Concentric with the border's inner curve: 12 less the border in
        // effect — 11 at rest, 10.5 on a chosen row.
        expect(
          decoration.borderRadius,
          BorderRadius.circular(CoreRadius.radius12 - border),
        );
        // Over the fill, under the content.
        expect(
          find.descendant(of: _card, matching: _face),
          findsOneWidget,
        );
        final stack = tester.widget<Stacks>(
          find.descendant(of: _card, matching: find.byType(Stacks)).first,
        );
        expect(stack.children.first, isA<Position>());
        expect(stack.children.last, isA<Padding>());

        await gesture.up();
        await tester.pump();
        expect(_face, findsNothing);
      }
    });

    testWidgets('a disabled row paints no pressed face', (tester) async {
      await _pump(tester, _item(enabled: false));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(_row)),
      );
      await tester.pump();
      expect(
        _face,
        findsNothing,
      );
      await gesture.up();
    });
  });

  group('OptionItem style slot', () {
    testWidgets('padding, spacing and the floor come from the style', (
      tester,
    ) async {
      await _pump(
        tester,
        _item(
          leading: const SizedBox.square(key: _leading, dimension: 20),
          style: const CoreOptionItemStyle(
            padding: CoreEdgeInsets.symmetric(vertical: CoreSpace.space8),
            spacing: CoreSpace.space4,
            minHeight: CoreSpace.space0,
          ),
        ),
      );
      final row = tester.getRect(find.byKey(_row));
      final label = tester.getRect(find.byKey(_label));
      final leading = tester.getRect(find.byKey(_leading));
      expect(row.height, label.height + 16);
      expect(label.left - leading.right, CoreSpace.space4);
    });

    testWidgets('the card chrome comes from the style', (tester) async {
      await _pump(
        tester,
        _item(
          selected: true,
          style: const CoreOptionItemStyle(
            borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
            selectedBorderColor: CoreColor.token(CoreColors.error),
            selectedBorderWidth: CoreStrokeWidth.stroke2,
            selectedBackgroundColor: CoreColor.token(CoreColors.surface),
          ),
        ),
      );
      final d = _cardDecoration(tester);
      final border = d.border! as Border;
      expect(
        border.top.color,
        _ink(tester, const CoreColor.token(CoreColors.error)),
      );
      expect(border.top.width, CoreStrokeWidth.stroke2);
      expect(d.color, _ink(tester, const CoreColor.token(CoreColors.surface)));
      expect(d.borderRadius, BorderRadius.circular(CoreRadius.radius4));
    });
  });

  group('OptionList', () {
    testWidgets('rows stand 8 apart, each as wide as the list', (
      tester,
    ) async {
      await _pump(
        tester,
        const OptionList(
          children: [
            OptionItem(key: Key('a'), label: Text('A')),
            OptionItem(key: Key('b'), label: Text('B')),
          ],
        ),
      );
      final a = tester.getRect(find.byKey(const Key('a')));
      final b = tester.getRect(find.byKey(const Key('b')));
      expect(a.width, _width);
      expect(b.width, _width);
      expect(b.top - a.bottom, CoreSpace.space8);
    });

    testWidgets('the style states the space between rows', (tester) async {
      await _pump(
        tester,
        const OptionList(
          optionListStyle: CoreOptionListStyle(spacing: CoreSpace.space4),
          children: [
            OptionItem(key: Key('a'), label: Text('A')),
            OptionItem(key: Key('b'), label: Text('B')),
          ],
        ),
      );
      final a = tester.getRect(find.byKey(const Key('a')));
      final b = tester.getRect(find.byKey(const Key('b')));
      expect(b.top - a.bottom, CoreSpace.space4);
    });
  });
}
