// Tests for CoreLoadingStyle — #3773.
//
// Scope: the `defaultsBySize` regression net only (issue #3773's
// completion definition). Before this file, CoreLoadingStyle had zero
// tests pinning `defaultsBySize` coverage — a `CoreComponentSize`
// member could be added without a matching entry and the only signal
// would be a runtime crash the first time some resolver hit
// `defaultsBySize[size]!` (a Map lookup, not a `switch`, so Dart's
// exhaustiveness checker never sees it).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreLoadingStyle.defaultsBySize (#3773)', () {
    // Full 6-tier coverage — CoUI_Size_Token_Specification §3-4
    // (Loading, v1.1) regulates every tier including xl2.
    const unregulatedSizes = <CoreComponentSize>{};

    test(
      'covers every CoreComponentSize member',
      () {
        for (final size in CoreComponentSize.values) {
          if (unregulatedSizes.contains(size)) continue;
          expect(
            CoreLoadingStyle.defaultsBySize[size],
            isNotNull,
            reason:
                'missing size chrome for CoreComponentSize.${size.name} — '
                'every `defaultsBySize[size]!` lookup in the resolvers '
                'assumes full coverage and would crash at runtime',
          );
        }
      },
    );

    test(
      'has exactly one entry per CoreComponentSize member',
      () {
        // Guards the other direction: a stale entry left behind after a
        // member is removed from CoreComponentSize.
        expect(
          CoreLoadingStyle.defaultsBySize.length,
          CoreComponentSize.values.length - unregulatedSizes.length,
        );
      },
    );

    test('every entry sets a non-null size', () {
      // Both the Flutter and Web resolvers chain a *second* `!` onto
      // this lookup — `defaultsBySize[componentSize]!.size!` — so
      // coverage of the map key alone is not the whole story: the
      // `size` field on every entry must also be non-null, or that
      // second `!` throws even though the key exists.
      for (final size in CoreComponentSize.values) {
        if (unregulatedSizes.contains(size)) continue;
        expect(
          CoreLoadingStyle.defaultsBySize[size]!.size,
          isNotNull,
          reason:
              'CoreComponentSize.${size.name} entry has no `size` — '
              '`defaultsBySize[size]!.size!` would crash at runtime',
        );
      }
    });
  });

  group('CoreLoadingStyle tone and stroke (#5879)', () {
    test('one row per tone', () {
      expect(CoreLoadingStyle.defaultsByTone.keys, CoreLoadingTone.values);
      expect(CoreLoadingTone.defaultTone, CoreLoadingTone.primary);
    });

    test('primary is the accent on a neutral track', () {
      final row = CoreLoadingStyle.defaultsByTone[CoreLoadingTone.primary]!;
      expect(row.color, CoreLoadingStyle.defaultColor);
      expect(
        row.trackColor,
        const CoreColor.token(CoreColors.surfaceContainerHigh),
      );
    });

    test('neutral reads on-surface-variant; inverse reads on-primary', () {
      expect(
        CoreLoadingStyle.defaultsByTone[CoreLoadingTone.neutral]!.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      final inverse = CoreLoadingStyle.defaultsByTone[CoreLoadingTone.inverse]!;
      expect(inverse.color, const CoreColor.token(CoreColors.onPrimary));
      // On a filled surface the track is the ink faded, not a neutral surface.
      expect(inverse.trackColor, isNull);
      expect(inverse.trackAlpha, 0.25);
    });

    test('the arc is a quarter of the ring', () {
      expect(CoreLoadingStyle.defaultArcSweepDegrees, 90);
    });

    test('the ring thickens with the size: 2 · 2 · 2 · 3 · 3 · 4', () {
      expect(
        [
          for (final size in CoreComponentSize.values)
            CoreLoadingStyle.defaultsBySize[size]!.strokeWidth,
        ],
        [
          CoreStrokeWidth.stroke2,
          CoreStrokeWidth.stroke2,
          CoreStrokeWidth.stroke2,
          CoreStrokeWidth.stroke3,
          CoreStrokeWidth.stroke3,
          CoreStrokeWidth.stroke4,
        ],
      );
    });
  });

  group('dots wave', () {
    test('the dots read 1 · 0.6 · 0.3 at the start of a cycle', () {
      expect(CoreLoadingStyle.dotWaveOpacities, [1, 0.6, 0.3]);
      for (var i = 0; i < CoreLoadingStyle.dotCount; i++) {
        expect(
          CoreLoadingStyle.dotOpacityAt(CoreLoadingStyle.dotWavePhase(i, 0)),
          closeTo(CoreLoadingStyle.dotWaveOpacities[i], 1e-9),
          reason: 'dot $i',
        );
      }
    });

    test('each dot lags the one before by a third of the cycle', () {
      expect(CoreLoadingStyle.dotPhaseOffsetRatio, closeTo(1 / 3, 1e-12));
      // A third on, the levels have stepped one dot to the right.
      const t = 1 / 3;
      final at = [
        for (var i = 0; i < CoreLoadingStyle.dotCount; i++)
          CoreLoadingStyle.dotOpacityAt(CoreLoadingStyle.dotWavePhase(i, t)),
      ];
      expect(at[0], closeTo(0.3, 1e-9));
      expect(at[1], closeTo(1, 1e-9));
      expect(at[2], closeTo(0.6, 1e-9));
    });

    test('a cycle stays within the wave levels and closes on itself', () {
      for (var step = 0; step <= 100; step++) {
        final o = CoreLoadingStyle.dotOpacityAt(step / 100);
        expect(o, inInclusiveRange(0.3, 1));
      }
      expect(
        CoreLoadingStyle.dotOpacityAt(0),
        closeTo(CoreLoadingStyle.dotOpacityAt(1), 1e-9),
      );
      expect(
        CoreLoadingStyle.dotWaveKeyframeOpacity(CoreLoadingStyle.dotCount),
        CoreLoadingStyle.dotWaveKeyframeOpacity(0),
      );
    });

    test('dots are half a dot apart', () {
      expect(CoreLoadingStyle.dotGapRatio, 0.5);
    });
  });
}
