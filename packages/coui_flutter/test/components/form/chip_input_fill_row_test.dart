// The chip input's entry field takes what is left of its row.
//
// The Web twin's field is `flex: 1` with a `min-width`: it joins the current
// row only if the floor is left there, and either way it then fills its row —
// its width is never asked of its text. Flutter's field used to hug its text
// (a guess, measured with a `TextPainter`), so the same chips and the same
// typed tag broke into rows differently on the two platforms.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/form/chip_input/chip_input_wrap.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => material.MaterialApp(
  home: material.Scaffold(
    body: Theme(data: const ThemeData(), child: child),
  ),
);

Widget _box(double width, double height) =>
    SizedBox(width: width, height: height);

/// Where each child of the wrap sits, in the wrap's own space.
List<Rect> _slots(WidgetTester tester) {
  final wrap = tester.renderObject<RenderChipInputWrap>(
    find.byType(ChipInputWrap),
  );
  final rects = <Rect>[];
  for (
    var child = wrap.firstChild;
    child != null;
    child = wrap.childAfter(child)
  ) {
    rects.add(
      (child.parentData! as ChipInputWrapParentData).offset & child.size,
    );
  }
  return rects;
}

/// A [ChipInputWrap] of two 100×28 chips and a 40-tall field, in [width].
Widget _wrap({
  required double width,
  bool fillsLast = true,
  TextDirection direction = TextDirection.ltr,
  int chips = 2,
}) => Directionality(
  textDirection: direction,
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: width,
      child: ChipInputWrap(
        spacing: 6,
        minFieldWidth: 80,
        fillsLast: fillsLast,
        textDirection: direction,
        children: [
          for (var i = 0; i < chips; i++) _box(100, 28),
          _box(1, 40),
        ],
      ),
    ),
  ),
);

void main() {
  group('ChipInputWrap — the rule', () {
    testWidgets('the field takes what is left of the row', (tester) async {
      await tester.pumpWidget(_wrap(width: 320));
      final slots = _slots(tester);

      expect(slots[2].left, 100 + 6 + 100 + 6);
      expect(slots[2].right, 320, reason: 'to the end of the row');
      expect(slots[2].width, 108);
    });

    testWidgets('it joins the row when exactly the floor is left', (
      tester,
    ) async {
      // 100 + 6 + 100 + 6 + 80
      await tester.pumpWidget(_wrap(width: 292));
      final slots = _slots(tester);

      expect(slots[2].width, 80);
      expect(slots[2].top, lessThan(slots[0].bottom + 6));
    });

    testWidgets('it opens the next row when less than the floor is left', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(width: 291));
      final slots = _slots(tester);

      expect(slots[2].left, 0);
      expect(slots[2].width, 291, reason: 'all of a row of its own');
      expect(slots[2].top, 28 + 6);
    });

    testWidgets('with no chips it is the whole row', (tester) async {
      await tester.pumpWidget(_wrap(width: 320, chips: 0));

      expect(_slots(tester).single.width, 320);
    });

    testWidgets('chips and the field centre on each other in a row', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(width: 320));
      final slots = _slots(tester);

      // The row is the field's 40; a 28 chip sits 6 from the top.
      expect(slots[0].top, 6);
      expect(slots[2].top, 0);
    });

    testWidgets('a full chip input is a plain wrap — its last child hugs', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(width: 320, fillsLast: false));
      final slots = _slots(tester);

      expect(slots[2].width, 1);
    });

    testWidgets('the start is the right in a right-to-left row', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(width: 320, direction: TextDirection.rtl));
      final slots = _slots(tester);

      expect(slots[0].right, 320);
      expect(slots[1].right, 320 - 100 - 6);
      expect(slots[2].left, 0, reason: 'the field runs to the far end');
      expect(slots[2].width, 108);
    });

    testWidgets('without a bound it is one row, the field at its floor', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: UnconstrainedBox(
              child: ChipInputWrap(
                spacing: 6,
                minFieldWidth: 80,
                fillsLast: true,
                textDirection: TextDirection.ltr,
                children: [_box(100, 28), _box(100, 28), _box(1, 40)],
              ),
            ),
          ),
        ),
      );
      final slots = _slots(tester);

      expect(slots[2].width, 80);
      expect(slots[2].top, 0, reason: 'still the one row');
    });

    testWidgets('a dry layout says what the layout does', (tester) async {
      for (final width in <double>[320, 291, 160]) {
        await tester.pumpWidget(_wrap(width: width));
        final wrap = tester.renderObject<RenderChipInputWrap>(
          find.byType(ChipInputWrap),
        );
        expect(
          wrap.getDryLayout(BoxConstraints.tightFor(width: width)),
          wrap.size,
          reason: 'at $width',
        );
      }
    });
  });

  group('ChipInput — the field', () {
    Widget chipInput({
      double width = 320,
      List<String> chips = const ['alpha', 'beta'],
      CoreChipInputStyle? style,
      int? maxChips,
    }) => _app(
      Center(
        child: SizedBox(
          width: width,
          child: ChipInput(
            chips: chips,
            chipInputStyle: style,
            maxChips: maxChips,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    /// The frame's inner row, and where the field and the last chip sit in it.
    ({Rect row, Rect lastChip, Rect field}) geometry(WidgetTester tester) {
      final wrap = tester.renderObject<RenderChipInputWrap>(
        find.byType(ChipInputWrap),
      );
      final slots = _slots(tester);
      final origin = wrap.localToGlobal(Offset.zero);
      return (
        row: origin & wrap.size,
        lastChip: slots[slots.length - 2].shift(origin),
        field: slots.last.shift(origin),
      );
    }

    testWidgets('fills the row to the frame, after the last chip', (
      tester,
    ) async {
      await tester.pumpWidget(chipInput());
      final g = geometry(tester);

      expect(g.field.right, closeTo(g.row.right, 0.01));
      expect(g.field.left, greaterThan(g.lastChip.right));
      expect(g.field.width, greaterThanOrEqualTo(80));
    });

    testWidgets('a long tag typed into it neither moves nor resizes it', (
      tester,
    ) async {
      await tester.pumpWidget(chipInput());
      final before = geometry(tester).field;

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'kubernetes-cluster-1');
      await tester.pump();
      final after = geometry(tester).field;

      expect(after, before, reason: 'the row decision never reads the text');
    });

    testWidgets('a field that does not fit beside the chips starts a row', (
      tester,
    ) async {
      await tester.pumpWidget(chipInput(width: 200));
      final g = geometry(tester);

      expect(g.field.top, greaterThan(g.lastChip.top));
      expect(g.field.width, closeTo(g.row.width, 0.01));
    });

    testWidgets('the floor is the Contract\'s one constant', (tester) async {
      expect(CoreChipInputContract.defaultInputMinWidth, 80);

      await tester.pumpWidget(chipInput());
      final g = geometry(tester);
      expect(
        g.field.width,
        greaterThanOrEqualTo(CoreChipInputContract.defaultInputMinWidth),
      );
    });

    testWidgets('a field that was typed into still takes a key', (
      tester,
    ) async {
      await tester.pumpWidget(chipInput());
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
