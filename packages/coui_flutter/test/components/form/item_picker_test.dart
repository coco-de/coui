import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kPreviewWidth = 320.0;
const _kGridColumns = 3;
const _kBorderRadius = 8.0;
const _kBorderWidth = 2.0;
const _kMaxHeight = 200.0;
const _kNewMaxHeight = 300.0;

material.Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: Center(
      child: SizedBox(width: _kPreviewWidth, child: child),
    ),
  ),
);

/// The picker panel's painted border colour — the outer box the composed
/// `OutlinedContainer` draws around the title, search field and options.
Color _panelBorderColor(WidgetTester tester) {
  final box = tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(OutlinedContainer),
          matching: find.byType(DecoratedBox),
        ),
      )
      .first;
  final decoration = box.decoration as BoxDecoration;
  return (decoration.border! as Border).top.color;
}

/// The scheme-resolved colour of a Core token, the way the panel does.
Color _resolved(WidgetTester tester, CoreColor color) => Theme.of(
  tester.element(find.byType(ItemPicker)),
).colorScheme.resolve(color).toValue();

/// The CoUI `Icon` drawing [name].
Finder _iconNamed(IconName name) =>
    find.byWidgetPredicate((widget) => widget is Icon && widget.icon == name);

/// Parks a mouse pointer over the centre of [finder] and returns the
/// gesture so the test can move it away again.
Future<TestGesture> _hoverOver(WidgetTester tester, Finder finder) async {
  final gesture = await tester.createGesture(kind: .mouse);
  await gesture.addPointer(location: .zero);
  addTearDown(gesture.removePointer);
  await gesture.moveTo(tester.getCenter(finder));
  await tester.pumpAndSettle();
  return gesture;
}

void main() {
  group('ItemPicker', () {
    testWidgets('renders all items', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ItemPicker(items: ['Apple', 'Banana', 'Cherry']),
        ),
      );
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ItemPicker(items: ['A'], title: 'Letters'),
        ),
      );
      expect(find.text('Letters'), findsOneWidget);
    });

    testWidgets('shows empty text when no items', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ItemPicker(items: [], emptyText: 'Nothing here'),
        ),
      );
      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('selecting an item fires onChanged', (tester) async {
      String? selected;
      await tester.pumpWidget(
        _buildApp(
          ItemPicker(
            onChanged: (value) => selected = value,
            items: const ['Apple', 'Banana'],
          ),
        ),
      );
      await tester.tap(find.text('Banana'));
      await tester.pump();
      expect(selected, equals('Banana'));
    });

    testWidgets('grid layout renders with column count', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ItemPicker(
            items: ['A', 'B', 'C', 'D', 'E', 'F'],
            layout: .grid,
            gridColumns: _kGridColumns,
          ),
        ),
      );
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('implements CoreItemPickerContract', (tester) async {
      const picker = ItemPicker(items: ['A']);
      expect(picker, isA<CoreItemPickerContract<ValueChanged<String>?>>());
    });
  });

  group('CoreItemPickerStyle', () {
    test('merge overrides non-null fields', () {
      const base = CoreItemPickerStyle(
        borderRadius: CoreBorderRadius.all(_kBorderRadius),
      );
      const override = CoreItemPickerStyle(borderWidth: _kBorderWidth);
      final merged = base.merge(override);
      expect(
        merged.borderRadius,
        equals(const CoreBorderRadius.all(_kBorderRadius)),
      );
      expect(merged.borderWidth, equals(_kBorderWidth));
    });

    test('copyWith replaces fields', () {
      const style = CoreItemPickerStyle(maxHeight: _kMaxHeight);
      final copy = style.copyWith(maxHeight: _kNewMaxHeight);
      expect(copy.maxHeight, equals(_kNewMaxHeight));
    });
  });

  // The picker panel is a composed `OutlinedContainer`; hover steps its
  // border through the same primitive (`disabled > hover > rest` — the panel
  // has no container-level focus or error state).
  group('panel hover border', () {
    testWidgets('the resolver swaps only the border colour', (tester) async {
      await tester.pumpWidget(_buildApp(const ItemPicker(items: ['A'])));
      final _ = await tester.pumpAndSettle();

      final resolved = resolveItemPicker(
        tester.element(find.byType(ItemPicker)),
      );
      final rest = resolved.containerStyle;
      final hovered = resolved.hoveredContainerStyle;

      expect(rest.borderColor, CoreItemPickerStyle.defaultBorderColor);
      expect(hovered.borderColor, CoreItemPickerStyle.defaultHoverBorderColor);
      // Everything else is the resting chrome — a hovered panel must not
      // be a different box.
      expect(hovered.copyWith(borderColor: rest.borderColor), equals(rest));
    });

    testWidgets('rests on the resting border', (tester) async {
      await tester.pumpWidget(_buildApp(const ItemPicker(items: ['A'])));
      final _ = await tester.pumpAndSettle();

      expect(
        _panelBorderColor(tester),
        _resolved(tester, CoreItemPickerStyle.defaultBorderColor),
      );
    });

    testWidgets('the pointer steps the border to the hover colour and back', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const ItemPicker(items: ['Apple', 'Banana'])),
      );
      final _ = await tester.pumpAndSettle();
      final rest = _resolved(tester, CoreItemPickerStyle.defaultBorderColor);
      final hover = _resolved(
        tester,
        CoreItemPickerStyle.defaultHoverBorderColor,
      );
      expect(hover, isNot(rest));

      final gesture = await _hoverOver(tester, find.byType(ItemPicker));
      expect(_panelBorderColor(tester), hover);

      // Over an option inside the panel is still over the panel.
      await gesture.moveTo(tester.getCenter(find.text('Banana')));
      await tester.pumpAndSettle();
      expect(_panelBorderColor(tester), hover);

      await gesture.moveTo(const Offset(1, 1));
      await tester.pumpAndSettle();
      expect(_panelBorderColor(tester), rest);
    });

    testWidgets('a per-instance hoverBorderColor wins over the default', (
      tester,
    ) async {
      const custom = CoreColor.token(CoreColors.error);
      await tester.pumpWidget(
        _buildApp(
          const ItemPicker(
            items: ['A'],
            itemPickerStyle: CoreItemPickerStyle(hoverBorderColor: custom),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      await _hoverOver(tester, find.byType(ItemPicker));

      expect(_panelBorderColor(tester), _resolved(tester, custom));
    });

    testWidgets('a disabled picker has no hover step', (tester) async {
      await tester.pumpWidget(
        _buildApp(const ItemPicker(items: ['A'], enabled: false)),
      );
      final _ = await tester.pumpAndSettle();

      await _hoverOver(tester, find.byType(ItemPicker));

      expect(
        _panelBorderColor(tester),
        _resolved(tester, CoreItemPickerStyle.defaultBorderColor),
      );
    });
  });

  group('panel redesign (#5831)', () {
    testWidgets('the panel is a floating face: bright fill, quiet line, '
        'corner 12, the strong cast', (tester) async {
      await tester.pumpWidget(_buildApp(const ItemPicker(items: ['A'])));
      final _ = await tester.pumpAndSettle();

      final panel = tester.widget<OutlinedContainer>(
        find.byType(OutlinedContainer),
      );
      final style = panel.containerStyle!;
      expect(
        style.backgroundColor,
        const CoreColor.token(
          CoreColors.surfaceBright,
        ),
      );
      expect(
        style.borderColor,
        const CoreColor.token(
          CoreColors.outlineVariant,
        ),
      );
      expect(
        style.borderRadius,
        const CoreBorderRadius.all(CoreRadiusRole.panel),
      );
      expect(style.elevation, CoreOutlinedContainerElevation.strong);
    });

    testWidgets('the search row is the bare field with a search glyph and '
        'a divider below it', (tester) async {
      await tester.pumpWidget(_buildApp(const ItemPicker(items: ['A'])));
      final _ = await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.variant, CoreTextFieldVariant.plain);
      expect(field.prefix, isA<Icon>());
      expect(_iconNamed(LucideIcons.search), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('the list is inset 6 and its rows are 8 padded with corner '
        '8', (tester) async {
      await tester.pumpWidget(_buildApp(const ItemPicker(items: ['A'])));
      final _ = await tester.pumpAndSettle();

      final resolved = resolveItemPicker(
        tester.element(find.byType(ItemPicker)),
      );
      expect(resolved.itemsPadding, const EdgeInsets.all(CoreSpace.space6));
      expect(resolved.optionPadding, const EdgeInsets.all(CoreSpace.space8));
      expect(
        resolved.optionBorderRadius,
        BorderRadius.circular(CoreRadiusRole.control),
      );
    });

    testWidgets('the selection is the check alone, in primary; no fill', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const ItemPicker(items: ['A', 'B'], selectedValue: 'B'),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final resolved = resolveItemPicker(
        tester.element(find.byType(ItemPicker)),
      );
      expect(resolved.selectedColor.a, 0);
      expect(
        resolved.checkIconStyle.color,
        const CoreColor.token(CoreColors.primary),
      );
      expect(_iconNamed(LucideIcons.check), findsOneWidget);
    });

    testWidgets('the title is a label inside the list, below the search '
        'row', (tester) async {
      await tester.pumpWidget(
        _buildApp(const ItemPicker(items: ['A'], title: 'Fruit')),
      );
      final _ = await tester.pumpAndSettle();

      final title = tester.getTopLeft(find.text('Fruit')).dy;
      expect(
        title,
        greaterThan(tester.getBottomLeft(find.byType(TextField)).dy),
      );
      expect(title, lessThan(tester.getTopLeft(find.text('A')).dy));
    });

    testWidgets('the section label is a 27 row in labelSmall · '
        'onSurfaceSubtle that fills the list and lines up with the rows '
        '(#5884)', (tester) async {
      await tester.pumpWidget(
        _buildApp(const ItemPicker(items: ['Apple'], title: 'Fruit')),
      );
      final _ = await tester.pumpAndSettle();

      final labelText = find.text('Fruit');
      final row = find
          .ancestor(of: labelText, matching: find.byType(Padding))
          .first;
      // 6 + the 16.8 labelSmall line box + 4.
      expect(tester.getSize(row).height, closeTo(27, 0.5));
      expect(
        tester.getTopLeft(row).dy,
        closeTo(
          tester.getTopLeft(labelText).dy - CoreSpace.space6,
          0.01,
        ),
      );

      // Fills the list's inner width: the panel less its 1 line and the
      // list's 6 inset on each side.
      final column = find
          .ancestor(of: row, matching: find.byType(Column))
          .first;
      expect(tester.getSize(row).width, tester.getSize(column).width);
      expect(
        tester.getSize(row).width,
        _kPreviewWidth -
            2 * CoreItemPickerStyle.defaultBorderWidth -
            2 * CoreSpace.space6,
      );

      // The label and the option text start on the same column.
      expect(
        tester.getTopLeft(labelText).dx,
        closeTo(tester.getTopLeft(find.text('Apple')).dx, 0.01),
      );

      final style = tester
          .widget<RichText>(
            find.descendant(of: labelText, matching: find.byType(RichText)),
          )
          .text
          .style!;
      expect(style.fontSize, 12);
      expect(style.fontWeight, FontWeight.w500);
      expect(
        style.color,
        _resolved(tester, const CoreColor.token(CoreColors.onSurfaceSubtle)),
      );
    });
  });
}
