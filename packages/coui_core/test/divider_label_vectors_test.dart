// Where a labelled Divider puts its label and its two line segments — the
// vector table `divider_label_vectors.json` checked against the closed form of
// the layout rule it comes from.
//
// The rule: along the divider's main axis the child, with its padding, is the
// one part that keeps its own length. The two segments share what it leaves by
// the weights of `CoreDividerChildAlignment`, and a segment with no weight is
// only as long as its inset. Each inset is held *inside* its segment, so it
// shortens the line and takes nothing from the share: the label stays where
// the box puts it, at the centre for the default alignment, whatever the two
// insets are.
//
// Flutter lays the divider out that way (the segments are `Flexible`s that
// hold their own `Padding`) and `coui_flutter`'s widget test measures the
// rendered widget tree against the table. The Web states the same thing in CSS
// and a real-Chrome probe measures the DOM against the same table. This file
// pins the table itself: every row must be what the rule gives for its
// inputs, and the rows must cover what the divider is claimed to do — so a
// row cannot be typed to agree with whichever platform is being fixed.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The vector table shared with the Flutter widget test and the Chrome probe.
const String kDividerLabelVectorsPath =
    'test/fixtures/divider_label_vectors.json';

/// The box of the rows that leave the child room to spare.
const double _kRoomyBox = 320;

/// One row of the table.
class _Row {
  _Row(this.json);

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
  List<String>? get directions => (json['directions'] as List?)?.cast<String>();
  List<Map<String, Object?>?> get lines =>
      (json['lines']! as List).cast<Map<String, Object?>?>();
}

/// One row of the table's `intrinsic` section: a divider whose parent takes
/// its width from its content.
class _IntrinsicRow {
  _IntrinsicRow(this.json);

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

/// The length of a divider whose parent takes its width from its content.
///
/// With no box to share there is nothing to divide by weight: the child and
/// the segments with no weight keep their lengths, and the weighted segments
/// are as long as the least length that holds every inset at its weight — the
/// larger inset per unit of weight, times the weights together.
double _intrinsicWidth(_IntrinsicRow row) {
  final leadingWeight = row.alignment.leadingFlex;
  final trailingWeight = row.alignment.trailingFlex;
  final fixed =
      row.label +
      2 * row.childPadding +
      (leadingWeight == 0 ? row.indent : 0) +
      (trailingWeight == 0 ? row.endIndent : 0);
  var perWeight = 0.0;
  if (leadingWeight > 0) perWeight = row.indent / leadingWeight;
  if (trailingWeight > 0) {
    final share = row.endIndent / trailingWeight;
    if (share > perWeight) perWeight = share;
  }

  return fixed + perWeight * (leadingWeight + trailingWeight);
}

/// What the rule gives for [row]'s inputs: the child's centre, the two
/// segments (`null` where one has no length) and whether the child needs more
/// than the box, all along the axis from the box's start edge.
({double labelCentre, List<({double start, double end})?> lines, bool overflow})
_place(_Row row) {
  final leadingWeight = row.alignment.leadingFlex;
  final trailingWeight = row.alignment.trailingFlex;
  final padded = row.label + 2 * row.childPadding;

  // A segment with no weight is its inset and nothing more; the child and
  // those segments are what the weighted ones cannot take back.
  final fixed =
      padded +
      (leadingWeight == 0 ? row.indent : 0) +
      (trailingWeight == 0 ? row.endIndent : 0);
  final free = row.box > fixed ? row.box - fixed : 0.0;
  final weights = leadingWeight + trailingWeight;
  final leading = leadingWeight > 0
      ? free * leadingWeight / weights
      : row.indent;
  final trailing = trailingWeight > 0
      ? free * trailingWeight / weights
      : row.endIndent;

  // The inset sits inside the segment: the line is what the segment has
  // left after it, and a segment shorter than its inset has no line at all.
  ({double start, double end})? line(
    double segmentStart,
    double segmentLength,
    double inset, {
    required bool weighted,
    required bool insetFirst,
  }) {
    final length = segmentLength - inset;
    if (!weighted || length <= 0) return null;
    final start = insetFirst ? segmentStart + inset : segmentStart;

    return (start: start, end: start + length);
  }

  return (
    labelCentre: leading + row.childPadding + row.label / 2,
    lines: [
      line(
        0,
        leading,
        row.indent,
        weighted: leadingWeight > 0,
        insetFirst: true,
      ),
      line(
        leading + padded,
        trailing,
        row.endIndent,
        weighted: trailingWeight > 0,
        insetFirst: false,
      ),
    ],
    overflow: fixed > row.box,
  );
}

void main() {
  final doc =
      jsonDecode(File(kDividerLabelVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final rows = [
    for (final row in (doc['cases']! as List).cast<Map<String, Object?>>())
      _Row(row),
  ];
  final intrinsic = [
    for (final row in (doc['intrinsic']! as List).cast<Map<String, Object?>>())
      _IntrinsicRow(row),
  ];

  group('the table', () {
    test('has rows, and states the directions it holds in', () {
      expect(rows, isNotEmpty);
      expect((doc['directions']! as List).cast<String>(), ['ltr', 'rtl']);
    });

    test('bounds the Web to the half pixel the parity claim allows', () {
      final tolerance = doc['tolerance']! as Map<String, Object?>;

      expect(
        (tolerance['web']! as num).toDouble(),
        lessThanOrEqualTo(0.5),
        reason: 'the label and the lines agree within 0.5 px on both platforms',
      );
      expect(
        (tolerance['flutter']! as num).toDouble(),
        lessThanOrEqualTo((tolerance['web']! as num).toDouble()),
        reason: 'Flutter is the reference; it is held at least as tight',
      );
    });

    test('names every row once', () {
      expect({for (final row in rows) row.name}, hasLength(rows.length));
    });

    test('narrows a row to ltr exactly when the child overflows the box', () {
      // A child wider than the box makes Flutter report an overflow and
      // anchor the children at the physical left edge in rtl too, where CSS
      // anchors them at the start edge — the one place the platforms are
      // not asked to agree.
      for (final row in rows) {
        expect(
          row.directions,
          row.overflow ? ['ltr'] : isNull,
          reason: row.name,
        );
      }
    });
  });

  group('every row is what the layout rule gives for its inputs', () {
    for (final row in rows) {
      test(row.name, () {
        final placed = _place(row);

        expect(row.overflow, placed.overflow, reason: 'overflow');
        expect(
          row.labelCentre,
          closeTo(placed.labelCentre, 1e-9),
          reason: 'label centre',
        );
        for (var i = 0; i < 2; i++) {
          final want = placed.lines[i];
          final got = row.lines[i];
          if (want == null) {
            expect(got, isNull, reason: 'segment $i has no length');
          } else {
            expect(got, isNotNull, reason: 'segment $i has a length');
            expect(
              (got!['start']! as num).toDouble(),
              closeTo(want.start, 1e-9),
              reason: 'segment $i starts',
            );
            expect(
              (got['end']! as num).toDouble(),
              closeTo(want.end, 1e-9),
              reason: 'segment $i ends',
            );
          }
        }
      });
    }
  });

  group('the claim the rule makes', () {
    test('a centred label stays at the centre of the box whatever the insets '
        'are', () {
      // Insets taken out of the space the segments share would move the
      // label by half the difference between them.
      final centred = rows.where(
        (row) =>
            row.alignment == CoreDividerChildAlignment.center && !row.overflow,
      );

      expect(centred, isNotEmpty);
      for (final row in centred) {
        expect(row.labelCentre, closeTo(row.box / 2, 1e-9), reason: row.name);
      }
    });

    test('an inset only shortens its line', () {
      // Same box, same label, two insets: the segments are the same length,
      // the lines are not.
      _Row pick(double indent, double endIndent) => rows.singleWhere(
        (row) =>
            row.horizontal &&
            row.alignment == CoreDividerChildAlignment.center &&
            row.box == _kRoomyBox &&
            row.childPadding == CoreDividerStyle.defaultChildPadding.left &&
            row.indent == indent &&
            row.endIndent == endIndent,
      );
      final plain = pick(0, 0);
      final inset = pick(24, 8);

      expect(inset.labelCentre, plain.labelCentre);
      expect(inset.lines[0]!['end'], plain.lines[0]!['end']);
      expect(inset.lines[0]!['start'], 24);
      expect(inset.lines[1]!['start'], plain.lines[1]!['start']);
      expect(inset.lines[1]!['end'], _kRoomyBox - 8);
    });
  });

  group('every intrinsic row is what the layout rule gives', () {
    for (final row in intrinsic) {
      test(row.name, () {
        expect(row.width, closeTo(_intrinsicWidth(row), 1e-9));
      });
    }

    test('a centred label is held by the larger inset on both sides', () {
      // Whatever the two insets are, the box that holds them is as wide as
      // twice the larger one around the child: the label stays centred
      // because both segments are that long.
      for (final row in intrinsic.where(
        (row) => row.alignment == CoreDividerChildAlignment.center,
      )) {
        final larger = row.indent > row.endIndent ? row.indent : row.endIndent;

        expect(
          row.width,
          row.label + 2 * row.childPadding + 2 * larger,
          reason: row.name,
        );
      }
    });

    test('rows cover both alignments that collapse a segment', () {
      expect(
        intrinsic.map((row) => row.alignment).toSet(),
        CoreDividerChildAlignment.values.toSet(),
      );
    });
  });

  group('the rows cover what the divider is claimed to do', () {
    // Equal and unequal insets, each with and without padding around the
    // child, in the default alignment, in a box with room for the child.
    const insets = [
      (0.0, 0.0),
      (16.0, 16.0),
      (24.0, 8.0),
      (8.0, 24.0),
      (0.0, 40.0),
      (40.0, 0.0),
    ];
    final paddings = {0.0, CoreDividerStyle.defaultChildPadding.left, 24.0};

    for (final (indent, endIndent) in insets) {
      for (final padding in paddings) {
        test('horizontal, centre, indent ${indent.toInt()} / endIndent '
            '${endIndent.toInt()}, child padding ${padding.toInt()}', () {
          expect(
            rows.where(
              (row) =>
                  row.horizontal &&
                  row.alignment == CoreDividerChildAlignment.center &&
                  row.box == _kRoomyBox &&
                  row.indent == indent &&
                  row.endIndent == endIndent &&
                  row.childPadding == padding,
            ),
            hasLength(1),
          );
        });
      }

      test('vertical, centre, indent ${indent.toInt()} / endIndent '
          '${endIndent.toInt()}', () {
        expect(
          rows.where(
            (row) =>
                !row.horizontal &&
                row.alignment == CoreDividerChildAlignment.center &&
                row.indent == indent &&
                row.endIndent == endIndent,
          ),
          hasLength(1),
        );
      });
    }

    test('both alignments that collapse a segment, on both axes', () {
      for (final alignment in [
        CoreDividerChildAlignment.start,
        CoreDividerChildAlignment.end,
      ]) {
        for (final horizontal in [true, false]) {
          expect(
            rows.where(
              (row) =>
                  row.horizontal == horizontal && row.alignment == alignment,
            ),
            isNotEmpty,
            reason: '${alignment.name}, horizontal: $horizontal',
          );
        }
      }
    });

    test('a child that fits the box but not its insets', () {
      // The room the child leaves is smaller than the two insets together, so
      // the lines have no length and the label must still be at the centre.
      expect(
        rows.where(
          (row) =>
              row.horizontal &&
              !row.overflow &&
              row.box - (row.label + 2 * row.childPadding) <
                  row.indent + row.endIndent &&
              row.alignment == CoreDividerChildAlignment.center,
        ),
        isNotEmpty,
      );
    });

    test('a segment narrower than its own inset next to one that is not', () {
      expect(
        rows.where((row) {
          final lines = _place(row).lines;

          return row.horizontal &&
              row.alignment == CoreDividerChildAlignment.center &&
              (lines[0] == null) != (lines[1] == null);
        }),
        isNotEmpty,
      );
    });

    test('a child wider than the box', () {
      expect(rows.where((row) => row.overflow), isNotEmpty);
    });
  });
}
