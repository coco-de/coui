@TestOn('vm')
library;

import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart' show CoreButtonStyle;
import 'package:test/test.dart';

/// Holds the Button page's size-ladder table to the ladder it describes.
///
/// The ladder lives in one place, `CoreButtonStyle.defaultsBySize`. A copy of
/// it in prose drifts: the Core doc comment once read
/// "xs=4 / sm=6 / md=8 / lg=8 / xl=10" while the rows said 4 · 4 · 8 · 8 ·
/// 12 · 12, and nothing noticed because nothing compared them. That comment
/// no longer restates the numbers; this table still does — for readers — so
/// it is the copy that has to be checked.
///
/// What this does **not** check: the label column. A role name is prose, and
/// the role ladder has its own gate in the size-ladder guard.
void main() {
  final file = File('content/components/button.md');

  /// `size → (height, padding-x, gap, icon, icon of a square · circle)` as
  /// the page's table states them.
  Map<String, (double, double, double, double, double)> tableRows() {
    final lines = file.readAsLinesSync();
    final start = lines.indexWhere(
      (l) => l.startsWith('### 사이즈 래더 — padding-x · gap'),
    );
    expect(start, isNot(-1), reason: 'size-ladder section heading moved');
    final row = RegExp(
      r'^\| `(\w+)` \| (\d+) \| (\d+) \| (\d+) \| [^|]+ \| (\d+) \| (\d+) \|',
    );
    final rows = <String, (double, double, double, double, double)>{};
    for (final line in lines.skip(start + 1)) {
      if (line.startsWith('#')) break;
      final m = row.firstMatch(line);
      if (m == null) continue;
      rows[m.group(1)!] = (
        double.parse(m.group(2)!),
        double.parse(m.group(3)!),
        double.parse(m.group(4)!),
        double.parse(m.group(5)!),
        double.parse(m.group(6)!),
      );
    }
    return rows;
  }

  /// A v2 page (`template: v2`) draws its size table with `<SizeSpec>`,
  /// which builds every row from `CoreButtonStyle.defaultsBySize`
  /// (`docs_core/lib/shared/size_spec.dart`, held by `size_spec_test`). There
  /// is no copy left to drift — what this file still has to hold is that the
  /// page uses that block and has not grown a hand-written ladder beside it.
  bool isV2() => RegExp(
    r'^template:\s*v2\s*$',
    multiLine: true,
  ).hasMatch(file.readAsStringSync());

  test('a v2 page draws the ladder from Core rather than restating it', () {
    expect(file.existsSync(), isTrue);
    if (!isV2()) return;
    final source = file.readAsStringSync();
    expect(
      source,
      contains('<SizeSpec component="button"'),
      reason: 'the v2 page lost the block that builds the size table',
    );
    expect(
      source.contains('### 사이즈 래더 — padding-x · gap'),
      isFalse,
      reason: 'a hand-written ladder table came back beside <SizeSpec>',
    );
  });

  test('every size row matches CoreButtonStyle.defaultsBySize', () {
    expect(file.existsSync(), isTrue);
    // The v2 page has no hand-written table to compare — see above.
    if (isV2()) return;
    final rows = tableRows();
    final ladder = CoreButtonStyle.defaultsBySize;

    expect(
      rows.keys.toSet(),
      ladder.keys.map((s) => s.name).toSet(),
      reason: 'the table and the ladder list different sizes',
    );
    for (final MapEntry(key: size, value: style) in ladder.entries) {
      final (height, paddingX, gap, icon, iconShape) = rows[size.name]!;
      expect(height, style.height, reason: '${size.name} height');
      expect(paddingX, style.padding!.left, reason: '${size.name} padding-x');
      expect(
        gap,
        style.iconLabelGapStyle!.size,
        reason: '${size.name} icon↔label gap',
      );
      expect(icon, style.leadingIconStyle!.size, reason: '${size.name} icon');
      expect(
        icon,
        style.trailingIconStyle!.size,
        reason: '${size.name} trailing icon',
      );
      expect(
        iconShape,
        style.iconShapeIconStyle!.size,
        reason: '${size.name} icon (square · circle)',
      );
    }
  });
}
