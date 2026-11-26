// Tests for CoreChipStyle (Epic #1302 — Story #1318).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const int _kWeightSemiBold = CoreFontWeight.semiBold;
const _kColorOnSurface = CoreColor.token(CoreColors.onSurface);
const _kColorTokenSurface = CoreColor.token(CoreColors.surface);
const _kPaddingSmall = CoreEdgeInsets.symmetric(horizontal: 8);
const _kPaddingTiny = CoreEdgeInsets.symmetric(horizontal: 4);
const double _kIconSize = 16;
const double _kIconSizeLarge = 20;

void main() {
  group('CoreChipStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreChipStyle(
        backgroundColor: _kColorTokenSurface,
        labelStyle: CoreTextStyle(color: _kColorOnSurface),
        leadingIconStyle: CoreIconStyle(size: _kIconSize),
        closeButtonStyle: CoreButtonStyle(padding: _kPaddingTiny),
      );
      const themeStyle = CoreChipStyle(
        labelStyle: CoreTextStyle(fontWeight: _kWeightSemiBold),
      );
      const widgetStyle = CoreChipStyle(
        closeButtonStyle: CoreButtonStyle(padding: _kPaddingSmall),
      );

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.backgroundColor, _kColorTokenSurface);
      expect(effective.labelStyle?.color, _kColorOnSurface);
      expect(effective.labelStyle?.fontWeight, _kWeightSemiBold);
      expect(effective.leadingIconStyle?.size, _kIconSize);
      expect(effective.closeButtonStyle?.padding, _kPaddingSmall);
    });

    test('trailingIconStyle / closeButtonStyle separate slots', () {
      const a = CoreChipStyle(
        trailingIconStyle: CoreIconStyle(size: _kIconSize),
        closeButtonStyle: CoreButtonStyle(padding: _kPaddingTiny),
      );
      const b = CoreChipStyle(
        trailingIconStyle: CoreIconStyle(size: _kIconSizeLarge),
      );
      final merged = a.merge(b);
      expect(merged.trailingIconStyle?.size, _kIconSizeLarge);
      expect(merged.closeButtonStyle?.padding, _kPaddingTiny);
    });

    test('null nested style on base inherits from override', () {
      const base = CoreChipStyle();
      const override = CoreChipStyle(
        closeButtonStyle: CoreButtonStyle(padding: _kPaddingTiny),
      );
      final merged = base.merge(override);
      expect(merged.closeButtonStyle?.padding, _kPaddingTiny);
    });

    test('equality + different closeButtonStyle → not equal', () {
      const a = CoreChipStyle(
        closeButtonStyle: CoreButtonStyle(padding: _kPaddingTiny),
      );
      const b = CoreChipStyle(
        closeButtonStyle: CoreButtonStyle(padding: _kPaddingSmall),
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreChipTheme passes through style', () {
    test('CoreChipTheme', () {
      const style = CoreChipStyle(backgroundColor: _kColorTokenSurface);
      const theme = CoreChipTheme(style: style);
      expect(theme.style, style);
    });
  });

  // #3773 — `defaultsBySize[size]!` is a Map lookup, not a `switch`, so
  // Dart's exhaustiveness checker never sees it. This group is the net
  // — it fails the moment a member is added without a matching entry,
  // before any `!` ever gets a chance to throw at runtime.
  group('CoreChipStyle.defaultsBySize (#3773)', () {
    test('covers every CoreChipSize member — and only those', () {
      // Three tiers, not the shared six: 24 is Badge's row and 48 / 56 are
      // Button's. Every `defaultsBySize[size]!` lookup in the resolvers
      // assumes full coverage and would crash at runtime on a hole.
      for (final size in CoreChipSize.values) {
        expect(
          CoreChipStyle.defaultsBySize[size],
          isNotNull,
          reason: size.name,
        );
      }
      expect(CoreChipStyle.defaultsBySize.length, CoreChipSize.values.length);
    });

    test('every row states its corner · padding · icons (the ladder)', () {
      // The corner is the chip's own height × 0.25 on a `CoreRadius` rung
      // (28 → 6, 32 → 8, 40 → 10); the inline padding 10 · 12 · 14; the 2px
      // vertical padding on every tier; the leading and trailing icons
      // 12 · 14 · 16. Stated per row, so a resolver reads
      // `merged.borderRadius` and never needs a size-independent fallback.
      const corners = {
        CoreChipSize.sm: CoreRadius.radius6,
        CoreChipSize.md: CoreRadius.radius8,
        CoreChipSize.lg: CoreRadius.radius10,
      };
      const inline = {
        CoreChipSize.sm: CoreSpace.space10,
        CoreChipSize.md: CoreSpace.space12,
        CoreChipSize.lg: CoreSpace.space14,
      };
      for (final size in CoreChipSize.values) {
        final row = CoreChipStyle.defaultsBySize[size]!;
        expect(
          row.borderRadius,
          CoreBorderRadius.all(corners[size]!),
          reason: '${size.name} corner',
        );
        expect(
          row.padding,
          CoreEdgeInsets.symmetric(
            horizontal: inline[size]!,
            vertical: CoreSpace.space2,
          ),
          reason: '${size.name} padding',
        );
      }
    });

    test('the size-less corner is retired — rows read through merge', () {
      // A chip folded from a size row and a caller's `borderRadius` takes the
      // caller's; a chip with none takes the row's. Nothing falls back to the
      // deprecated size-less pill.
      const pill = CoreBorderRadius.all(CoreRadius.radius9999);
      for (final size in CoreChipSize.values) {
        final row = CoreChipStyle.defaultsBySize[size]!;
        final plain = const CoreChipStyle().merge(row);
        expect(plain.borderRadius, row.borderRadius, reason: size.name);
        expect(plain.borderRadius, isNot(pill), reason: size.name);
        final stated = plain.merge(const CoreChipStyle(borderRadius: pill));
        expect(stated.borderRadius, pill, reason: '${size.name} caller pill');
      }
    });

    test('the clickable default states no corner — the face supplies it', () {
      // The focus ring follows the corner the face is drawn with, which is a
      // per-size row value; a corner here would pin it to one size's.
      expect(CoreChipStyle.defaultClickableStyle.borderRadius, isNull);
      expect(
        CoreChipStyle.defaultClickableStyle.disabledOpacity,
        CoreOpacity.opacity100,
      );
    });
  });

  // #5630 — the pill is a shape, not a size-less corner value. The shape's
  // row is laid over the size row, the order both resolvers merge in, and a
  // corner the theme or the instance states goes on top of both.
  group('CoreChipStyle.defaultsByShape (#5630)', () {
    const pill = CoreBorderRadius.all(CoreRadius.radius9999);

    CoreBorderRadius? cornerOf(
      CoreChipSize size,
      CoreChipShape shape, {
      CoreChipStyle? override,
    }) => const CoreChipStyle()
        .merge(CoreChipStyle.defaultsBySize[size])
        .merge(CoreChipStyle.defaultsByShape[shape])
        .merge(override)
        .borderRadius;

    test("the widget default is rounded — today's look", () {
      expect(CoreChipShape.defaultShape, CoreChipShape.rounded);
    });

    test('covers every CoreChipShape member — and only those', () {
      expect(
        CoreChipStyle.defaultsByShape.keys,
        unorderedEquals(CoreChipShape.values),
      );
    });

    test('rounded states nothing — every size keeps its row corner', () {
      expect(
        CoreChipStyle.defaultsByShape[CoreChipShape.rounded],
        const CoreChipStyle(),
      );
      for (final size in CoreChipSize.values) {
        expect(
          cornerOf(size, .rounded),
          CoreChipStyle.defaultsBySize[size]!.borderRadius,
          reason: size.name,
        );
      }
    });

    test('pill states only the full corner — the same on every size', () {
      // Equality over the whole style: the pill changes the corner and
      // nothing else a size row states (padding, floor, icons, label).
      expect(
        CoreChipStyle.defaultsByShape[CoreChipShape.pill],
        const CoreChipStyle(borderRadius: pill),
      );
      for (final size in CoreChipSize.values) {
        expect(cornerOf(size, .pill), pill, reason: size.name);
      }
    });

    test('a stated corner wins over both shapes', () {
      const stated = CoreBorderRadius.all(CoreRadius.radius4);
      for (final size in CoreChipSize.values) {
        for (final shape in CoreChipShape.values) {
          expect(
            cornerOf(
              size,
              shape,
              override: const CoreChipStyle(borderRadius: stated),
            ),
            stated,
            reason: '${size.name} ${shape.name}',
          );
        }
      }
    });
  });
}
