// The rule a navigation bar follows scrolling content by
// (`CoreNavigationCompact.onScroll`): pure, and shared by the two seats that
// feed it. The table in `test/fixtures/navigation_scroll_compaction_vectors.json`
// pins it for all three packages; this file replays that table on the pure
// type and holds what a table row cannot — that the table is one content's
// consecutive positions, and the cases a consistent trace cannot state.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const String kNavigationScrollCompactionVectorsPath =
    'test/fixtures/navigation_scroll_compaction_vectors.json';

Map<String, Object?> _vectors() =>
    jsonDecode(File(kNavigationScrollCompactionVectorsPath).readAsStringSync())
        as Map<String, Object?>;

List<Map<String, Object?>> _list(Object? value) =>
    (value! as List).cast<Map<String, Object?>>();

void main() {
  final vectors = _vectors();
  final traces = _list(vectors['traces']);

  test('the table restates the travel', () {
    expect(vectors['travel'], CoreNavigationScrollCompaction.travel);
  });

  test("every trace is one content's consecutive positions", () {
    // The Web seat works each delta out from the offsets; a row whose delta
    // is not the difference from the row before would replay differently
    // there.
    for (final trace in traces) {
      double? previous;
      for (final step in _list(trace['steps'])) {
        if (step['event'] != null) continue;
        final offset = (step['offset']! as num).toDouble();
        final delta = (step['delta']! as num).toDouble();
        expect(
          delta,
          previous == null ? 0 : offset - previous,
          reason: '${trace['name']} at offset $offset',
        );
        previous = offset;
      }
    }
  });

  group('the shared table', () {
    for (final trace in traces) {
      test(trace['name']! as String, () {
        final compaction = CoreNavigationScrollCompaction();
        final maxExtent = (trace['maxExtent']! as num).toDouble();
        for (final step in _list(trace['steps'])) {
          if (step['event'] == 'reset') {
            compaction.reset();
          } else {
            compaction.update(
              offset: (step['offset']! as num).toDouble(),
              delta: (step['delta']! as num).toDouble(),
              maxExtent: maxExtent,
            );
          }
          expect(compaction.compact, step['compact'], reason: '$step');
        }
      });
    }
  });

  test('starts in full', () {
    expect(CoreNavigationScrollCompaction().compact, isFalse);
  });

  test('content moved to its start without a delta returns the bar', () {
    // A jump the platform reports with no distance — the content was sent to
    // its top.
    final compaction = CoreNavigationScrollCompaction()
      ..update(offset: 400, delta: 400, maxExtent: 2000);
    expect(compaction.compact, isTrue);
    expect(
      compaction.update(offset: 0, delta: 0, maxExtent: 2000),
      isFalse,
    );
  });

  test('the start is where the content says it is', () {
    // Content whose start is not offset 0: at -200 it is at its start, and
    // 12 from inside it counts.
    final compaction = CoreNavigationScrollCompaction();
    expect(
      compaction.update(
        offset: -200,
        delta: 0,
        minExtent: -200,
        maxExtent: 2000,
      ),
      isFalse,
    );
    expect(
      compaction.update(
        offset: -188,
        delta: 12,
        minExtent: -200,
        maxExtent: 2000,
      ),
      isTrue,
    );
  });

  test('the default asks for no compact form', () {
    expect(CoreNavigationCompact.defaultCompact, CoreNavigationCompact.never);
  });

  group("the compact form is the style's", () {
    test('a docked bar has none and the floating glass bar shrinks', () {
      expect(CoreNavigationBarStyle.defaultCompactScale, 1);
      expect(
        CoreNavigationBarStyle.glassBarStyle.compactScale,
        CoreNavigationBarStyle.glassCompactScale,
      );
      expect(CoreNavigationBarStyle.glassCompactScale, lessThan(1));
      // Having a form is what drops the captions too, and both platforms
      // ask the same question.
      expect(CoreNavigationBarStyle.hasCompactForm(1), isFalse);
      expect(
        CoreNavigationBarStyle.hasCompactForm(
          CoreNavigationBarStyle.glassCompactScale,
        ),
        isTrue,
      );
      // The rail's capsule states none: where it shrinks toward is its
      // shell's to say.
      expect(CoreNavigationBarStyle.glassRailStyle.compactScale, isNull);
    });

    test('the two fields take part in merge, copyWith and equality', () {
      const base = CoreNavigationBarStyle(
        compactScale: .9,
        compactDuration: Duration(milliseconds: 200),
      );
      expect(const CoreNavigationBarStyle().merge(base), base);
      expect(
        base.merge(const CoreNavigationBarStyle(compactScale: .8)),
        const CoreNavigationBarStyle(
          compactScale: .8,
          compactDuration: Duration(milliseconds: 200),
        ),
      );
      expect(
        const CoreNavigationBarStyle().copyWith(
          compactScale: .9,
          compactDuration: const Duration(milliseconds: 200),
        ),
        base,
      );
      expect(base, isNot(const CoreNavigationBarStyle(compactScale: .9)));
      expect(
        base.hashCode,
        isNot(const CoreNavigationBarStyle(compactScale: .9).hashCode),
      );
    });
  });
}
