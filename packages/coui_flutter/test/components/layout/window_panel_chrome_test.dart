import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart' show IconTheme;
import 'package:flutter_test/flutter_test.dart';

const _kPanelWidth = 320.0;

/// The title bar's row container — the only `Container` in a bare panel that
/// pads by the title bar's own side padding.
final _titleBar = find.byWidgetPredicate(
  (widget) =>
      widget is Container &&
      widget.padding == const EdgeInsets.symmetric(horizontal: 12),
  description: 'title bar Container',
);

Future<void> _pumpPanel(WidgetTester tester) async {
  final _ = await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: const ThemeData(),
        child: Center(
          child: SizedBox(
            width: _kPanelWidth,
            child: WindowPanel(
              title: const material.Text('T'),
              child: const SizedBox(height: 80),
            ),
          ),
        ),
      ),
    ),
  );
  final settled = await tester.pumpAndSettle();
  expect(settled, greaterThan(0));
}

BoxDecoration _titleBarDecoration(WidgetTester tester) {
  final container = tester.widget<Container>(_titleBar);
  return container.decoration! as BoxDecoration;
}

void main() {
  group('WindowPanel default chrome', () {
    testWidgets('the title bar pads its sides by 12', (tester) async {
      await _pumpPanel(tester);

      expect(_titleBar, findsOneWidget);
    });

    testWidgets('the title bar draws no divider under itself', (tester) async {
      await _pumpPanel(tester);

      expect(_titleBarDecoration(tester).border, isNull);
    });

    testWidgets('the frame corner is 12 and the bar follows it by one border', (
      tester,
    ) async {
      await _pumpPanel(tester);

      final radius = _titleBarDecoration(tester).borderRadius! as BorderRadius;
      // Outer 12 − the 1px container border.
      expect(radius.topLeft.x, 11);
      expect(radius.topRight.x, 11);
      expect(radius.bottomLeft.x, 0);
    });

    testWidgets('the frame casts the md step, one layer at 10%', (
      tester,
    ) async {
      await _pumpPanel(tester);

      final frame = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .map((decoration) => decoration.boxShadow)
          .where((shadows) => shadows != null && shadows.isNotEmpty)
          .toList();

      expect(frame, hasLength(1));
      final layers = frame.single!;
      expect(layers, hasLength(1));

      // The same step through the shared converter — the blur is a CSS
      // length there, so the Flutter value is the converter's, not 24.
      final theme = Theme.of(tester.element(find.byType(WindowPanel)));
      final expected = CoreShadow.md.toValue(
        base: theme.colorScheme
            .resolve(const CoreColor.token(CoreColors.shadow))
            .toValue(),
        geometry: theme.geometry,
      );
      expect(layers.single.offset, const Offset(0, 8));
      expect(layers.single.offset, expected.single.offset);
      expect(layers.single.blurRadius, expected.single.blurRadius);
      expect(layers.single.spreadRadius, expected.single.spreadRadius);
      // The strength sits on the layer, not on a second alpha over the base.
      expect(layers.single.color.a, closeTo(0.1, 0.005));
      expect(layers.single.color, expected.single.color);
    });
  });

  group('WindowPanel control glyph colour', () {
    Future<void> pumpWithControls(WidgetTester tester) async {
      final _ = await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(),
            child: Center(
              child: SizedBox(
                width: _kPanelWidth,
                child: WindowPanel(
                  title: const material.Text('T'),
                  onClose: () {},
                  onMinimize: () {},
                  minimizable: true,
                  child: const SizedBox(height: 80),
                ),
              ),
            ),
          ),
        ),
      );
      final settled = await tester.pumpAndSettle();
      expect(settled, greaterThan(0));
    }

    // The foreground the Button hands its glyph — what the × is painted with.
    Color glyphColor(WidgetTester tester, int buttonIndex) {
      final glyph = find.descendant(
        of: find.byType(Button).at(buttonIndex),
        matching: find.byType(Icon),
      );
      return IconTheme.of(tester.element(glyph)).color!;
    }

    testWidgets('the close × rests on the surface-variant tone, not error', (
      tester,
    ) async {
      await pumpWithControls(tester);

      final theme = Theme.of(tester.element(find.byType(WindowPanel)));
      final surfaceVariant = theme.colorScheme
          .resolve(const CoreColor.token(CoreColors.onSurfaceVariant))
          .toValue();
      final error = theme.colorScheme
          .resolve(const CoreColor.token(CoreColors.error))
          .toValue();

      // Controls render in order: minimize, close.
      expect(find.byType(Button), findsNWidgets(2));
      final close = glyphColor(tester, 1);
      expect(close, surfaceVariant);
      expect(close, isNot(error));
      // And it is the colour the minimize glyph beside it wears.
      expect(close, glyphColor(tester, 0));
    });
  });
}
