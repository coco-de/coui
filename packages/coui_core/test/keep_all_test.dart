// CoreKeepAll decides where keep-all (CSS `word-break: keep-all`) removes a
// line-break opportunity. The Flutter `Text.keepAll` draws its display
// string; the Web `Text.keepAll` leaves the string to the CSS property. Both
// platform tests read the vector table this file pins to the Core
// definition, so a change to which pairs stay together fails everywhere.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The vector table shared with the Flutter and Web Text tests and the
/// Chrome line-break probe.
const String kKeepAllVectorsPath = 'test/fixtures/keep_all_vectors.json';

/// Renders the joiners visibly so a failing expectation reads at a glance.
String _visible(String text) => text.replaceAll(CoreKeepAll.wordJoiner, '⁀');

void main() {
  final doc =
      jsonDecode(File(kKeepAllVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final joins = (doc['joins']! as List).cast<Map<String, Object?>>();

  test('the vector table is not empty', () {
    expect(joins, isNotEmpty);
  });

  group('CoreKeepAll.join against the shared vectors', () {
    for (final c in joins) {
      final input = c['input']! as String;
      final expected = c['expected']! as String;
      test(c['name'], () {
        expect(_visible(CoreKeepAll.join(input)), _visible(expected));
      });
    }
  });

  group('CoreKeepAll.joinOffsets', () {
    test('marks exactly where join inserts, in source offsets', () {
      for (final c in joins) {
        final input = c['input']! as String;
        expect(
          CoreKeepAll.joinAt(input, CoreKeepAll.joinOffsets(input)),
          CoreKeepAll.join(input),
          reason: c['name']! as String,
        );
      }
    });

    test('offsets ascend and sit strictly inside the text', () {
      for (final c in joins) {
        final input = c['input']! as String;
        final offsets = CoreKeepAll.joinOffsets(input);
        for (var i = 0; i < offsets.length; i++) {
          expect(offsets[i], inExclusiveRange(0, input.length));
          if (i > 0) expect(offsets[i], greaterThan(offsets[i - 1]));
        }
      }
    });

    test('a joiner goes between clusters, never inside one', () {
      // 가나 written in conjoining jamo — two clusters of two code units.
      expect(CoreKeepAll.joinOffsets('\u1100\u1161\u1102\u1161'), [2]);
    });

    test('a character outside the BMP never joins — Chromium reads one '
        'UTF-16 code unit a side, and a surrogate is not a letter', () {
      expect(CoreKeepAll.joinOffsets('\u{20000}\u{20001}'), isEmpty);
      expect(CoreKeepAll.joinOffsets('가\u{20000}'), isEmpty);
      expect(CoreKeepAll.joinOffsets('\u{20000}가'), isEmpty);
    });
  });

  group('CoreKeepAll.join', () {
    test('is idempotent — a drawn string joins nothing more', () {
      for (final c in joins) {
        final once = CoreKeepAll.join(c['input']! as String);
        expect(
          _visible(CoreKeepAll.join(once)),
          _visible(once),
          reason: c['name']! as String,
        );
      }
    });

    test('removing every inserted joiner gives the source back', () {
      for (final c in joins) {
        final input = c['input']! as String;
        if (input.contains(CoreKeepAll.wordJoiner)) continue;
        expect(
          CoreKeepAll.join(input).replaceAll(CoreKeepAll.wordJoiner, ''),
          input,
          reason: c['name']! as String,
        );
      }
    });

    test('returns the same instance when nothing joins', () {
      const latin = 'Hello world';
      expect(identical(CoreKeepAll.join(latin), latin), isTrue);
    });
  });
}
