// A one-line field is held on its size row: the box is the row's control
// height at every size and density, and the value line is centred in it —
// read off the painted rectangles, not the resolver (#5762, 2026-11-04 결정).
//
// The row's vertical padding no longer sizes the box: on the small rows it
// ran past the rung (`sm` 6 + 21 + 6 + border = 35 against 32, `xs` 30
// against 24). Centring holds the rung with whole-number values instead of
// a half-pixel padding.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart' as w;
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child,
  CoreDensity density,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 600);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    CoUIApp(
      theme: const ThemeData(),
      density: density,
      home: w.Align(
        alignment: w.Alignment.topCenter,
        child: w.SizedBox(width: 320, child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The row the field sits on: its size's rung, moved by the density.
double _row(CoreComponentSize size, CoreDensity density) =>
    density.controlHeight(CoreTextFieldStyle.defaultsBySize[size]!.minHeight!);

/// The field's box and the value line's top / bottom gaps inside it.
({double height, double top, double bottom}) _measure(WidgetTester tester) {
  final box = tester.getRect(find.byType(TextField).first);
  final state = tester.state<EditableTextState>(find.byType(EditableText));
  final editable = state.renderEditable;
  final lineTop = editable.localToGlobal(Offset.zero).dy;
  final line = editable.preferredLineHeight;
  return (
    height: box.height,
    top: lineTop - box.top,
    bottom: box.bottom - lineTop - line,
  );
}

void main() {
  for (final density in CoreDensity.values) {
    for (final size in CoreComponentSize.values) {
      for (final prefixed in [false, true]) {
        testWidgets('${density.name} ${size.name}'
            '${prefixed ? ' with a prefix' : ''}: the box is the row, '
            'the line centred', (tester) async {
          await _pump(
            tester,
            TextField(
              size: size,
              initialValue: 'Value',
              prefix: prefixed ? const Icon(LucideIcons.search) : null,
            ),
            density,
          );
          final m = _measure(tester);
          expect(m.height, _row(size, density));
          expect(m.top, m.bottom);
          // The line fits inside the border on every row.
          expect(m.top, greaterThanOrEqualTo(CoreStrokeWidth.stroke1));
        });
      }
    }

    for (final size in CoreSelectSize.values) {
      testWidgets('${density.name} Select ${size.name}: on the field row', (
        tester,
      ) async {
        await _pump(
          tester,
          Select<String>(
            size: size,
            items: const [CoreSelectItem(value: 'a', label: 'Apple')],
            value: 'a',
            onChanged: (_) {},
          ),
          density,
        );
        final m = _measure(tester);
        expect(m.height, _row(size.toComponentSize(), density));
        expect(m.top, m.bottom);
      });
    }
  }

  testWidgets('a field that grows keeps the row padding', (tester) async {
    // Several lines are not held on one row: the row's vertical padding is
    // the inset above the first line.
    await _pump(
      tester,
      TextField(initialValue: 'a\nb', maxLines: 3),
      CoreDensity.standard,
    );
    final m = _measure(tester);
    final rowPadding =
        CoreTextFieldStyle.defaultsBySize[CoreComponentSize.md]!.padding!;
    expect(m.top, CoreStrokeWidth.stroke1 + rowPadding.top);
    expect(m.height, greaterThan(_row(.md, .standard)));
  });
}
