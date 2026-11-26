// Where a labelled Divider puts its label and its two line segments, read off
// the rendered widget tree.
//
// The Flutter layout is the reference: the label and its padding sit between
// two segments that share what the label leaves, and each segment holds its
// own inset inside its share. So the label does not move when the insets are
// unequal; the insets only shorten the lines. The expected positions are the
// vector table coui_core shares with the Chrome probe of the Web markup
// (`divider_label_vectors.json`), so a layout change on one platform fails the
// other.
//
// Every number is read from a rect the widget tree painted — the label's, the
// divider's own and the two line boxes — never from the resolved style: a
// style that carries the right inset into a widget that places it wrongly
// reads fine from the numbers and wrong on screen.
import 'dart:convert';
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// The vector table shared with the Core reference test and the Chrome probe
/// (cwd is `packages/coui_flutter` under `flutter test`).
const String _kVectorsPath =
    '../coui_core/test/fixtures/divider_label_vectors.json';

const _kLabelKey = ValueKey<String>('divider-label');

/// A span along the divider's main axis, measured from the box's start edge.
typedef _Span = ({double start, double end});

/// One row of the table.
class _Case {
  _Case(this.json);

  final Map<String, Object?> json;

  String get name => json['name']! as String;
  bool get horizontal => json['orientation'] == 'horizontal';
  double _n(String key) => (json[key]! as num).toDouble();
  double get box => _n('box');
  double get label => _n('label');
  double get childPadding => _n('childPadding');
  double get indent => _n('indent');
  double get endIndent => _n('endIndent');
  CoreDividerChildAlignment get alignment =>
      CoreDividerChildAlignment.values.byName(json['alignment']! as String);
  bool get overflow => json['overflow']! as bool;
  double get labelCentre => _n('labelCentre');

  /// The text directions this row holds in, when it narrows the table's.
  List<TextDirection>? get directions {
    final names = json['directions'] as List?;

    return names == null
        ? null
        : [
            for (final name in names.cast<String>())
              TextDirection.values.byName(name),
          ];
  }

  /// The two expected segments in reading order, `null` where a segment has no
  /// length.
  List<_Span?> get lines => [
    for (final line in (json['lines']! as List).cast<Map<String, Object?>?>())
      if (line == null)
        null
      else
        (
          start: (line['start']! as num).toDouble(),
          end: (line['end']! as num).toDouble(),
        ),
  ];
}

/// One row of the table's `intrinsic` section: a divider whose parent takes
/// its width from its content.
class _Intrinsic {
  _Intrinsic(this.json);

  final Map<String, Object?> json;

  String get name => json['name']! as String;
  double _n(String key) => (json[key]! as num).toDouble();
  double get label => _n('label');
  double get childPadding => _n('childPadding');
  double get indent => _n('indent');
  double get endIndent => _n('endIndent');
  CoreDividerChildAlignment get alignment =>
      CoreDividerChildAlignment.values.byName(json['alignment']! as String);
  double get width => _n('width');
}

Widget _divider(_Case c, double crossExtent) {
  final labelBox = c.horizontal
      ? SizedBox(key: _kLabelKey, width: c.label, height: crossExtent)
      : SizedBox(key: _kLabelKey, width: crossExtent, height: c.label);
  final divider = Divider(
    orientation: c.horizontal ? .horizontal : .vertical,
    dividerStyle: CoreDividerStyle(
      indent: c.indent,
      endIndent: c.endIndent,
      childAlignment: c.alignment,
      childPadding: CoreEdgeInsets.symmetric(horizontal: c.childPadding),
    ),
    child: labelBox,
  );

  return c.horizontal
      ? SizedBox(width: c.box, child: divider)
      : SizedBox(height: c.box, child: divider);
}

/// [rect]'s extent along the divider's main axis, from the box's start edge in
/// reading order.
_Span _fromStart(
  Rect rect,
  Rect box, {
  required bool horizontal,
  required TextDirection direction,
}) {
  if (!horizontal) {
    return (start: rect.top - box.top, end: rect.bottom - box.top);
  }

  return direction == TextDirection.ltr
      ? (start: rect.left - box.left, end: rect.right - box.left)
      : (start: box.right - rect.right, end: box.right - rect.left);
}

void main() {
  final doc =
      jsonDecode(File(_kVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final cases = [
    for (final c in (doc['cases']! as List).cast<Map<String, Object?>>())
      _Case(c),
  ];
  final directions = [
    for (final name in (doc['directions']! as List).cast<String>())
      TextDirection.values.byName(name),
  ];
  final tolerance = ((doc['tolerance']! as Map)['flutter']! as num).toDouble();
  final crossExtent = (doc['crossExtent']! as num).toDouble();
  final intrinsic = [
    for (final row in (doc['intrinsic']! as List).cast<Map<String, Object?>>())
      _Intrinsic(row),
  ];

  test('the vector table is not empty', () {
    expect(cases, isNotEmpty);
    expect(directions, [TextDirection.ltr, TextDirection.rtl]);
  });

  group('a labelled Divider against the shared vectors', () {
    for (final c in cases) {
      for (final direction in c.directions ?? directions) {
        testWidgets('${c.name} (${direction.name})', (tester) async {
          await pumpTestApp(
            tester,
            _divider(c, crossExtent),
            textDirection: direction,
          );

          // A label wider than the box is the one case the widget tree cannot
          // hold: `Row` / `Column` report the overflow and let the label run
          // past the end. Taking the report is part of the claim.
          final reported = tester.takeException();
          if (c.overflow) {
            expect(
              reported,
              isA<FlutterError>(),
              reason: 'the table says the label needs more than the box',
            );
          } else {
            expect(reported, isNull);
          }

          final box = tester.getRect(find.byType(Divider));
          final label = _fromStart(
            tester.getRect(find.byKey(_kLabelKey)),
            box,
            horizontal: c.horizontal,
            direction: direction,
          );
          expect(
            (label.start + label.end) / 2,
            closeTo(c.labelCentre, tolerance),
            reason: 'the label centre, from the start edge',
          );
          expect(
            label.end - label.start,
            closeTo(c.label, tolerance),
            reason: 'the label keeps its own length',
          );

          final lines = find.descendant(
            of: find.byType(Divider),
            matching: find.byType(ColoredBox),
          );
          expect(lines, findsNWidgets(2));
          final expected = c.lines;
          for (var i = 0; i < 2; i++) {
            final line = _fromStart(
              tester.getRect(lines.at(i)),
              box,
              horizontal: c.horizontal,
              direction: direction,
            );
            final lineRect = tester.getRect(lines.at(i));
            final labelRect = tester.getRect(find.byKey(_kLabelKey));
            expect(
              c.horizontal ? lineRect.center.dy : lineRect.center.dx,
              closeTo(
                c.horizontal ? labelRect.center.dy : labelRect.center.dx,
                tolerance,
              ),
              reason: 'segment $i is centred across the axis on the label',
            );
            final want = expected[i];
            if (want == null) {
              expect(
                line.end - line.start,
                closeTo(0, tolerance),
                reason: 'segment $i has no length',
              );
            } else {
              expect(
                line.start,
                closeTo(want.start, tolerance),
                reason: 'segment $i starts',
              );
              expect(
                line.end,
                closeTo(want.end, tolerance),
                reason: 'segment $i ends',
              );
            }
          }
        });
      }
    }
  });

  group('a labelled Divider whose parent takes its width from its content', () {
    // With no box to share, a weighted segment is as long as its inset allows
    // the other to be, so the label stays centred and the box holds the larger
    // inset on both sides.
    for (final row in intrinsic) {
      testWidgets(row.name, (tester) async {
        await pumpTestApp(
          tester,
          IntrinsicWidth(
            child: Divider(
              dividerStyle: CoreDividerStyle(
                indent: row.indent,
                endIndent: row.endIndent,
                childAlignment: row.alignment,
                childPadding: CoreEdgeInsets.symmetric(
                  horizontal: row.childPadding,
                ),
              ),
              child: SizedBox(
                key: _kLabelKey,
                width: row.label,
                height: crossExtent,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(Divider)).width,
          closeTo(row.width, tolerance),
        );
      });
    }
  });
}
