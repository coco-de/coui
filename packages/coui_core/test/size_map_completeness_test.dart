// A `Map<CoreComponentSize, …>` missing a size is a crash, not a gap.
//
// Every resolver reads these tables as `CoreXxxStyle.defaultsBySize[size]!`
// because a size ladder is supposed to be total over the enum. A missing
// row does not fall back to the nearest size; it throws a null-check error
// the first time anyone passes that size, on both platforms at once.
//
// Two components already assert this for themselves (`badge_style_test` and
// `text_field_style_test`). Nothing asserted it for the other tables in the
// tree, and a per-component test only protects the component someone
// remembered to write it for — which is the wrong shape for a rule about
// "every table". This reads the source instead, so a table added later is
// covered the day it lands.
//
// ─── Gaps that are decisions, not oversights ───────────────────────────
//
// A table may leave a size out only when that is a recorded decision, and
// the exclusion list below carries the reason next to each entry. An entry
// records that the fix needs a decision, not that a crash is acceptable —
// and when the decision lands, this list is the one place it shrinks.
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _contracts = 'lib/src/component/contracts';

/// Tables allowed to be missing a size, and why. Keyed
/// `component.mapName` → the size names that may be absent.
const _decidedExclusions = <String, Set<String>>{
  // Toggle 리디자인 (2026-09-09) — a 24×12 track cannot show its own
  // travel (8px), so the designer retired `xs`; both resolvers clamp it
  // to `sm` through `CoreToggleStyle.sizeDefaults`, so a caller still
  // renders, one rung up.
  'toggle.defaultsBySize': {'xs'},
  // Stat 리디자인 (#5832) — the library states `md` and the compact `sm`;
  // every other size reads through `resolveSizeRow`, which renders at the
  // nearest stated one (and asserts in debug), so a caller still renders.
  'stat.defaultsBySize': {'xs', 'lg', 'xl', 'xl2'},
  // StarRating 리디자인 (#5880) — the design copy states four star sizes
  // (sm 16 · md 20 · lg 24 · xl 32). `xs` and `xl2` read through
  // `resolveSizeRow`, which renders them at the nearest stated one.
  'star_rating.defaultsBySize': {'xs', 'xl2'},
  // ToggleGroup · Filter 리디자인 (#6016) — the design states the `md` bar
  // (40 track) and the `sm` bar (32 track) and no other. Both resolvers read
  // the table through `sizeDefaults`, which renders every other size at `md`,
  // so a caller still renders. Filter's table is the bar's own (reset button
  // height · hairline length) and follows the group's two rows.
  'toggle_group.defaultsBySize': {'xs', 'lg', 'xl', 'xl2'},
  'filter.defaultsBySize': {'xs', 'lg', 'xl', 'xl2'},
};

/// `component.mapName → size, size` for one gap of the failure message.
String _describeGap(MapEntry<String, List<String>> e) =>
    '${e.key} → ${e.value.join(", ")}';

/// The body of the brace-delimited block that starts at [openBrace].
String _blockAt(String source, int openBrace) {
  var depth = 0;
  for (var i = openBrace; i < source.length; i++) {
    if (source[i] == '{') depth++;
    if (source[i] == '}') {
      depth--;
      if (depth == 0) return source.substring(openBrace + 1, i);
    }
  }

  return source.substring(openBrace);
}

/// Every `Map<CoreComponentSize, …>` literal in the contracts tree, keyed
/// `component.mapName`, with the size names it actually lists.
Map<String, Set<String>> sizeMaps() {
  final dir = Directory(_contracts);
  if (!dir.existsSync()) {
    throw StateError(
      'run from packages/coui_core — $_contracts not found from '
      '${Directory.current.path}',
    );
  }

  // `static final`, not just `static const` — a table whose rungs
  // reference a non-const composite value (`.copyWith(...)` over a
  // `const` token, the `CoreTextFieldStyle.defaultsBySize` shape) can't
  // stay `const`, and that is a legitimate pattern for these tables, not
  // a different kind of table.
  final decl = RegExp(
    r'static\s+(?:const|final)\s+Map<\s*CoreComponentSize\s*,[^>]*>\s+(\w+)\s*=\s*\{',
  );
  final key = RegExp(r'CoreComponentSize\.(\w+)\s*:');

  final found = <String, Set<String>>{};
  for (final file in dir.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('_style.dart')) continue;
    final component = file.parent.path.split(Platform.pathSeparator).last;
    final source = file.readAsStringSync();
    for (final match in decl.allMatches(source)) {
      final body = _blockAt(source, match.end - 1);
      found['$component.${match.group(1)}'] = {
        for (final k in key.allMatches(body)) k.group(1)!,
      };
    }
  }

  return found;
}

void main() {
  group('every size ladder covers every size', () {
    final maps = sizeMaps();
    final sizes = CoreComponentSize.values.map((s) => s.name).toSet();

    // Without this the assertions below would pass by finding nothing —
    // a scan that stops matching after a refactor is how this class of
    // test dies without saying so.
    test('the scan finds the tables it is supposed to check', () {
      expect(maps, isNotEmpty);
      expect(
        maps.keys,
        containsAll(_decidedExclusions.keys),
        reason:
            'the excluded tables must still be found — otherwise the '
            'exclusion below silences a scan that is not looking at them',
      );
      expect(
        maps.keys,
        contains('text_field.defaultsBySize'),
        reason:
            'text_field has a full six-row ladder; if the scan misses it, '
            'the regex stopped matching rather than the tables changing',
      );
    });

    test('no table is missing a size it has not been excused from', () {
      final gaps = <String, List<String>>{};
      maps.forEach((name, keys) {
        final excused = _decidedExclusions[name] ?? const <String>{};
        final missing = sizes.difference(keys).difference(excused).toList()
          ..sort();
        if (missing.isNotEmpty) gaps[name] = missing;
      });

      expect(
        gaps,
        isEmpty,
        reason:
            'these tables are read as `defaultsBySize[size]!`, so a missing '
            'row throws rather than degrading: '
            '${gaps.entries.map(_describeGap).join(' · ')}',
      );
    });

    // An exclusion that stops being true should be deleted, not left
    // standing — otherwise the list grows into a place where a real gap
    // can hide behind a stale entry.
    test('every excused gap is still a gap', () {
      _decidedExclusions.forEach((name, excused) {
        final keys = maps[name] ?? const <String>{};
        for (final size in excused) {
          expect(
            keys,
            isNot(contains(size)),
            reason:
                '$name now has $size — remove it from _decidedExclusions '
                'so the next missing row is not excused by a stale entry',
          );
        }
      });
    });
  });
}
