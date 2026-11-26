// How tall a Dock bar is — the vector table `dock_bar_height_vectors.json`
// checked against the closed form of the sizing rule it comes from.
//
// The rule: `CoreDockStyle.height` is the bar's *minimum* height. The bar is as
// tall as its item row asks, plus the room it keeps above and below the row —
// its padding, never less than the active plate's reach — plus the line it
// draws around itself, on both edges — and never shorter than the minimum.
//
// Flutter sizes the bar with a min-height constraint over a content-sized
// stack, and `coui_flutter`'s widget test measures the rendered widget tree
// against the table. The Web states the same thing as `min-height` and
// padding, and a real-Chrome probe measures the DOM against the same table.
// This file pins the table itself: every row must be what the rule gives for
// its inputs, and the rows must reach the places where the rule changes its
// answer — so a row cannot be typed to agree with whichever platform is being
// fixed.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The vector table shared with the Flutter widget test and the Chrome probe.
const String kDockBarHeightVectorsPath =
    'test/fixtures/dock_bar_height_vectors.json';

/// One row of the table.
class _Row {
  _Row(this.json);

  final Map<String, Object?> json;

  String get name => json['name']! as String;
  CoreDockSize get size => CoreDockSize.values.byName(json['size']! as String);
  double get iconSize => (json['iconSize']! as num).toDouble();
  double get bar => (json['bar']! as num).toDouble();

  CoreEdgeInsets? _vertical(String key) {
    final padding = json[key] as Map<String, Object?>?;
    if (padding == null) return null;

    return CoreEdgeInsets.only(
      top: (padding['top']! as num).toDouble(),
      bottom: (padding['bottom']! as num).toDouble(),
    );
  }

  /// The plate padding the row states, or the size's where it does not.
  CoreEdgeInsets get indicatorPadding =>
      _vertical('indicatorPadding') ??
      CoreDockStyle.defaultsBySize[size]!.indicatorPadding!;

  /// The bar padding the row states, or the size's where it does not.
  CoreEdgeInsets get padding =>
      _vertical('padding') ?? CoreDockStyle.defaultsBySize[size]!.padding!;

  bool get statesIndicatorPadding => json['indicatorPadding'] != null;
  bool get statesPadding => json['padding'] != null;
}

/// The minimum height Core states for the row's size.
double _minimum(_Row row) => CoreDockStyle.defaultsBySize[row.size]!.height!;

/// What the row's content asks of the bar: the icon, the room kept above and
/// below it, and the line on both edges.
double _asked(_Row row, {required double border}) {
  final top = CoreDockStyle.rowInsetFor(row.padding.top, row.indicatorPadding);
  final bottom = CoreDockStyle.rowInsetFor(
    row.padding.bottom,
    row.indicatorPadding,
  );

  return row.iconSize + top + bottom + 2 * border;
}

/// The bar's height by the rule, from the row's inputs.
double _ruleBar(_Row row, {required double border}) {
  final asked = _asked(row, border: border);
  final minimum = _minimum(row);

  return asked > minimum ? asked : minimum;
}

void main() {
  final doc =
      jsonDecode(File(kDockBarHeightVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final border = (doc['border']! as num).toDouble();
  final rows = [
    for (final row in (doc['cases']! as List).cast<Map<String, Object?>>())
      _Row(row),
  ];

  test('the table is not empty and states a line of one px', () {
    expect(rows, isNotEmpty);
    expect(border, 1);
  });

  group('every row is what the rule gives for its inputs', () {
    for (final row in rows) {
      test(row.name, () {
        expect(row.bar, _ruleBar(row, border: border));
      });
    }
  });

  group('the rows reach the places the rule changes its answer', () {
    test('every size has a row where its own minimum is the bar', () {
      for (final size in CoreDockSize.values) {
        expect(
          rows.any((row) => row.size == size && row.bar == _minimum(row)),
          isTrue,
          reason: '${size.name} never sits at its minimum in the table',
        );
      }
    });

    test('rows where the row governs', () {
      expect(rows.any((row) => row.bar > _minimum(row)), isTrue);
    });

    test("the plate's reach is what tips a bar past its minimum", () {
      // An item that fits the bar with the padding alone yet makes it grow
      // once the plate's reach is counted: without these rows a bar sized to
      // its padding alone passes the table.
      final tipped = rows.where((row) {
        final alone =
            row.iconSize + row.padding.top + row.padding.bottom + 2 * border;

        return alone <= _minimum(row) && row.bar > _minimum(row);
      });
      expect(tipped, isNotEmpty);
    });

    test("the plate's reach is the room where there is no padding", () {
      expect(
        rows.any((row) => row.statesPadding && row.padding.top == 0),
        isTrue,
      );
    });

    test('rows exactly at the edge, and one px past it', () {
      // The comparison is `>`, not `>=`, and an off-by-one in either
      // direction moves one of the pair: a row whose content asks exactly
      // the minimum (the bar stays), and one that asks one px more (it grows).
      expect(
        rows.any((row) => _asked(row, border: border) == _minimum(row)),
        isTrue,
      );
      expect(
        rows.any(
          (row) => _asked(row, border: border) == _minimum(row) + 1,
        ),
        isTrue,
      );
    });

    test('unequal vertical padding, both ways round, and none at all', () {
      final stated = rows.where((row) => row.statesIndicatorPadding).toList();
      expect(
        stated.any(
          (row) => row.indicatorPadding.top < row.indicatorPadding.bottom,
        ),
        isTrue,
      );
      expect(
        stated.any(
          (row) => row.indicatorPadding.top > row.indicatorPadding.bottom,
        ),
        isTrue,
      );
      expect(
        stated.any(
          (row) =>
              row.indicatorPadding.top == 0 && row.indicatorPadding.bottom == 0,
        ),
        isTrue,
      );
    });
  });

  group('the room kept for the pill', () {
    test('is the larger vertical padding, on both edges', () {
      expect(
        CoreDockStyle.indicatorClearanceFor(
          const CoreEdgeInsets.only(top: 4, bottom: 12),
        ),
        12,
      );
      expect(
        CoreDockStyle.indicatorClearanceFor(
          const CoreEdgeInsets.only(top: 12, bottom: 4),
        ),
        12,
      );
    });

    test('ignores the horizontal padding', () {
      expect(
        CoreDockStyle.indicatorClearanceFor(
          const CoreEdgeInsets.symmetric(horizontal: 40, vertical: 2),
        ),
        2,
      );
    });

    test('is nothing for a pill with no vertical padding', () {
      expect(CoreDockStyle.indicatorClearanceFor(CoreEdgeInsets.zero), 0);
    });

    test("is the size's plate reach by default: 3 at xs and sm, 5 from md", () {
      expect(
        {
          for (final size in CoreDockSize.values)
            size: CoreDockStyle.indicatorClearanceFor(
              CoreDockStyle.defaultsBySize[size]!.indicatorPadding!,
            ),
        },
        {
          CoreDockSize.xs: 3,
          CoreDockSize.sm: 3,
          CoreDockSize.md: 5,
          CoreDockSize.lg: 5,
          CoreDockSize.xl: 5,
        },
      );
    });
  });

  group('the room above and below the row', () {
    test('is the padding where it is the larger', () {
      expect(
        CoreDockStyle.rowInsetFor(10, const CoreEdgeInsets.only(top: 5)),
        10,
      );
    });

    test("is the plate's reach where that is the larger", () {
      expect(
        CoreDockStyle.rowInsetFor(2, const CoreEdgeInsets.only(bottom: 7)),
        7,
      );
    });

    test("is the size's padding by default: 6 at xs and sm, 10 from md", () {
      expect(
        {
          for (final size in CoreDockSize.values)
            size: CoreDockStyle.rowInsetFor(
              CoreDockStyle.defaultsBySize[size]!.padding!.top,
              CoreDockStyle.defaultsBySize[size]!.indicatorPadding!,
            ),
        },
        {
          CoreDockSize.xs: 6,
          CoreDockSize.sm: 6,
          CoreDockSize.md: 10,
          CoreDockSize.lg: 10,
          CoreDockSize.xl: 10,
        },
      );
    });
  });
}
