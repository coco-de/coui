// CoreDialogActionsStretch places the actions of a stretched Dialog actions
// row (CoreDialogActionsLayout.stretch). The Flutter render object lays the
// row out with it; the Web states the same row in CSS and a real-Chrome probe
// checks the browser against the vector table this file pins to the Core
// definition, so a change to where an action lands fails everywhere.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The vector table shared with the Flutter Dialog test and the Chrome
/// footer probe.
const String kDialogActionsStretchVectorsPath =
    'test/fixtures/dialog_actions_stretch_vectors.json';

/// An action built from parts laid side by side that wrap between them: its
/// narrowest width is its widest part, its natural width is their sum.
CoreDialogStretchAction _actionOf(List<num> parts) {
  var widest = 0.0;
  var sum = 0.0;
  for (final part in parts) {
    final width = part.toDouble();
    if (width > widest) widest = width;
    sum += width;
  }

  return CoreDialogStretchAction(minWidth: widest, maxWidth: sum);
}

void main() {
  final doc =
      jsonDecode(File(kDialogActionsStretchVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final spacing = (doc['spacing']! as num).toDouble();
  final cases = (doc['cases']! as List).cast<Map<String, Object?>>();

  test('the vector table is not empty', () {
    expect(cases, isNotEmpty);
  });

  test('the table is spaced the way the Dialog spaces its actions', () {
    expect(spacing, CoreDialogStyle.defaultActionSpacing);
    expect(
      (doc['runSpacing']! as num).toDouble(),
      CoreDialogStyle.defaultActionRunSpacing,
    );
  });

  group('CoreDialogActionsStretch.place against the shared vectors', () {
    for (final c in cases) {
      test(c['name'], () {
        final actions = [
          for (final a in (c['actions']! as List).cast<Map<String, Object?>>())
            _actionOf((a['parts']! as List).cast<num>()),
        ];
        final cells = CoreDialogActionsStretch.place(
          width: (c['width']! as num).toDouble(),
          spacing: spacing,
          actions: actions,
        );
        final expected = (c['cells']! as List).cast<Map<String, Object?>>();
        expect(cells, hasLength(expected.length));
        for (var i = 0; i < cells.length; i++) {
          final e = expected[i];
          expect(cells[i].line, e['line'], reason: 'action $i line');
          expect(
            cells[i].start,
            closeTo((e['start']! as num).toDouble(), 1e-4),
            reason: 'action $i start',
          );
          expect(
            cells[i].width,
            closeTo((e['width']! as num).toDouble(), 1e-4),
            reason: 'action $i width',
          );
        }
      });
    }
  });

  group('CoreDialogActionsStretch.place', () {
    const short = CoreDialogStretchAction(minWidth: 60, maxWidth: 60);

    test('places nothing for no actions', () {
      expect(
        CoreDialogActionsStretch.place(width: 300, spacing: 8, actions: []),
        isEmpty,
      );
    });

    test('every line fills the row exactly', () {
      for (final width in [100.0, 200.0, 311.3, 640.0]) {
        for (var count = 1; count <= 4; count++) {
          final cells = CoreDialogActionsStretch.place(
            width: width,
            spacing: 8,
            actions: List.filled(count, short),
          );
          final lines = <int, List<CoreDialogStretchCell>>{};
          for (final cell in cells) {
            (lines[cell.line] ??= []).add(cell);
          }
          for (final line in lines.values) {
            var taken = 8.0 * (line.length - 1);
            for (final cell in line) {
              taken += cell.width;
            }
            expect(taken, closeTo(width, 1e-9), reason: '$count at $width');
            expect(line.first.start, closeTo(0, 1e-9));
          }
        }
      }
    });

    test('keeps the order the actions were handed in', () {
      final cells = CoreDialogActionsStretch.place(
        width: 200,
        spacing: 8,
        actions: const [
          CoreDialogStretchAction(minWidth: 120, maxWidth: 120),
          CoreDialogStretchAction(minWidth: 120, maxWidth: 120),
        ],
      );
      expect([for (final c in cells) c.line], [0, 1]);
    });

    test('a stated spacing moves the cells, not the row', () {
      final cells = CoreDialogActionsStretch.place(
        width: 300,
        spacing: 20,
        actions: const [short, short],
      );
      expect(cells[0].width, 140);
      expect(cells[1].start, 160);
    });
  });
}
