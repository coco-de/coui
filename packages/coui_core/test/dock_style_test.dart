// Tests for CoreDockStyle — #3773.
//
// Scope: the `defaultsBySize` regression net only (issue #3773's
// completion definition). Before this file, CoreDockStyle had zero
// tests pinning `defaultsBySize` coverage — a `CoreDockSize` member
// could be added without a matching entry and the only signal would be
// a runtime crash the first time some resolver hit
// `defaultsBySize[size]!` (a Map lookup, not a `switch`, so Dart's
// exhaustiveness checker never sees it).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreDockStyle.defaultsBySize (#3773)', () {
    test('covers every CoreDockSize member', () {
      for (final size in CoreDockSize.values) {
        expect(
          CoreDockStyle.defaultsBySize[size],
          isNotNull,
          reason:
              'missing size chrome for CoreDockSize.${size.name} — every '
              '`defaultsBySize[size]!` lookup in the resolvers assumes '
              'full coverage and would crash at runtime',
        );
      }
    });

    test('has exactly one entry per CoreDockSize member', () {
      // Guards the other direction: a stale entry left behind after a
      // member is removed from CoreDockSize.
      expect(
        CoreDockStyle.defaultsBySize.length,
        CoreDockSize.values.length,
      );
    });
  });

  group("the bar's minimum height", () {
    test('is the height each size states: 48, 56, 64, 72, 80', () {
      // `height` is the floor the bar grows from, not a height it is held to:
      // these are the heights a bar whose content fits is drawn at, and the
      // vector table's rows are built on them.
      expect(
        {
          for (final entry in CoreDockStyle.defaultsBySize.entries)
            entry.key: entry.value.height,
        },
        {
          CoreDockSize.xs: 48,
          CoreDockSize.sm: 56,
          CoreDockSize.md: 64,
          CoreDockSize.lg: 72,
          CoreDockSize.xl: 80,
        },
      );
    });
  });

  group('the redesign (#6463) per size', () {
    Map<CoreDockSize, T> each<T>(T Function(CoreDockStyle row) read) => {
      for (final entry in CoreDockStyle.defaultsBySize.entries)
        entry.key: read(entry.value),
    };

    test('the bar is padded 6 · 8 at xs and sm, 10 all round from md', () {
      expect(each((r) => r.padding), {
        CoreDockSize.xs: const CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space8,
          vertical: CoreSpace.space6,
        ),
        CoreDockSize.sm: const CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space8,
          vertical: CoreSpace.space6,
        ),
        CoreDockSize.md: const CoreEdgeInsets.all(CoreSpace.space10),
        CoreDockSize.lg: const CoreEdgeInsets.all(CoreSpace.space10),
        CoreDockSize.xl: const CoreEdgeInsets.all(CoreSpace.space10),
      });
    });

    test('the bar is rounded 10 at xs and sm, 16 from md', () {
      expect(each((r) => r.barRadius!.topLeft), {
        CoreDockSize.xs: 10,
        CoreDockSize.sm: 10,
        CoreDockSize.md: 16,
        CoreDockSize.lg: 16,
        CoreDockSize.xl: 16,
      });
    });

    test('the apps are 6 apart at xs and sm, 4 from md', () {
      expect(each((r) => r.itemSpacing), {
        CoreDockSize.xs: 6,
        CoreDockSize.sm: 6,
        CoreDockSize.md: 4,
        CoreDockSize.lg: 4,
        CoreDockSize.xl: 4,
      });
    });

    test('a labelled cell is 48 · 56 · 64 wide, a bare icon is its own', () {
      expect(each((r) => r.itemWidth), {
        CoreDockSize.xs: null,
        CoreDockSize.sm: null,
        CoreDockSize.md: 48,
        CoreDockSize.lg: 56,
        CoreDockSize.xl: 64,
      });
      for (final size in CoreDockSize.values) {
        expect(
          CoreDockStyle.defaultsBySize[size]!.itemWidth != null,
          CoreDockStyle.labelVisibleFor(size),
          reason: 'a fixed cell is what carries a name',
        );
      }
    });

    test('the plate is 8 round reaching 3 at xs and sm, 10 round reaching '
        '5 above and below from md', () {
      expect(each((r) => r.indicatorRadius!.topLeft), {
        CoreDockSize.xs: 8,
        CoreDockSize.sm: 8,
        CoreDockSize.md: 10,
        CoreDockSize.lg: 10,
        CoreDockSize.xl: 10,
      });
      expect(each((r) => r.indicatorPadding), {
        CoreDockSize.xs: const CoreEdgeInsets.all(3),
        CoreDockSize.sm: const CoreEdgeInsets.all(3),
        CoreDockSize.md: const CoreEdgeInsets.symmetric(vertical: 5),
        CoreDockSize.lg: const CoreEdgeInsets.symmetric(vertical: 5),
        CoreDockSize.xl: const CoreEdgeInsets.symmetric(vertical: 5),
      });
    });

    test('the line is outline-variant, the plate surface-container-high', () {
      expect(
        CoreDockStyle.defaultBorderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(
        CoreDockStyle.defaultIndicatorColor,
        const CoreColor.token(CoreColors.surfaceContainerHigh),
      );
    });

    test('labels are the 11px role, SemiBold on-surface when active and '
        'Medium on-surface-variant otherwise', () {
      final active = CoreDockStyle.defaultActiveLabelStyle;
      final inactive = CoreDockStyle.defaultInactiveLabelStyle;
      expect(active.token, CoreTextStyles.labelXs);
      expect(inactive.token, CoreTextStyles.labelXs);
      expect(CoreTypography.coui.labelXs.fontSize, 11);
      expect(active.fontWeight, CoreFontWeight.semiBold);
      expect(inactive.fontWeight, CoreFontWeight.medium);
      expect(active.color, const CoreColor.token(CoreColors.onSurface));
      expect(
        inactive.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
    });

    test('the bar casts the md shadow on the palette shadow slot', () {
      expect(CoreDockStyle.defaultBoxShadow, CoreShadow.md);
      expect(
        CoreDockStyle.defaultShadowBaseColor,
        const CoreColor.token(CoreColors.shadow),
      );
    });

    test('merge, copyWith and equality carry the shadow fields', () {
      const base = CoreDockStyle();
      const patch = CoreDockStyle(
        boxShadow: CoreShadow.lg,
        shadowBaseColor: CoreColor.token(CoreColors.primary),
      );
      final merged = base.merge(patch);
      expect(merged, patch);
      expect(merged.hashCode, patch.hashCode);
      expect(merged, isNot(base));
      expect(
        const CoreDockStyle(boxShadow: CoreShadow.lg),
        isNot(const CoreDockStyle(boxShadow: CoreShadow.md)),
      );
      expect(base.copyWith(boxShadow: CoreShadow.sm).boxShadow, CoreShadow.sm);
      expect(
        patch.merge(const CoreDockStyle(height: 10)).boxShadow,
        CoreShadow.lg,
      );
    });

    test('merge, copyWith and equality carry the two new fields', () {
      const base = CoreDockStyle();
      const patch = CoreDockStyle(itemSpacing: 12, itemWidth: 70);
      final merged = base.merge(patch);
      expect(merged, patch);
      expect(merged.hashCode, patch.hashCode);
      expect(merged, isNot(base));
      expect(base.copyWith(itemSpacing: 12).itemSpacing, 12);
      expect(base.copyWith(itemWidth: 70).itemWidth, 70);
      expect(patch.merge(const CoreDockStyle(height: 10)).itemWidth, 70);
    });
  });

  group("the bar's line width is a value the style carries", () {
    test('the default is the one-pixel stroke', () {
      expect(CoreDockStyle.defaultBorderWidth, CoreStrokeWidth.stroke1);
    });

    test('merge, copyWith and equality carry it', () {
      // The axis rule again: a field `==` cannot see is a field a retune
      // cannot reach.
      const base = CoreDockStyle();
      const patch = CoreDockStyle(borderWidth: 3);

      final merged = base.merge(patch);
      expect(merged.borderWidth, 3);
      expect(merged, patch);
      expect(merged.hashCode, patch.hashCode);
      expect(merged, isNot(base));
      expect(base.copyWith(borderWidth: 3).borderWidth, 3);
      expect(patch.merge(const CoreDockStyle(height: 10)).borderWidth, 3);
    });
  });

  group('the active indicator is a value the style carries', () {
    test('every field has a default, and the plate is on by default', () {
      expect(CoreDockStyle.defaultIndicatorColor.opacity, greaterThan(0));
      for (final row in CoreDockStyle.defaultsBySize.values) {
        expect(row.indicatorRadius, isNotNull);
        expect(row.indicatorPadding!.top, greaterThan(0));
      }
      expect(CoreDockStyle.defaultIndicatorSpring.speed, CoreMorphSpeed.fast);
    });

    test('merge, copyWith and equality carry all four fields', () {
      // The axis rule: a field `==` cannot see is a field a retune cannot
      // reach — the framework compares, finds nothing changed, and the
      // old pill stays on screen.
      const base = CoreDockStyle();
      const patch = CoreDockStyle(
        indicatorColor: CoreColor.transparent,
        indicatorRadius: CoreBorderRadius.zero,
        indicatorPadding: CoreEdgeInsets.zero,
        indicatorSpring: CoreMorphSpring(speed: CoreMorphSpeed.slow),
      );

      final merged = base.merge(patch);
      expect(merged, patch);
      expect(merged.hashCode, patch.hashCode);
      expect(merged, isNot(base));
      expect(
        base.copyWith(indicatorSpring: patch.indicatorSpring).indicatorSpring,
        patch.indicatorSpring,
      );
      // A later patch that says nothing about the pill keeps the earlier
      // answer — right-side-wins only where the right side speaks.
      expect(
        patch.merge(const CoreDockStyle(height: 10)).indicatorColor,
        CoreColor.transparent,
      );
    });
  });
}
