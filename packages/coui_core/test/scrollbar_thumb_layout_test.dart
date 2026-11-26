// CoreScrollbarThumbLayout is where a Scrollbar thumb sits along its track.
// Web draws the thumb itself and runs this code; Flutter's ScrollbarPainter
// paints it, and its test asks the painter the questions this file asks of
// Core. Both read one table, so a change to either side fails the other.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The vector table shared with the Web overlay test and the Flutter painter
/// test.
const String kScrollbarThumbVectorsPath =
    'test/fixtures/scrollbar_thumb_vectors.json';

CoreScrollbarThumbLayout? _layoutOf(Map<String, Object?> c) =>
    CoreScrollbarThumbLayout.of(
      viewportExtent: (c['viewport']! as num).toDouble(),
      contentExtent: (c['content']! as num).toDouble(),
      scrollOffset: (c['scrollOffset']! as num).toDouble(),
      margin: (c['margin']! as num).toDouble(),
      minLength: (c['minLength']! as num).toDouble(),
    );

void main() {
  final doc =
      jsonDecode(File(kScrollbarThumbVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final tolerance = (doc['tolerance']! as num).toDouble();
  final cases = (doc['cases']! as List).cast<Map<String, Object?>>();

  test('the vector table is not empty', () {
    expect(cases, isNotEmpty);
  });

  test('the table covers a thumb and the absence of one', () {
    expect(cases.any((c) => c['expected'] == null), isTrue);
    expect(cases.any((c) => c['expected'] != null), isTrue);
  });

  group('CoreScrollbarThumbLayout.of against the shared vectors', () {
    for (final c in cases) {
      test(c['name']! as String, () {
        final layout = _layoutOf(c);
        final expected = c['expected'] as Map<String, Object?>?;
        if (expected == null) {
          expect(layout, isNull);

          return;
        }
        expect(layout, isNotNull);
        expect(
          layout!.extent,
          closeTo((expected['extent']! as num).toDouble(), tolerance),
        );
        expect(
          layout.offset,
          closeTo((expected['offset']! as num).toDouble(), tolerance),
        );
      });
    }
  });

  group('out-of-range positions', () {
    CoreScrollbarThumbLayout at(double scrollOffset) =>
        CoreScrollbarThumbLayout.of(
          viewportExtent: 160,
          contentExtent: 560,
          scrollOffset: scrollOffset,
          margin: 2,
          minLength: 48,
        )!;

    test('past the end the thumb rests at the end of its track', () {
      expect(at(9999).offset, at(400).offset);
    });

    test('before the start the thumb rests at the start of its track', () {
      expect(at(-50).offset, at(0).offset);
    });

    test('a non-finite input draws no thumb', () {
      for (final bad in [double.nan, double.infinity]) {
        expect(
          CoreScrollbarThumbLayout.of(
            viewportExtent: 160,
            contentExtent: bad,
            scrollOffset: 0,
            margin: 2,
            minLength: 48,
          ),
          isNull,
        );
        expect(
          CoreScrollbarThumbLayout.of(
            viewportExtent: 160,
            contentExtent: 560,
            scrollOffset: bad,
            margin: 2,
            minLength: 48,
          ),
          isNull,
        );
      }
    });
  });

  group('dragging the thumb', () {
    // 160 viewport over 560 content: the thumb is 48 long and travels 108
    // along a 156 track, while the content scrolls 400.
    final layout = CoreScrollbarThumbLayout.of(
      viewportExtent: 160,
      contentExtent: 560,
      scrollOffset: 0,
      margin: 2,
      minLength: 48,
    )!;

    test('travel is the track less the thumb', () {
      expect(layout.travel, 108);
      expect(layout.scrollableExtent, 400);
    });

    test('a thumb delta maps to proportionally more content', () {
      // 27px of 108 is a quarter of the way; a quarter of 400 is 100.
      expect(
        layout.scrollOffsetAfterDrag(fromScrollOffset: 0, thumbDelta: 27),
        closeTo(100, 1e-9),
      );
    });

    test('a drag adds to where the content already was', () {
      expect(
        layout.scrollOffsetAfterDrag(fromScrollOffset: 100, thumbDelta: 27),
        closeTo(200, 1e-9),
      );
    });

    test('dragging back moves the content back', () {
      expect(
        layout.scrollOffsetAfterDrag(fromScrollOffset: 200, thumbDelta: -27),
        closeTo(100, 1e-9),
      );
    });

    test('a drag past either end stays inside the scrollable range', () {
      expect(
        layout.scrollOffsetAfterDrag(fromScrollOffset: 0, thumbDelta: 9999),
        400,
      );
      expect(
        layout.scrollOffsetAfterDrag(fromScrollOffset: 0, thumbDelta: -9999),
        0,
      );
    });

    test('a thumb with no room to move leaves the position alone', () {
      final fills = CoreScrollbarThumbLayout.of(
        viewportExtent: 60,
        contentExtent: 400,
        scrollOffset: 0,
        margin: 2,
        minLength: 100,
      )!;
      expect(fills.travel, 0);
      expect(
        fills.scrollOffsetAfterDrag(fromScrollOffset: 30, thumbDelta: 50),
        30,
      );
    });
  });

  group('tapping the track', () {
    final layout = CoreScrollbarThumbLayout.of(
      viewportExtent: 300,
      contentExtent: 2300,
      scrollOffset: 600,
      margin: 2,
      minLength: 48,
    )!;
    const page = CoreScrollbarContract.trackTapPageFraction;

    test('a page is 80% of the viewport', () {
      expect(page, 0.8);
    });

    test('a tap beyond the thumb pages forward', () {
      expect(
        layout.scrollOffsetAfterTrackTap(
          fromScrollOffset: 600,
          trackOffset: layout.offset + layout.extent + 20,
          viewportExtent: 300,
          pageFraction: page,
        ),
        closeTo(840, 1e-9),
      );
    });

    test('a tap before the thumb pages backward', () {
      expect(
        layout.scrollOffsetAfterTrackTap(
          fromScrollOffset: 600,
          trackOffset: layout.offset - 20,
          viewportExtent: 300,
          pageFraction: page,
        ),
        closeTo(360, 1e-9),
      );
    });

    test('a page never leaves the scrollable range', () {
      expect(
        layout.scrollOffsetAfterTrackTap(
          fromScrollOffset: 1900,
          trackOffset: 299,
          viewportExtent: 300,
          pageFraction: page,
        ),
        2000,
      );
      expect(
        layout.scrollOffsetAfterTrackTap(
          fromScrollOffset: 100,
          trackOffset: 0,
          viewportExtent: 300,
          pageFraction: page,
        ),
        0,
      );
    });
  });

  group('the contract timings Web and Flutter share', () {
    test('a track page eases over 100ms', () {
      expect(CoreScrollbarContract.trackTapDurationMs, 100);
    });

    test('the hover look moves over 200ms', () {
      expect(CoreScrollbarContract.hoverTransitionMs, 200);
    });
  });

  test('equal layouts compare equal', () {
    CoreScrollbarThumbLayout? build() => CoreScrollbarThumbLayout.of(
      viewportExtent: 160,
      contentExtent: 560,
      scrollOffset: 10,
      margin: 2,
      minLength: 48,
    );
    expect(build(), build());
    expect(build().hashCode, build().hashCode);
  });
}
