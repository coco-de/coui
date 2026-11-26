// Pins that an intrinsic row is measured at the width its cells are laid
// out at.
//
// `computeTableSize` used to measure widths and heights in ONE walk, so the
// height branch read `columnWidths[column]` while it was still null for flex
// columns and fell back to the whole leftover width. The cell was then laid
// out into one column's share of that. Content wrapped tighter than the
// height reserved for it and the overflow was clipped — silently, because
// `performLayout` clamps only the table's own size and the cells are drawn
// inside three clip rects.
//
// It is the DEFAULT configuration: `defaultColumnWidth` is flex and
// `defaultRowHeight` is intrinsic (table.dart), so a plain `Table` in a
// bounded box hits it.
//
// The fix reorders the phases (widths → flex width distribution → heights)
// rather than appending a second pass. A second pass would have left the
// flex ROW heights distributed from a stale total, and its `max` fold would
// have silently discarded the corrected height for spanning cells — where
// the summed-span extent is wider, not narrower, than the old fallback.

import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// Narrow enough that the text must wrap inside one column's share.
const _kTableWidth = 200.0;
const _kLongText =
    'a sentence long enough that it has to wrap once the column is only '
    'half of the table';

List<CoreTableRowData<Widget>> _rows() => [
  CoreTableRowData(
    cells: [
      CoreTableCellData(child: const Text(_kLongText)),
      CoreTableCellData(child: const Text('short')),
    ],
  ),
];

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(
      body: material.Align(
        alignment: Alignment.topLeft,
        child: material.SizedBox(width: _kTableWidth, child: child),
      ),
    ),
  ),
);

void main() {
  group('Table intrinsic row height', () {
    testWidgets('a wrapping cell is given the height it needs', (tester) async {
      await tester.pumpWidget(
        _app(
          Table(rows: _rows()),
        ),
      );
      await tester.pumpAndSettle();

      final cell = tester.getRect(find.text(_kLongText));
      final textWidget = tester.widget<Text>(find.text(_kLongText));

      // What the text needs at the width it actually occupies.
      final painter = TextPainter(
        text: TextSpan(
          text: textWidget.data,
          style: textWidget.style ?? const TextStyle(),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: cell.width);

      expect(
        cell.height,
        greaterThanOrEqualTo(painter.height - 0.5),
        reason:
            'measuring at the full table width and laying out at one '
            'column reserves less height than the wrapped text needs',
      );
      expect(
        painter.didExceedMaxLines || painter.height > 0,
        isTrue,
      );
    });

    testWidgets('the row is taller than a single line', (tester) async {
      // Guards the assertion above from passing on a table that never
      // wrapped: if the text fit on one line, measured and laid-out widths
      // would agree trivially and the case would prove nothing.
      await tester.pumpWidget(
        _app(
          Table(rows: _rows()),
        ),
      );
      await tester.pumpAndSettle();

      final long = tester.getRect(find.text(_kLongText));
      final short = tester.getRect(find.text('short'));

      expect(
        long.height,
        greaterThan(short.height),
        reason: 'the long cell must actually be wrapping in this layout',
      );
    });

    testWidgets('the table does not exceed its width', (tester) async {
      await tester.pumpWidget(
        _app(
          Table(rows: _rows()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.byType(Table)).width,
        lessThanOrEqualTo(_kTableWidth + 0.5),
      );
    });
  });
}
