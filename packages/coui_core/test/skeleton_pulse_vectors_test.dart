// The Skeleton pulse ends are the fill scaled by `CoreColor.scaleAlpha` —
// the one composition Flutter, Web and the Figma builder share. These
// vectors are the numbers both platform tests compare their output against;
// this file pins them to the Core definition they come from.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The vector table shared with the Flutter and Web Skeleton tests.
const String kSkeletonPulseVectorsPath =
    'test/fixtures/skeleton_pulse_vectors.json';

/// The tokens the vector table names — `CoreColors` has no lookup by name.
const Map<String, CoreColorToken> _kTokens = {'primary': CoreColors.primary};

const double _kTolerance = 1e-9;

void main() {
  final doc =
      jsonDecode(File(kSkeletonPulseVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final cases = (doc['cases']! as List).cast<Map<String, Object?>>();

  test('the vector table is not empty', () {
    expect(cases, isNotEmpty);
  });

  test('the first vector states the Core default pulse ends', () {
    // The variant-default case is the one the platform tests read as "what an
    // unstyled Skeleton does"; every other case passes its own opacities, so
    // without this nothing ties the table to `defaultFromOpacity`.
    expect(
      (cases.first['fromOpacity']! as num).toDouble(),
      CoreSkeletonStyle.defaultFromOpacity,
    );
    expect(
      (cases.first['toOpacity']! as num).toDouble(),
      CoreSkeletonStyle.defaultToOpacity,
    );
  });

  final timelines =
      ((doc['timelines']! as Map<String, Object?>)['cases']! as List)
          .cast<Map<String, Object?>>();

  group('timeline', () {
    test('the default case is the Core default — one 2 s pulse, move', () {
      final c = timelines.firstWhere((c) => c['name'] == 'default');
      expect(c['periodMs'], CoreSkeletonStyle.defaultDuration.inMilliseconds);
      expect(curveOf(c), CoreSkeletonStyle.defaultCurve);
    });

    for (final c in timelines) {
      test('${c['name']}: each half eases forward with the curve', () {
        final curve = curveOf(c);
        for (final s in (c['samples']! as List).cast<Map<String, Object?>>()) {
          final t = (s['t']! as num).toDouble();
          // Rest → peak in the first half, peak → rest in the second, each
          // eased forward — the CSS per-keyframe-interval reading.
          final progress = t <= 0.5
              ? easeAt(curve, t / 0.5)
              : 1 - easeAt(curve, (t - 0.5) / 0.5);
          expect(
            progress,
            closeTo((s['progress']! as num).toDouble(), 1e-6),
            reason: 't $t',
          );
        }
      });
    }
  });

  for (final c in cases) {
    test('${c['name']}: rest ${c['restAlpha']}, peak ${c['peakAlpha']}', () {
      final fill = _fill(c['fill'] as Map<String, Object?>?);
      final rest = fill.scaleAlpha((c['fromOpacity']! as num).toDouble());
      final peak = fill.scaleAlpha((c['toOpacity']! as num).toDouble());

      expect(
        _alphaOf(rest),
        closeTo((c['restAlpha']! as num).toDouble(), _kTolerance),
      );
      expect(
        _alphaOf(peak),
        closeTo((c['peakAlpha']! as num).toDouble(), _kTolerance),
      );
    });
  }
}

/// `null` is the variant default — every variant shares one fill token.
CoreColor _fill(Map<String, Object?>? spec) {
  if (spec == null) {
    return CoreSkeletonStyle
        .defaultsByVariant[CoreSkeletonVariant.defaultVariant]!
        .backgroundColor;
  }
  final argb = spec['argb'] as String?;
  if (argb != null) return CoreColor(int.parse(argb));

  return CoreColor.token(
    _kTokens[spec['token']]!,
    opacity: (spec['opacity']! as num).toDouble(),
  );
}

/// The alpha a colour paints with over an opaque scheme colour — the
/// opacity modifier for a token, the alpha byte for a raw colour.
double _alphaOf(CoreColor color) =>
    color.token == null ? color.effectiveOpacity : color.opacity;

/// The fixture's `[x1, y1, x2, y2]` as a [CoreCubicBezier].
CoreCubicBezier curveOf(Map<String, Object?> c) {
  final l = (c['curve']! as List).cast<num>();
  return (
    x1: l[0].toDouble(),
    y1: l[1].toDouble(),
    x2: l[2].toDouble(),
    y2: l[3].toDouble(),
  );
}

/// The eased value of [curve] at input [x] — solve the bezier's x for its
/// parameter by bisection, then read y there. Exact enough for the 1e-6 the
/// table is written to, and independent of either platform's evaluator.
double easeAt(CoreCubicBezier curve, double x) {
  double at(double a, double b, double s) =>
      3 * (1 - s) * (1 - s) * s * a + 3 * (1 - s) * s * s * b + s * s * s;
  var lo = 0.0;
  var hi = 1.0;
  for (var i = 0; i < 60; i++) {
    final mid = (lo + hi) / 2;
    if (at(curve.x1, curve.x2, mid) < x) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return at(curve.y1, curve.y2, (lo + hi) / 2);
}
