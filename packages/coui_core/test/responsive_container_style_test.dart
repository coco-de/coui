// Tests for `CoreResponsiveContainerStyle` — Story H (#2967):
// `responsiveMaxWidth` non-breaking extension over the pre-existing
// static `maxWidth` field.
//
// These Style-level tests exercise merge/copyWith/equality — a plain
// whole-map replace, not per-key fallback (that per-key fallback
// mechanism lives in the resolver and is covered by
// `packages/coui_flutter/test/components/layout/responsive_container_test.dart`
// and the Web counterpart). Maps here are exhaustive (all three
// `CoreBreakpointTier` keys) purely to stay out of
// `avoid-missing-enum-constant-in-map`'s way — exhaustiveness carries
// no special meaning for what's under test in this file.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const Map<CoreBreakpointTier, CoreResponsiveContainerMaxWidth> _kFullMap = {
  .mobile: .sm,
  .tablet: .md,
  .desktop: .xxl,
};

void main() {
  group('CoreResponsiveContainerStyle — constructor', () {
    test('defaults every field to null', () {
      const style = CoreResponsiveContainerStyle();

      expect(style.maxWidth, isNull);
      expect(style.responsiveMaxWidth, isNull);
      expect(style.centered, isNull);
      expect(style.horizontalPadding, isNull);
    });

    test('accepts a responsiveMaxWidth map alongside the static maxWidth', () {
      const style = CoreResponsiveContainerStyle(
        maxWidth: .sm,
        responsiveMaxWidth: _kFullMap,
      );

      expect(style.maxWidth, CoreResponsiveContainerMaxWidth.sm);
      expect(style.responsiveMaxWidth, _kFullMap);
    });
  });

  group('CoreResponsiveContainerStyle.merge', () {
    test('other.responsiveMaxWidth overrides this.responsiveMaxWidth', () {
      const base = CoreResponsiveContainerStyle(
        responsiveMaxWidth: {
          .mobile: .sm,
          .tablet: .sm,
          .desktop: .sm,
        },
      );
      const override = CoreResponsiveContainerStyle(
        responsiveMaxWidth: _kFullMap,
      );

      final merged = base.merge(override);

      // Map fields replace wholesale — merge is not a per-key deep
      // merge (that semantics belongs to the resolver's per-tier
      // fallback, not the Style layer).
      expect(merged.responsiveMaxWidth, _kFullMap);
    });

    test('null other.responsiveMaxWidth preserves this.responsiveMaxWidth', () {
      const base = CoreResponsiveContainerStyle(
        responsiveMaxWidth: _kFullMap,
      );
      const override = CoreResponsiveContainerStyle();

      final merged = base.merge(override);

      expect(merged.responsiveMaxWidth, _kFullMap);
    });

    test('merge(null) returns this unchanged', () {
      const style = CoreResponsiveContainerStyle(
        responsiveMaxWidth: _kFullMap,
      );

      expect(style.merge(null), same(style));
    });

    test('existing fields (maxWidth/centered/horizontalPadding) merge '
        'unchanged', () {
      const base = CoreResponsiveContainerStyle(
        maxWidth: .sm,
        centered: true,
        horizontalPadding: CoreEdgeInsets.all(8),
      );
      const override = CoreResponsiveContainerStyle(maxWidth: .lg);

      final merged = base.merge(override);

      expect(merged.maxWidth, CoreResponsiveContainerMaxWidth.lg);
      expect(merged.centered, isTrue);
      expect(merged.horizontalPadding, const CoreEdgeInsets.all(8));
    });
  });

  group('CoreResponsiveContainerStyle.copyWith', () {
    test('replaces responsiveMaxWidth when supplied', () {
      const original = CoreResponsiveContainerStyle(
        responsiveMaxWidth: {
          .mobile: .sm,
          .tablet: .sm,
          .desktop: .sm,
        },
      );
      final copy = original.copyWith(responsiveMaxWidth: _kFullMap);

      expect(copy.responsiveMaxWidth, _kFullMap);
    });

    test('preserves responsiveMaxWidth when no override is supplied', () {
      const original = CoreResponsiveContainerStyle(
        responsiveMaxWidth: _kFullMap,
      );
      final copy = original.copyWith();

      expect(copy.responsiveMaxWidth, original.responsiveMaxWidth);
    });

    test('copyWith covers every field (no silent field drop)', () {
      const original = CoreResponsiveContainerStyle();
      final copy = original.copyWith(
        maxWidth: .lg,
        responsiveMaxWidth: _kFullMap,
        centered: false,
        horizontalPadding: const CoreEdgeInsets.all(4),
      );

      expect(copy.maxWidth, CoreResponsiveContainerMaxWidth.lg);
      expect(copy.responsiveMaxWidth, _kFullMap);
      expect(copy.centered, isFalse);
      expect(copy.horizontalPadding, const CoreEdgeInsets.all(4));
    });
  });

  group('CoreResponsiveContainerStyle — equality + hashCode', () {
    test('equal when every field (including responsiveMaxWidth) matches', () {
      const a = CoreResponsiveContainerStyle(
        maxWidth: .sm,
        responsiveMaxWidth: _kFullMap,
        centered: true,
      );
      const b = CoreResponsiveContainerStyle(
        maxWidth: .sm,
        responsiveMaxWidth: _kFullMap,
        centered: true,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('unequal when responsiveMaxWidth maps differ', () {
      const a = CoreResponsiveContainerStyle(
        responsiveMaxWidth: {
          .mobile: .sm,
          .tablet: .sm,
          .desktop: .sm,
        },
      );
      const b = CoreResponsiveContainerStyle(
        responsiveMaxWidth: {
          .mobile: .md,
          .tablet: .sm,
          .desktop: .sm,
        },
      );

      expect(a == b, isFalse);
    });

    test('unequal when one side has a null responsiveMaxWidth', () {
      const a = CoreResponsiveContainerStyle(
        responsiveMaxWidth: _kFullMap,
      );
      const b = CoreResponsiveContainerStyle();

      expect(a == b, isFalse);
    });
  });
}
