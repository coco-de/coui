// CoreOverlayFit holds a floating panel to the room the viewport leaves it.
// Flutter's popover engine caps its panels with `availableExtent` before it
// lays them out; the Web positioner measures the panel and asks `fit`. Both
// read the vector table this file pins to the Core definition, so a change to
// the room a panel gets, or to where an over-tall one sits, fails everywhere.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The vector table shared with the Flutter popover-engine test and the
/// Chrome panel probe.
const String kOverlayFitVectorsPath = 'test/fixtures/overlay_fit_vectors.json';

double _n(Map<String, Object?> map, String key) =>
    (map[key]! as num).toDouble();

void main() {
  final doc =
      jsonDecode(File(kOverlayFitVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final cases = (doc['cases']! as List).cast<Map<String, Object?>>();

  test('the vector table is not empty', () {
    expect(cases, isNotEmpty);
  });

  test('the table covers a fitting panel, a capped one and no room at all', () {
    final fits = [
      for (final c in cases) (c['fit']! as Map<String, Object?>)['capped'],
    ];
    expect(fits, contains(true));
    expect(fits, contains(false));
    expect(
      cases.any((c) => (c['room']! as num) == 0),
      isTrue,
      reason: 'paddings that leave no room are a case of their own',
    );
  });

  group('CoreOverlayFit against the shared vectors', () {
    for (final c in cases) {
      test(c['name']! as String, () {
        final viewport = _n(c, 'viewport');
        final before = _n(c, 'paddingBefore');
        final after = _n(c, 'paddingAfter');

        expect(
          CoreOverlayFit.availableExtent(
            viewport: viewport,
            paddingBefore: before,
            paddingAfter: after,
          ),
          closeTo(_n(c, 'room'), 1e-9),
          reason: 'the room',
        );

        final fit = c['fit']! as Map<String, Object?>;
        final result = CoreOverlayFit.fit(
          viewport: viewport,
          paddingBefore: before,
          paddingAfter: after,
          start: _n(c, 'start'),
          extent: _n(c, 'extent'),
        );
        expect(result.capped, fit['capped'], reason: 'capped');
        expect(result.start, closeTo(_n(fit, 'start'), 1e-9), reason: 'start');
        expect(
          result.extent,
          closeTo(_n(fit, 'extent'), 1e-9),
          reason: 'extent',
        );
      });
    }
  });

  group('CoreOverlayFit', () {
    test('never reports a negative room', () {
      expect(
        CoreOverlayFit.availableExtent(
          viewport: 10,
          paddingBefore: 8,
          paddingAfter: 8,
        ),
        0,
      );
    });

    test('a capped panel always lies inside the paddings', () {
      for (final viewport in [120.0, 480.0, 844.0, 1080.0]) {
        for (final (before, after) in [(0.0, 0.0), (8.0, 8.0), (55.0, 42.0)]) {
          final result = CoreOverlayFit.fit(
            viewport: viewport,
            paddingBefore: before,
            paddingAfter: after,
            start: 0,
            extent: 10000,
          );
          expect(result.capped, isTrue);
          expect(result.start, greaterThanOrEqualTo(before));
          expect(
            result.start + result.extent,
            lessThanOrEqualTo(viewport - after + 1e-9),
            reason: '$viewport / $before / $after',
          );
        }
      }
    });

    test('a panel that fits is returned untouched', () {
      final result = CoreOverlayFit.fit(
        viewport: 480,
        paddingBefore: 8,
        paddingAfter: 8,
        start: 123.5,
        extent: 77.25,
      );
      expect(
        result,
        const CoreOverlayFitResult(start: 123.5, extent: 77.25, capped: false),
      );
    });

    test('results compare by value', () {
      const a = CoreOverlayFitResult(start: 1, extent: 2, capped: true);
      const b = CoreOverlayFitResult(start: 1, extent: 2, capped: true);
      const c = CoreOverlayFitResult(start: 1, extent: 2, capped: false);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
      expect(a.toString(), contains('capped: true'));
    });
  });
}
