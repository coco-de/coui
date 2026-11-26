// Tests for CoreProgressStyle — #3773 pattern applied to Epic K axis 8-1
// (#3886).
//
// Scope: the `defaultsBySize` regression net only (issue #3773's
// completion definition, mirrored for the newly-introduced
// `CoreProgressSize`). Before this file, `CoreProgressStyle` had no size
// axis at all — a `CoreProgressSize` member could be added without a
// matching `defaultsBySize` entry and the only signal would be a runtime
// crash the first time some resolver hit `defaultsBySize[size]!` (a Map
// lookup, not a `switch`, so Dart's exhaustiveness checker never sees it).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreProgressStyle.defaultsBySize (#3773)', () {
    test('covers every CoreProgressSize member', () {
      for (final size in CoreProgressSize.values) {
        expect(
          CoreProgressStyle.defaultsBySize[size],
          isNotNull,
          reason:
              'missing size chrome for CoreProgressSize.${size.name} — '
              'every `defaultsBySize[size]!` lookup in the resolvers '
              'assumes full coverage and would crash at runtime',
        );
      }
    });

    test('has exactly one entry per CoreProgressSize member', () {
      // Guards the other direction: a stale entry left behind after a
      // member is removed from CoreProgressSize.
      expect(
        CoreProgressStyle.defaultsBySize.length,
        CoreProgressSize.values.length,
      );
    });
  });

  group('defaults', () {
    test('the widget default is sm — a 6 px bar', () {
      expect(CoreProgressSize.defaultSize, CoreProgressSize.sm);
      expect(
        CoreProgressStyle
            .defaultsBySize[CoreProgressSize.defaultSize]!
            .minHeight,
        6,
      );
    });

    test('the track ends in a half circle at every height', () {
      expect(
        CoreProgressStyle.defaultBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius9999),
      );
    });
  });

  group('track colour', () {
    test('the track is a neutral band, not the fill faded', () {
      const track = CoreColor.token(CoreColors.surfaceContainerHigh);
      expect(CoreProgressStyle.defaultBackgroundColor, track);
      expect(CoreRadialProgressStyle.defaultBackgroundColor, track);
    });

    test('no tone row states a track — every tone runs on the neutral one', () {
      for (final row in CoreProgressStyle.defaultsByTone.values) {
        expect(row.backgroundColor, isNull);
        expect(row.backgroundAlpha, isNull);
      }
    });
  });

  group('CoreProgressStyle.defaultsByTone', () {
    test('the widget default is primary', () {
      expect(CoreProgressTone.defaultTone, CoreProgressTone.primary);
    });

    test('has exactly one row per tone, each stating its fill', () {
      // The resolvers read `defaultsByTone[tone]!.color!` — a missing row
      // or an empty one crashes at runtime, and an empty row also reaches
      // the canvas with no colour.
      expect(
        CoreProgressStyle.defaultsByTone.keys,
        unorderedEquals(CoreProgressTone.values),
      );
      for (final tone in CoreProgressTone.values) {
        expect(
          CoreProgressStyle.defaultsByTone[tone]!.color,
          isNotNull,
          reason: 'CoreProgressTone.${tone.name} states no fill',
        );
      }
    });

    test('each tone fills with its status slot', () {
      CoreColor? fill(CoreProgressTone tone) =>
          CoreProgressStyle.defaultsByTone[tone]!.color;

      expect(fill(.primary), CoreProgressStyle.defaultColor);
      expect(fill(.primary), const CoreColor.token(CoreColors.primary));
      expect(fill(.success), const CoreColor.token(CoreColors.success));
      expect(fill(.warning), const CoreColor.token(CoreColors.warning));
      expect(fill(.destructive), const CoreColor.token(CoreColors.error));
    });
  });

  group('label cells', () {
    test('label — labelMedium at its own weight in onSurface', () {
      const style = CoreProgressStyle.defaultLabelStyle;
      expect(style.token, CoreTextStyles.labelMedium);
      expect(style.fontWeight, isNull);
      expect(style.fontSize, isNull, reason: "the size is the role's own");
      expect(style.color, const CoreColor.token(CoreColors.onSurface));
    });

    test('valueLabel — labelMedium at regular weight in onSurfaceVariant', () {
      final style = CoreProgressStyle.defaultValueLabelStyle;
      expect(style.token, CoreTextStyles.labelMedium);
      expect(style.fontWeight, CoreFontWeight.regular);
      expect(style.color, const CoreColor.token(CoreColors.onSurfaceVariant));
    });

    test('caption — bodyXs in onSurfaceSubtle', () {
      const style = CoreProgressStyle.defaultCaptionStyle;
      expect(style.token, CoreTextStyles.bodyXs);
      expect(style.color, const CoreColor.token(CoreColors.onSurfaceSubtle));
    });

    test('both spacers are space8, as two fields', () {
      expect(CoreProgressStyle.defaultLabelGapStyle.size, CoreSpace.space8);
      expect(CoreProgressStyle.defaultCaptionGapStyle.size, CoreSpace.space8);
    });
  });

  group('value semantics of the new fields', () {
    const base = CoreProgressStyle(
      labelStyle: CoreTextStyle(fontSize: 14),
      valueLabelStyle: CoreTextStyle(fontSize: 13),
      captionStyle: CoreTextStyle(fontSize: 12),
      labelGapStyle: CoreGapStyle(size: CoreSpace.space4),
      captionGapStyle: CoreGapStyle(size: CoreSpace.space6),
    );

    test('merge layers nested slots field by field', () {
      final merged = base.merge(
        const CoreProgressStyle(
          labelStyle: CoreTextStyle(color: CoreColor.token(CoreColors.error)),
          captionGapStyle: CoreGapStyle(size: CoreSpace.space10),
        ),
      );

      expect(merged.labelStyle!.fontSize, 14, reason: 'base size kept');
      expect(merged.labelStyle!.color, const CoreColor.token(CoreColors.error));
      expect(merged.valueLabelStyle, base.valueLabelStyle);
      expect(merged.captionStyle, base.captionStyle);
      expect(merged.labelGapStyle, base.labelGapStyle);
      expect(merged.captionGapStyle!.size, CoreSpace.space10);
    });

    test('merge onto an empty style takes the other side whole', () {
      expect(const CoreProgressStyle().merge(base), base);
    });

    test('copyWith replaces only what it names', () {
      final copy = base.copyWith(
        captionStyle: const CoreTextStyle(fontSize: 11),
      );
      expect(copy.captionStyle!.fontSize, 11);
      expect(copy.labelStyle, base.labelStyle);
      expect(copy.labelGapStyle, base.labelGapStyle);
      expect(copy.captionGapStyle, base.captionGapStyle);
    });

    test('every new field takes part in == and hashCode', () {
      final variants = <CoreProgressStyle>[
        base.copyWith(labelStyle: const CoreTextStyle(fontSize: 20)),
        base.copyWith(valueLabelStyle: const CoreTextStyle(fontSize: 20)),
        base.copyWith(captionStyle: const CoreTextStyle(fontSize: 20)),
        base.copyWith(labelGapStyle: const CoreGapStyle(size: 20)),
        base.copyWith(captionGapStyle: const CoreGapStyle(size: 20)),
      ];
      for (final other in variants) {
        expect(other, isNot(base));
        expect(other.hashCode, isNot(base.hashCode));
      }
      expect(base.copyWith(), base);
      expect(base.copyWith().hashCode, base.hashCode);
    });
  });

  group('segments', () {
    test('the cell gap is space4', () {
      expect(CoreProgressStyle.defaultSegmentSpacing, CoreSpace.space4);
    });

    test('segmentSpacing merges, copies and compares', () {
      const spaced = CoreProgressStyle(segmentSpacing: CoreSpace.space8);

      expect(const CoreProgressStyle().merge(spaced).segmentSpacing, 8);
      expect(
        spaced.merge(const CoreProgressStyle()).segmentSpacing,
        8,
        reason: 'a null on the other side keeps the stated gap',
      );
      expect(spaced.copyWith(segmentSpacing: 12).segmentSpacing, 12);
      expect(spaced.copyWith(), spaced);
      expect(spaced, isNot(const CoreProgressStyle()));
      expect(spaced.hashCode, isNot(const CoreProgressStyle().hashCode));
    });

    int filled(double value, int segments, {double min = 0, double max = 1}) =>
        CoreProgressContract.filledSegmentsOf(
          value: value,
          min: min,
          max: max,
          segments: segments,
        );

    test('fills the steps passed, never a partial one', () {
      expect(filled(0, 2), 0);
      expect(filled(0.49, 2), 0);
      expect(filled(0.5, 2), 1);
      expect(filled(0.99, 2), 1);
      expect(filled(1, 2), 2);
    });

    test('counts in the bar range, not 0…1', () {
      expect(filled(1, 2, max: 2), 1, reason: 'STEP 1 / 2');
      expect(filled(7, 4, min: 5, max: 9), 2);
    });

    test('a step reached in floating point counts as reached', () {
      // 0.29 × 100 is 28.999999999999996 and 0.57 × 100 is
      // 56.99999999999999 — a plain floor would fill one cell short.
      expect(0.29 * 100, lessThan(29));
      expect(filled(0.29, 100), 29);
      expect(filled(0.57, 100), 57);
    });

    test('stays inside 0 … segments', () {
      expect(filled(1.5, 3), 3);
      expect(filled(-1, 3), 0);
    });

    test('a range or segment count it cannot divide fills nothing', () {
      expect(filled(1, 3, min: 1), 0);
      expect(filled(1, 3, min: 2), 0);
      expect(filled(0.5, 0), 0);
      expect(filled(double.nan, 3), 0);
    });
  });

  group('CoreProgressTheme.toneStyles', () {
    const warning = CoreProgressStyle(
      color: CoreColor.token(CoreColors.tertiary),
    );
    const destructive = CoreProgressStyle(
      color: CoreColor.token(CoreColors.secondary),
    );

    test('equal maps compare equal and hash alike, in any order', () {
      const a = CoreProgressTheme(
        toneStyles: {
          CoreProgressTone.warning: warning,
          CoreProgressTone.destructive: destructive,
        },
      );
      const b = CoreProgressTheme(
        toneStyles: {
          CoreProgressTone.destructive: destructive,
          CoreProgressTone.warning: warning,
        },
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a different row or key is a different theme', () {
      const a = CoreProgressTheme(
        toneStyles: {CoreProgressTone.warning: warning},
      );
      expect(
        a,
        isNot(
          const CoreProgressTheme(
            toneStyles: {CoreProgressTone.warning: destructive},
          ),
        ),
      );
      expect(
        a,
        isNot(
          const CoreProgressTheme(
            toneStyles: {CoreProgressTone.destructive: warning},
          ),
        ),
      );
      expect(a, isNot(const CoreProgressTheme()));
    });
  });

  group('indeterminate bar fill (#5879)', () {
    test('the sweeping fill is 35% of the track, stated once', () {
      expect(CoreProgressStyle.defaultIndeterminateFillRatio, 0.35);
    });

    test('indeterminateFillRatio merges, copies and compares', () {
      const a = CoreProgressStyle(indeterminateFillRatio: 0.5);
      expect(const CoreProgressStyle().merge(a).indeterminateFillRatio, 0.5);
      expect(a.merge(const CoreProgressStyle()).indeterminateFillRatio, 0.5);
      expect(
        a.copyWith(indeterminateFillRatio: 0.2).indeterminateFillRatio,
        0.2,
      );
      expect(a, isNot(const CoreProgressStyle(indeterminateFillRatio: 0.4)));
      expect(
        a.hashCode,
        const CoreProgressStyle(indeterminateFillRatio: 0.5).hashCode,
      );
    });

    test('the value cell reserves the widest reading', () {
      expect(CoreProgressContract.defaultValueLabelReserve, '100%');
    });
  });

  group('CoreRadialProgressStyle size ladder (#5879)', () {
    const sizes = CoreRadialProgressStyle.defaultsBySize;

    test('four steps: 32 · 48 · 80 · 128 with rings 3 · 4 · 6 · 8', () {
      expect(sizes.keys, CoreProgressSize.values.where(sizes.containsKey));
      expect(
        {
          for (final e in sizes.entries)
            e.key: (e.value.size, e.value.strokeWidth),
        },
        {
          CoreProgressSize.sm: (CoreSize.size32, CoreStrokeWidth.stroke3),
          CoreProgressSize.md: (CoreSize.size48, CoreStrokeWidth.stroke4),
          CoreProgressSize.lg: (CoreSize.size80, CoreStrokeWidth.stroke6),
          CoreProgressSize.xl: (CoreSize.size128, CoreStrokeWidth.stroke8),
        },
      );
    });

    test('sm draws no figure; the others state a role', () {
      expect(sizes[CoreProgressSize.sm]!.valueTextStyle, isNull);
      for (final size in [
        CoreProgressSize.md,
        CoreProgressSize.lg,
        CoreProgressSize.xl,
      ]) {
        expect(sizes[size]!.valueTextStyle, isNotNull, reason: size.name);
      }
    });

    test('a tone changes the arc colour and nothing else', () {
      const tones = CoreRadialProgressStyle.defaultsByTone;
      expect(tones.keys, CoreProgressTone.values);
      for (final tone in tones.values) {
        expect(tone.color, isNotNull);
        expect(tone.size, isNull);
        expect(tone.strokeWidth, isNull);
      }
    });

    test('the resting ring is lg / primary', () {
      expect(CoreRadialProgressContract.defaultSize, CoreProgressSize.lg);
      expect(CoreRadialProgressContract.defaultTone, CoreProgressTone.primary);
      final lg = CoreRadialProgressStyle.defaultsBySize[CoreProgressSize.lg]!;
      expect(lg.size, CoreSize.size80);
      expect(lg.strokeWidth, CoreStrokeWidth.stroke6);
    });
  });
}
