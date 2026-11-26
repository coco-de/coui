// The density axis — what each density draws where a value was authored,
// and how it meets the surface style at the one geometry seat.
//
// The expectations are written out as numbers on purpose: a second source,
// so a change to the rungs or the floors fails here instead of moving the
// implementation and the test together.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('standard', () {
    test('draws every scale value as authored', () {
      for (final px in CoreSpace.steps) {
        expect(CoreDensity.standard.space(px), px, reason: 'space $px');
      }
      for (final px in CoreControlSize.steps) {
        expect(CoreDensity.standard.controlHeight(px), px, reason: 'row $px');
      }
      for (final px in [0.0, ...CoreRadius.steps, CoreRadius.radius9999]) {
        expect(CoreDensity.standard.radius(px), px, reason: 'radius $px');
      }
    });

    test('is the default, and the default geometry stays identity', () {
      expect(CoreDensity.defaultDensity, CoreDensity.standard);
      expect(resolveThemeGeometry().isIdentity, isTrue);
      expect(
        identical(
          resolveThemeGeometry(),
          resolveThemeRecipe().geometry,
        ),
        isTrue,
        reason: 'an app that states no density keeps the preset instance',
      );
    });
  });

  group('spacing', () {
    final compact = <double, double>{
      6.0: 4.0,
      8.0: 4.0,
      10.0: 8.0,
      12.0: 8.0,
      14.0: 12.0,
      16.0: 12.0,
      // Off the 4px grid, so it moves to the next rung down like 6 · 10 · 14.
      18.0: 16.0,
      20.0: 16.0,
      24.0: 20.0,
      32.0: 28.0,
      64.0: 60.0,
      72.0: 64.0,
      256.0: 248.0,
    };
    final spacious = <double, double>{
      6.0: 8.0,
      8.0: 12.0,
      10.0: 12.0,
      12.0: 16.0,
      16.0: 20.0,
      18.0: 20.0,
      24.0: 28.0,
      60.0: 64.0,
      64.0: 72.0,
      248.0: 256.0,
    };

    test('compact moves one rung down the 4px grid', () {
      compact.forEach((from, to) {
        expect(CoreDensity.compact.space(from), to, reason: '$from');
      });
    });

    test('spacious moves one rung up the 4px grid', () {
      spacious.forEach((from, to) {
        expect(CoreDensity.spacious.space(from), to, reason: '$from');
      });
    });

    test('4 and below do not move — the gap beside an icon', () {
      for (final density in CoreDensity.values) {
        for (final px in [-8.0, 0.0, 2.0, 4.0]) {
          expect(density.space(px), px, reason: '${density.name} $px');
        }
      }
    });

    test('past either end of the scale, nothing moves', () {
      expect(CoreDensity.compact.space(300), 300);
      expect(CoreDensity.spacious.space(256), 256);
      expect(CoreDensity.spacious.space(300), 300);
    });

    test('an off-scale value moves to the next rung in its direction', () {
      expect(CoreDensity.compact.space(13), 12);
      expect(CoreDensity.spacious.space(13), 16);
    });

    test('every on-scale value lands on the scale', () {
      for (final density in CoreDensity.values) {
        for (final px in CoreSpace.steps) {
          expect(
            CoreSpace.steps,
            contains(density.space(px)),
            reason: '${density.name} $px',
          );
        }
      }
    });
  });

  group('a row off the control ladder', () {
    // The 36 `md` MenuItem row sits between the sm (32) and md (40) rungs.
    const menuMd = CoreSize.size36;

    test('36 is no rung of the control ladder', () {
      expect(CoreControlSize.steps, isNot(contains(menuMd)));
      expect(
        CoreMenuItemStyle.defaultsBySize[CoreMenuItemSize.md]!.minHeight,
        menuMd,
      );
    });

    test('every density draws it as authored', () {
      for (final density in CoreDensity.values) {
        expect(density.controlHeight(menuMd), 36.0, reason: density.name);
      }
      expect(
        resolveThemeGeometry(density: .compact).controlHeight(menuMd),
        36.0,
      );
      expect(
        resolveThemeGeometry(density: .spacious).controlHeight(menuMd),
        36.0,
      );
    });

    test('the ladder asks one question, and the rungs are its answer', () {
      for (final h in CoreControlSize.steps) {
        expect(CoreControlSize.isRung(h), isTrue, reason: '$h');
      }
      expect(CoreControlSize.isRung(menuMd), isFalse);
    });
  });

  group('control rows', () {
    test('compact moves one rung down and stops at sm', () {
      expect(
        [
          for (final h in CoreControlSize.steps)
            CoreDensity.compact.controlHeight(h),
        ],
        [24.0, 32.0, 32.0, 40.0, 48.0, 56.0],
      );
    });

    test('spacious moves one rung up and stops at xl2', () {
      expect(
        [
          for (final h in CoreControlSize.steps)
            CoreDensity.spacious.controlHeight(h),
        ],
        [32.0, 40.0, 48.0, 56.0, 64.0, 64.0],
      );
    });

    test('the corner follows the row on every rung, ends included', () {
      for (final density in CoreDensity.values) {
        for (final h in CoreControlSize.steps) {
          expect(
            density.radius(h * 0.25),
            density.controlHeight(h) * 0.25,
            reason: '${density.name} row $h',
          );
        }
      }
    });
  });

  group('corners', () {
    test('compact moves the row band down, stopping at the sm corner', () {
      expect(
        [
          for (final px in [6.0, 8.0, 10.0, 12.0, 14.0, 16.0])
            CoreDensity.compact.radius(px),
        ],
        [6.0, 8.0, 8.0, 10.0, 12.0, 14.0],
      );
    });

    test('spacious moves the row band up, stopping at its top', () {
      expect(
        [
          for (final px in [6.0, 8.0, 10.0, 12.0, 14.0, 16.0])
            CoreDensity.spacious.radius(px),
        ],
        [8.0, 10.0, 12.0, 14.0, 16.0, 16.0],
      );
    });

    test('corners off the row band stay', () {
      for (final density in CoreDensity.values) {
        for (final px in [0.0, 2.0, 4.0, 20.0, 24.0, CoreRadius.radius9999]) {
          expect(density.radius(px), px, reason: '${density.name} $px');
        }
      }
    });
  });

  group('the geometry seat', () {
    test('carries the density into equality', () {
      final compact = resolveThemeGeometry(density: .compact);
      expect(compact, isNot(resolveThemeGeometry()));
      expect(compact, resolveThemeGeometry(density: .compact));
      expect(
        compact.hashCode,
        resolveThemeGeometry(density: .compact).hashCode,
      );
      expect(compact.isIdentity, isFalse);
    });

    test('applies the density first, then the style', () {
      for (final style in CoreSurfaceStyleId.values) {
        final styleOnly = resolveThemeGeometry(surfaceStyle: style);
        for (final density in CoreDensity.values) {
          final both = resolveThemeGeometry(
            surfaceStyle: style,
            density: density,
          );
          for (final px in [...CoreRadius.steps, 0.0, CoreRadius.radius9999]) {
            expect(
              both.radius(px),
              styleOnly.radius(density.radius(px)),
              reason: '${style.name} × ${density.name} radius $px',
            );
          }
        }
      }
    });

    test(
      'a compact neo-brutalism corner is the style of the compact corner',
      () {
        // Written out: compact moves 10 → 8, and the style then lands 8
        // wherever it lands any 8.
        expect(
          resolveThemeGeometry(
            surfaceStyle: .neoBrutalism,
            density: .compact,
          ).radius(10),
          resolveThemeGeometry(surfaceStyle: .neoBrutalism).radius(8),
        );
      },
    );

    test('bends insets on every side and keeps them directional', () {
      final compact = resolveThemeGeometry(density: .compact);
      expect(
        compact.insets(
          const CoreEdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        const CoreEdgeInsets.symmetric(horizontal: 12, vertical: 4),
      );
      final directional = compact.insets(
        const CoreEdgeInsets.directional(start: 24, end: 12),
      );
      expect(directional.isDirectional, isTrue);
      expect(directional.start, 20);
      expect(directional.end, 8);
    });

    test('identity insets come back as the same instance', () {
      const value = CoreEdgeInsets.all(16);
      expect(identical(resolveThemeGeometry().insets(value), value), isTrue);
    });
  });

  group('a field with no Size axis states the md row', () {
    // ChipInput's frame and ItemPicker's search are fields
    // that sit beside an md text field. Stated as the md rung — not as a size
    // that happens to measure 40 — they move with that field.
    final rows = <String, double>{
      'ChipInput.minHeight': CoreChipInputStyle.defaultMinHeight,
      'ItemPicker.searchHeight': CoreItemPickerStyle.defaultSearchHeight,
    };

    test('is the md rung', () {
      for (final MapEntry(:key, :value) in rows.entries) {
        expect(value, CoreControlSize.heightMd, reason: key);
      }
    });

    test('draws the text field’s row under every density', () {
      final field =
          CoreTextFieldStyle.defaultsBySize[CoreComponentSize.md]!.minHeight!;
      for (final (density, px) in [
        (CoreDensity.compact, 32.0),
        (CoreDensity.standard, 40.0),
        (CoreDensity.spacious, 48.0),
      ]) {
        expect(density.controlHeight(field), px, reason: density.name);
        for (final MapEntry(:key, :value) in rows.entries) {
          expect(density.controlHeight(value), px, reason: '$key $density');
        }
      }
    });

    test('the picker’s search is the composed field’s own md row', () {
      // Web forwards no height for the search — the composed TextField's own
      // row variable carries the density — while Flutter sizes the row from
      // this constant. The two have to stay one rung.
      expect(
        CoreItemPickerStyle.defaultSearchHeight,
        CoreTextFieldStyle.defaultsBySize[CoreComponentSize.md]!.minHeight,
      );
    });
  });

  test('PhoneInput’s box is the lg rung, the row of the lg text field', () {
    expect(CorePhoneInputStyle.defaultHeight, CoreControlSize.heightLg);
    expect(
      CorePhoneInputStyle.defaultHeight,
      CoreTextFieldStyle.defaultsBySize[CoreComponentSize.lg]!.minHeight,
    );
  });

  test('a compact md button is the sm row', () {
    // The ladders were not authored to make this true; it falls out of
    // moving every value one rung, which is the evidence the rungs are the
    // right size.
    //
    // The icon↔label gap is left out on purpose: the gap ladder is 4 · 6 ·
    // 6 · 6 · 8 · 8, so md and sm state the same 6 and no density can make
    // one row's gap the other's — compact takes the md 6 to 4 while sm
    // keeps its 6.
    final md = CoreButtonStyle.defaultsBySize[CoreComponentSize.md]!;
    final sm = CoreButtonStyle.defaultsBySize[CoreComponentSize.sm]!;
    final compact = resolveThemeGeometry(density: .compact);

    expect(compact.controlHeight(md.height!), sm.height);
    expect(
      compact.borderRadius(md.borderRadius!),
      sm.borderRadius,
    );
    expect(compact.insets(md.padding!), sm.padding);
  });
}
