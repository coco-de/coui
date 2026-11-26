// #5350 — a labelled SwitchField / Checkbox is one pressable row, and a
// theme can give that row a touch-target floor through `minHeight`.
//
// The default stays as it is: the design decision on press areas (D17,
// #5306) keeps the 24 floor and does not widen rows by default. These
// tests pin both halves — nothing moves unless a theme asks, and when it
// asks, the row (label included) is the floor × scaling tall, presses
// anywhere in it, and stacked rows do not overlap.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

const double _kTouchTarget = CoreA11ySize.touchTarget;

ThemeData _theme({double? minHeight}) => ThemeData(
  coreComponentTheme: minHeight == null
      ? null
      : CoreComponentTheme(
          switchField: CoreSwitchFieldTheme(
            style: CoreSwitchFieldStyle(minHeight: minHeight),
          ),
          checkbox: CoreCheckboxTheme(
            style: CoreCheckboxStyle(minHeight: minHeight),
          ),
        ),
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double? minHeight,
  double scaling = 1,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    CoUIApp(
      theme: _theme(minHeight: minHeight),
      scaling: AdaptiveScaling(scaling),
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 342, child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The pressable row — the `Clickable` that owns the press.
Rect _row(WidgetTester tester, Finder of) => tester.getRect(
  find.descendant(of: of, matching: find.byType(Clickable)).first,
);

void main() {
  testWidgets('without a theme floor the rows keep their content height', (
    tester,
  ) async {
    await _pump(
      tester,
      Column(
        children: [
          SwitchField(label: '도착 알림', value: true, onChanged: (_) {}),
          Checkbox(checked: false, label: '미해소만 보기', onChanged: (_) {}),
        ],
      ),
    );

    expect(_row(tester, find.byType(SwitchField)).height, lessThan(30));
    expect(_row(tester, find.byType(Checkbox)).height, lessThan(30));
  });

  for (final scaling in [1.0, 1.25]) {
    testWidgets('a theme floor makes each labelled row ≥ 48 × $scaling and '
        'meets the tap-target guideline', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        Column(
          children: [
            SwitchField(label: '도착 알림', value: true, onChanged: (_) {}),
            SwitchField(
              label: '야간 알림',
              description: '22시부터 7시까지',
              value: false,
              onChanged: (_) {},
            ),
            Checkbox(checked: false, label: '미해소만 보기', onChanged: (_) {}),
          ],
        ),
        minHeight: _kTouchTarget,
        scaling: scaling,
      );

      for (final widget in [
        find.byType(SwitchField).first,
        find.byType(SwitchField).last,
        find.byType(Checkbox),
      ]) {
        expect(
          _row(tester, widget).height,
          greaterThanOrEqualTo(_kTouchTarget * scaling - 0.01),
        );
      }
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  }

  testWidgets('the whole floored row is the press area', (tester) async {
    var switched = false;
    bool? checked = false;
    await _pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => Column(
          children: [
            SwitchField(
              label: '도착 알림',
              value: switched,
              onChanged: (value) => setState(() => switched = value),
            ),
            Checkbox(
              checked: checked,
              label: '미해소만 보기',
              onChanged: (value) => setState(() => checked = value),
            ),
          ],
        ),
      ),
      minHeight: _kTouchTarget,
    );

    // Just inside the top edge — above the label's glyphs, inside the
    // floor the theme added.
    final switchRow = _row(tester, find.byType(SwitchField));
    await tester.tapAt(switchRow.topLeft + const Offset(4, 2));
    await tester.pumpAndSettle();
    expect(switched, isTrue);

    final checkboxRow = _row(tester, find.byType(Checkbox));
    await tester.tapAt(checkboxRow.bottomLeft + const Offset(4, -2));
    await tester.pumpAndSettle();
    expect(checked, isTrue);
  });

  testWidgets('stacked floored rows do not overlap — each press lands on '
      'its own row', (tester) async {
    final values = List<bool?>.filled(5, false);
    await _pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => Column(
          children: [
            for (var i = 0; i < values.length; i++)
              Checkbox(
                checked: values[i],
                label: '항목 $i',
                onChanged: (value) => setState(() => values[i] = value),
              ),
          ],
        ),
      ),
      minHeight: _kTouchTarget,
    );

    final rows = [
      for (var i = 0; i < values.length; i++)
        _row(tester, find.byType(Checkbox).at(i)),
    ];
    for (var i = 1; i < rows.length; i++) {
      expect(rows[i].top, greaterThanOrEqualTo(rows[i - 1].bottom - 0.01));
    }
    for (var i = 0; i < rows.length; i++) {
      // Near the boundary with the next row — the press stays on this one.
      await tester.tapAt(rows[i].bottomLeft + const Offset(4, -1));
      await tester.pumpAndSettle();
      expect(values, [for (var j = 0; j < values.length; j++) j <= i]);
    }
  });
}
