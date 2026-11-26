// A chip drawn wider than its content — a caller's fixed width — places the
// content row by `CoreChipStyle.contentAlignment`, centred by default (#6068:
// a fixed-width chip read as weighted to its leading edge).
//
// Read from the rendered rectangles, not the resolver: the value reaching
// `ResolvedChip` says nothing about where the label lands inside the box.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const double _kWidth = 200;

Future<(Rect chip, Rect label)> _measure(
  WidgetTester tester, {
  CoreChipStyle? chipStyle,
  bool removable = false,
}) async {
  await pumpTestApp(
    tester,
    Center(
      child: SizedBox(
        width: _kWidth,
        child: Chip(
          label: 'Tag',
          chipStyle: chipStyle,
          onTap: () {},
          onRemove: removable ? () {} : null,
        ),
      ),
    ),
  );
  final chip = tester.getRect(find.byType(OutlinedContainer).first);
  final label = tester.getRect(find.text('Tag'));

  return (chip, label);
}

void main() {
  testWidgets('the label sits in the middle of a widened chip', (
    tester,
  ) async {
    final (chip, label) = await _measure(tester);
    expect(chip.width, _kWidth, reason: 'the chip takes the fixed width');
    expect(label.center.dx, moreOrLessEquals(chip.center.dx, epsilon: 0.5));
  });

  testWidgets('the whole row — label and close button — is centred', (
    tester,
  ) async {
    final (chip, label) = await _measure(tester, removable: true);
    final close = tester.getRect(find.byType(Button).last);
    final leftGap = label.left - chip.left;
    final rightGap = chip.right - close.right;
    // The close glyph sits inside its own box, so the gaps differ by at most
    // that inset; what must not happen is the whole slack piling on one side.
    expect((leftGap - rightGap).abs(), lessThan(8));
    expect(leftGap, greaterThan(40));
  });

  testWidgets('a caller can still pack the row to the start', (tester) async {
    final (chip, label) = await _measure(
      tester,
      chipStyle: const CoreChipStyle(contentAlignment: .start),
    );
    expect(label.center.dx, lessThan(chip.center.dx - 40));
  });
}
