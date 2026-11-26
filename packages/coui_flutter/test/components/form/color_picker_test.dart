import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

// Hex string length constants: '#' + 8 hex chars (with alpha) or 6 hex
// chars (without alpha).
const _kHexWithAlphaLength = 9;
const _kHexWithoutAlphaLength = 7;

/// How long the tests let an opening popover settle.
const Duration _kPopoverSettle = Duration(milliseconds: 250);

/// The trigger's chevron — the coui `Icon` takes an `IconName`, which
/// `find.byIcon` does not match.
final Finder _chevron = find.byWidgetPredicate(
  (w) => w is Icon && w.icon == LucideIcons.chevronDown,
);

void main() {
  group('colorToHex', () {
    test('returns hex string with alpha by default', () {
      const color = material.Color(0xFFFF0000);
      final hex = colorToHex(color);

      expect(hex, startsWith('#'));
      expect(hex.length, equals(_kHexWithAlphaLength));
    });

    test('returns hex string without alpha when showAlpha is false', () {
      const color = material.Color(0xFFFF0000);
      final hex = colorToHex(color, false);

      expect(hex, startsWith('#'));
      expect(hex.length, equals(_kHexWithoutAlphaLength));
    });
  });

  group('ColorPicker popover', () {
    testWidgets('opens without a layout exception', (tester) async {
      await tester.pumpWidget(
        const material.MaterialApp(
          home: Theme(
            data: ThemeData(),
            child: material.Scaffold(
              body: Center(
                child: ColorPicker(color: material.Color(0xFFFF0000)),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ColorPicker));
      // One frame builds + lays out the popover panel — this is where
      // `Popup`'s `IntrinsicWidth` would throw on the SV area if it weren't
      // intrinsic-measurable. `pumpAndSettle` is avoided: the open panel
      // owns a perpetual animation (text-field caret) that never settles.
      await tester.pump();
      await tester.pump(_kPopoverSettle);

      expect(tester.takeException(), isNull);
      expect(find.byType(ColorPicker), findsOneWidget);
    });
  });

  group('ColorPicker redesigned chrome', () {
    Future<void> pumpOpen(WidgetTester tester, material.Color color) async {
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(),
            child: material.Scaffold(
              body: Center(child: ColorPicker(color: color)),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ColorPicker));
      await tester.pump();
      await tester.pump(_kPopoverSettle);
    }

    testWidgets('mode tabs are the shared ToggleGroup', (tester) async {
      await pumpOpen(tester, const material.Color(0xFFFF0000));
      expect(tester.takeException(), isNull);
      expect(find.byType(ToggleGroup<CoreColorPickerMode>), findsOneWidget);
    });

    testWidgets('area has no border, bar is 8 high under 18 handles', (
      tester,
    ) async {
      await pumpOpen(tester, const material.Color(0xFFFF0000));
      expect(tester.takeException(), isNull);
      // Two handles: one on the saturation/value area, one on the hue bar.
      final handles = find.byType(IgnorePointer).evaluate().where((e) {
        final size = (e.renderObject! as RenderBox).size;
        return size == const Size.square(18);
      });
      expect(handles.length, 2);
      // The hue slider's hit box is as tall as the handle.
      final hue = find.byWidgetPredicate(
        (w) => w is SizedBox && w.height == 18 && w.child is LayoutBuilder,
      );
      expect(hue, findsOneWidget);
    });

    testWidgets('both handles: the current colour in a white 3 ring', (
      tester,
    ) async {
      await pumpOpen(tester, const material.Color(0xFFFF0000));
      expect(tester.takeException(), isNull);
      final discs = find
          .byType(IgnorePointer)
          .evaluate()
          .where(
            (e) => (e.renderObject! as RenderBox).size == const Size.square(18),
          )
          .map(
            (e) =>
                (find
                                .descendant(
                                  of: find.byWidget(e.widget),
                                  matching: find.byType(material.DecoratedBox),
                                )
                                .evaluate()
                                .first
                                .widget
                            as material.DecoratedBox)
                        .decoration
                    as material.BoxDecoration,
          )
          .toList();
      expect(discs.length, 2);
      // Area and hue handles alike: the current colour inside a white 3px
      // ring, over the weakest shadow.
      for (final disc in discs) {
        expect(disc.color, const Color(0xFFFF0000));
        final ring = (disc.border! as material.Border).top;
        expect(ring.color, const Color(0xFFFFFFFF));
        expect(ring.width, 3);
        expect(disc.boxShadow, isNotEmpty);
      }
    });

    testWidgets('the mode tabs span the panel and split it equally', (
      tester,
    ) async {
      await pumpOpen(tester, const material.Color(0xFFFF0000));
      final tabs = tester.getRect(
        find.byType(ToggleGroup<CoreColorPickerMode>),
      );
      final area = tester.getRect(
        find.byWidgetPredicate(
          (w) => w is SizedBox && w.height == 18 && w.child is LayoutBuilder,
        ),
      );
      expect(tabs.width, closeTo(area.width, 0.5));
      expect(tabs.left, closeTo(area.left, 0.5));
    });

    testWidgets('the mode tabs are the sm size: 26 cells in a 32 track', (
      tester,
    ) async {
      await pumpOpen(tester, const material.Color(0xFFFF0000));
      final tabs = find.byType(ToggleGroup<CoreColorPickerMode>);
      expect(
        tester.widget<ToggleGroup<CoreColorPickerMode>>(tabs).size,
        CoreComponentSize.sm,
      );
      expect(tester.getRect(tabs).height, 32);
      final cell = find
          .ancestor(
            of: find.descendant(of: tabs, matching: find.byType(Text)).first,
            matching: find.byType(material.AnimatedContainer),
          )
          .first;
      expect(tester.getRect(cell).height, 26);
    });

    testWidgets('the panel is a 14-corner box with 16 between its sections', (
      tester,
    ) async {
      await pumpOpen(tester, const material.Color(0xFFFF0000));
      final panelBox = find
          .ancestor(
            of: find.byType(ToggleGroup<CoreColorPickerMode>),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is material.DecoratedBox &&
                  w.decoration is material.BoxDecoration &&
                  (w.decoration as material.BoxDecoration).borderRadius ==
                      BorderRadius.circular(CoreRadius.radius14),
            ),
          )
          .evaluate();
      expect(panelBox, isNotEmpty);
      final column = tester.widget<material.Column>(
        find
            .ancestor(
              of: find.byType(ToggleGroup<CoreColorPickerMode>),
              matching: find.byType(material.Column),
            )
            .first,
      );
      expect(column.spacing, 16);
    });

    testWidgets('the panel inputs are HEX + three channels at Size=sm', (
      tester,
    ) async {
      await pumpOpen(tester, const material.Color(0xFF6750A4));
      expect(find.text(kColorPickerHexLabel), findsOneWidget);
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields.length, 4);
      expect(fields.every((f) => f.size == CoreComponentSize.sm), isTrue);
      expect(fields.first.initialValue, '#6750A4');
    });

    testWidgets('the recent colours carry their title', (tester) async {
      // The scope sits above the app: the popover panel is built in the
      // app's overlay, not under `home`.
      await tester.pumpWidget(
        const RecentColorsScope(
          initialRecentColors: [CoreColor(0xFF00FF00)],
          child: material.MaterialApp(
            home: Theme(
              data: ThemeData(),
              child: material.Scaffold(
                body: Center(
                  child: ColorPicker(color: material.Color(0xFFFF0000)),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ColorPicker));
      await tester.pump();
      await tester.pump(_kPopoverSettle);
      final title = tester.widget<material.Text>(find.text('Recently used'));
      expect(title.style?.fontSize, 11);
    });
  });

  group('ColorPicker field trigger', () {
    Future<void> pumpTrigger(WidgetTester tester, material.Color color) =>
        tester.pumpWidget(
          material.MaterialApp(
            home: Theme(
              data: const ThemeData(),
              child: material.Scaffold(
                body: Center(child: ColorPicker(color: color)),
              ),
            ),
          ),
        );

    material.BoxDecoration fieldDecoration(WidgetTester tester) {
      final field = tester.widget<material.Container>(
        find
            .ancestor(
              of: _chevron,
              matching: find.byType(material.Container),
            )
            .first,
      );
      return field.decoration! as material.BoxDecoration;
    }

    testWidgets('is a 184-wide outlined field on the surface face', (
      tester,
    ) async {
      await pumpTrigger(tester, const material.Color(0xFF6750A4));
      final field = find
          .ancestor(
            of: _chevron,
            matching: find.byType(material.Container),
          )
          .first;
      expect(tester.getSize(field).width, greaterThanOrEqualTo(184));
      final container = tester.widget<material.Container>(field);
      // Start 4 (beside the swatch), end 12 (after the chevron) — directional.
      expect(
        container.padding,
        const EdgeInsetsDirectional.fromSTEB(
          CoreSpace.space4,
          CoreSpace.space4,
          CoreSpace.space12,
          CoreSpace.space4,
        ),
      );
      final decoration = fieldDecoration(tester);
      expect(
        decoration.borderRadius,
        BorderRadius.circular(CoreRadius.radius10),
      );
      final border = decoration.border! as material.Border;
      expect(border.top.width, 1);
      final scheme = Theme.of(tester.element(field)).colorScheme;
      expect(
        border.top.color,
        scheme
            .resolve(const CoreColor.token(CoreColors.outlineVariant))
            .toValue(),
      );
      expect(
        decoration.color,
        scheme.resolve(const CoreColor.token(CoreColors.surface)).toValue(),
      );
      final row = tester.widget<material.Row>(
        find
            .ancestor(
              of: _chevron,
              matching: find.byType(material.Row),
            )
            .first,
      );
      expect(row.spacing, 10);
      expect(
        tester.getSize(_chevron),
        const Size.square(16),
      );
    });

    testWidgets('a picked colour shows a 32 swatch and its hex in 13 Medium', (
      tester,
    ) async {
      await pumpTrigger(tester, const material.Color(0xFF6750A4));
      final swatch = find.byWidgetPredicate(
        (w) =>
            w is material.DecoratedBox &&
            w.decoration is material.BoxDecoration &&
            (w.decoration as material.BoxDecoration).borderRadius ==
                BorderRadius.circular(CoreRadius.radius6),
      );
      expect(swatch, findsOneWidget);
      expect(tester.getSize(swatch), const Size.square(32));
      final hex = tester.widget<material.Text>(find.text('#6750A4'));
      expect(hex.style?.fontSize, 13);
      expect(hex.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('no colour shows the dashed swatch and the placeholder', (
      tester,
    ) async {
      await pumpTrigger(tester, const material.Color(0x00000000));
      final text = find.text('No colour picked');
      expect(text, findsOneWidget);
      final style = material.DefaultTextStyle.of(tester.element(text)).style;
      expect(style.fontSize, 13);
      expect(style.fontWeight, FontWeight.w400);
      expect(
        style.color,
        Theme.of(tester.element(text)).colorScheme
            .resolve(const CoreColor.token(CoreColors.onSurfaceVariant))
            .toValue(),
      );
    });
  });

  group('ColorPicker inline presentation', () {
    Future<List<Color>> pumpInline(WidgetTester tester) async {
      final changes = <Color>[];
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(),
            child: material.Scaffold(
              body: Center(
                child: ColorPicker(
                  color: const material.Color(0xFF6750A4),
                  onChanged: changes.add,
                  promptMode: .inline,
                ),
              ),
            ),
          ),
        ),
      );
      return changes;
    }

    testWidgets('popover stays the default presentation', (tester) async {
      await tester.pumpWidget(
        const material.MaterialApp(
          home: Theme(
            data: ThemeData(),
            child: material.Scaffold(
              body: Center(
                child: ColorPicker(color: material.Color(0xFF6750A4)),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(Popover), findsOneWidget);
      expect(_chevron, findsOneWidget);
    });

    testWidgets('draws the panel in place, without a trigger or shadow', (
      tester,
    ) async {
      await pumpInline(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(Popover), findsNothing);
      expect(_chevron, findsNothing);
      expect(find.byType(ToggleGroup<CoreColorPickerMode>), findsOneWidget);
      final popup = tester.widget<Popup>(find.byType(Popup));
      expect(popup.popupStyle?.boxShadow, isEmpty);
    });

    testWidgets('a comparison cell takes the place of Cancel / Save', (
      tester,
    ) async {
      await pumpInline(tester);
      expect(find.text('Cancel'), findsNothing);
      expect(find.text('Save'), findsNothing);
      final halves = find.byWidgetPredicate(
        (w) =>
            w is material.SizedBox &&
            w.width == 24 &&
            w.height == 24 &&
            w.child is material.ColoredBox,
      );
      expect(halves, findsNWidgets(2));
      final cell = tester.widget<material.Container>(
        find.ancestor(of: halves.first, matching: find.byType(Container)).first,
      );
      final decoration = cell.decoration! as material.BoxDecoration;
      expect(
        decoration.borderRadius,
        BorderRadius.circular(CoreRadius.radius6),
      );
      expect((decoration.border! as material.Border).top.width, 1);
    });

    testWidgets('a disabled inline panel stays in view with its inputs off', (
      tester,
    ) async {
      await tester.pumpWidget(
        const material.MaterialApp(
          home: Theme(
            data: ThemeData(),
            child: material.Scaffold(
              body: Center(
                child: ColorPicker(
                  color: material.Color(0xFF6750A4),
                  enabled: false,
                  promptMode: .inline,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(ToggleGroup<CoreColorPickerMode>), findsOneWidget);
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields, hasLength(4));
      expect(fields.every((f) => !(f.enabled ?? true)), isTrue);
    });

    testWidgets('commits each edit as it happens', (tester) async {
      final changes = await pumpInline(tester);
      await tester.enterText(find.byType(TextField).first, '#00FF00');
      await tester.pump();
      expect(changes, isNotEmpty);
      expect(changes.last, const material.Color(0xFF00FF00));
    });
  });

  group('ColorPicker empty swatch', () {
    testWidgets('a transparent value shows the empty dashed swatch', (
      tester,
    ) async {
      await tester.pumpWidget(
        const material.MaterialApp(
          home: Theme(
            data: ThemeData(),
            child: material.Scaffold(
              body: Center(
                child: ColorPicker(color: material.Color(0x00000000)),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter.toString().contains('Dashed'),
        ),
        findsOneWidget,
      );
    });
  });
}
