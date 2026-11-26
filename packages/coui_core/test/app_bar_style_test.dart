// Tests for CoreAppBarStyle / CoreAppBarTheme (AppBar Core contract).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kSurface = CoreColor.token(CoreColors.surface);
const _kOnSurface = CoreColor.token(CoreColors.onSurface);
const _kPrimary = CoreColor.token(CoreColors.primary);
const _kOutline = CoreColor.token(CoreColors.outline);

const double _kSpacingSm = CoreSpace.space4;
const double _kSpacingLg = CoreSpace.space8;
const double _kHeightStandard = CoreSize.size64;
const double _kHeightCompact = CoreSize.size56;
const double _kHeightMedium = CoreSize.size112;
const double _kHeightDense = CoreSize.size48;
const double _kDividerThin = CoreStrokeWidth.stroke1;
const double _kDividerBold = CoreStrokeWidth.stroke2;

const _kPaddingSm = CoreEdgeInsets.symmetric(horizontal: CoreSpace.space8);
const _kPaddingLg = CoreEdgeInsets.symmetric(horizontal: CoreSpace.space16);

void main() {
  group('CoreAppBarStyle.merge', () {
    test('null other returns this', () {
      const a = CoreAppBarStyle(
        backgroundColor: _kSurface,
        height: _kHeightStandard,
      );
      expect(identical(a.merge(null), a), isTrue);
    });

    test('right-most non-null wins on each field', () {
      const a = CoreAppBarStyle(
        height: _kHeightStandard,
        spacing: _kSpacingSm,
        dividerWidth: _kDividerThin,
      );
      const b = CoreAppBarStyle(height: _kHeightCompact);
      const c = CoreAppBarStyle(spacing: _kSpacingLg);

      final result = a.merge(b).merge(c);

      expect(result.height, _kHeightCompact);
      expect(result.spacing, _kSpacingLg);
      expect(result.dividerWidth, _kDividerThin);
    });

    test('partial override preserves untouched fields', () {
      const base = CoreAppBarStyle(
        backgroundColor: _kSurface,
        padding: _kPaddingSm,
        actionSpacing: _kSpacingSm,
        dividerColor: _kOutline,
        elevatedShadow: CoreShadow.sm,
      );
      const override = CoreAppBarStyle(padding: _kPaddingLg);

      final merged = base.merge(override);

      expect(merged.backgroundColor, _kSurface);
      expect(merged.padding, _kPaddingLg);
      expect(merged.actionSpacing, _kSpacingSm);
      expect(merged.dividerColor, _kOutline);
      expect(merged.elevatedShadow, CoreShadow.sm);
    });

    test('titleStyle merges recursively (subset override keeps token)', () {
      const base = CoreAppBarStyle(
        titleStyle: CoreTextStyle.token(
          CoreTextStyles.titleMedium,
          color: _kOnSurface,
        ),
      );
      const override = CoreAppBarStyle(
        titleStyle: CoreTextStyle(fontWeight: CoreFontWeight.bold),
      );

      final merged = base.merge(override);

      expect(merged.titleStyle?.token, CoreTextStyles.titleMedium);
      expect(merged.titleStyle?.color, _kOnSurface);
      expect(merged.titleStyle?.fontWeight, CoreFontWeight.bold);
    });

    test('null nested titleStyle on base inherits from override', () {
      const base = CoreAppBarStyle();
      const override = CoreAppBarStyle(
        titleStyle: CoreTextStyle.token(CoreTextStyles.titleLarge),
      );
      final merged = base.merge(override);
      expect(merged.titleStyle?.token, CoreTextStyles.titleLarge);
    });
  });

  group('CoreAppBarStyle.copyWith', () {
    test('only-supplied fields override', () {
      const base = CoreAppBarStyle(
        backgroundColor: _kSurface,
        height: _kHeightStandard,
        titlePadding: _kPaddingSm,
      );
      final copy = base.copyWith(height: _kHeightMedium);
      expect(copy.backgroundColor, _kSurface);
      expect(copy.height, _kHeightMedium);
      expect(copy.titlePadding, _kPaddingSm);
    });

    test('round-trips to an equal value when nothing is supplied', () {
      const base = CoreAppBarStyle(
        backgroundColor: _kSurface,
        padding: _kPaddingSm,
        spacing: _kSpacingSm,
        actionSpacing: _kSpacingSm,
        height: _kHeightStandard,
        topRowHeight: _kHeightCompact,
        titleStyle: CoreTextStyle.token(
          CoreTextStyles.titleMedium,
          color: _kOnSurface,
        ),
        titlePadding: _kPaddingSm,
        dividerColor: _kOutline,
        dividerWidth: _kDividerThin,
        elevatedShadow: CoreShadow.sm,
      );
      final copy = base.copyWith();
      expect(copy, equals(base));
      expect(copy.hashCode, base.hashCode);
    });
  });

  group('CoreAppBarStyle equality', () {
    test('same fields → equal', () {
      const a = CoreAppBarStyle(
        backgroundColor: _kSurface,
        height: _kHeightStandard,
        dividerWidth: _kDividerThin,
      );
      const b = CoreAppBarStyle(
        backgroundColor: _kSurface,
        height: _kHeightStandard,
        dividerWidth: _kDividerThin,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('changing one field → not equal', () {
      const a = CoreAppBarStyle(dividerWidth: _kDividerThin);
      const b = CoreAppBarStyle(dividerWidth: _kDividerBold);
      expect(a, isNot(equals(b)));
    });

    test('elevatedShadow compares element-wise, not by identity', () {
      final a = CoreAppBarStyle(elevatedShadow: CoreShadow.sm.toList());
      const b = CoreAppBarStyle(elevatedShadow: CoreShadow.sm);
      expect(a, equals(b));
    });
  });

  group('CoreAppBarStyle.defaultsByVariant', () {
    test('covers every CoreAppBarVariant member', () {
      for (final variant in CoreAppBarVariant.values) {
        expect(
          CoreAppBarStyle.defaultsByVariant[variant],
          isNotNull,
          reason:
              'missing variant chrome for CoreAppBarVariant.${variant.name} '
              '— every `defaultsByVariant[variant]!` lookup in the '
              'resolvers assumes full coverage',
        );
      }
      expect(
        CoreAppBarStyle.defaultsByVariant.length,
        CoreAppBarVariant.values.length,
      );
    });

    test('heights are the designer-measured 64 / 56 / 112 / 48', () {
      expect(
        CoreAppBarStyle.defaultsByVariant[CoreAppBarVariant.standard]!.height,
        _kHeightStandard,
      );
      expect(
        CoreAppBarStyle.defaultsByVariant[CoreAppBarVariant.compact]!.height,
        _kHeightCompact,
      );
      expect(
        CoreAppBarStyle.defaultsByVariant[CoreAppBarVariant.medium]!.height,
        _kHeightMedium,
      );
      expect(
        CoreAppBarStyle.defaultsByVariant[CoreAppBarVariant.dense]!.height,
        _kHeightDense,
      );
    });

    test('compact and dense state a bar padding — 16; standard and medium '
        'read the shared 8', () {
      expect(
        CoreAppBarStyle.defaultsByVariant[CoreAppBarVariant.compact]!.padding,
        _kPaddingLg,
      );
      expect(
        CoreAppBarStyle.defaultsByVariant[CoreAppBarVariant.dense]!.padding,
        _kPaddingLg,
      );
      expect(
        CoreAppBarStyle.defaultsByVariant[CoreAppBarVariant.standard]!.padding,
        isNull,
      );
      expect(
        CoreAppBarStyle.defaultsByVariant[CoreAppBarVariant.medium]!.padding,
        isNull,
      );
      expect(CoreAppBarStyle.defaultPadding, _kPaddingSm);
    });

    test('titleStyle roles are titleMedium / titleMedium / titleLarge / '
        'labelLarge', () {
      expect(
        CoreAppBarStyle
            .defaultsByVariant[CoreAppBarVariant.standard]!
            .titleStyle
            ?.token,
        CoreTextStyles.titleMedium,
      );
      expect(
        CoreAppBarStyle
            .defaultsByVariant[CoreAppBarVariant.compact]!
            .titleStyle
            ?.token,
        CoreTextStyles.titleMedium,
      );
      expect(
        CoreAppBarStyle
            .defaultsByVariant[CoreAppBarVariant.medium]!
            .titleStyle
            ?.token,
        CoreTextStyles.titleLarge,
      );
      expect(
        CoreAppBarStyle
            .defaultsByVariant[CoreAppBarVariant.dense]!
            .titleStyle
            ?.token,
        CoreTextStyles.labelLarge,
      );
    });

    // Every variant states a title inset, and both platforms are supposed to
    // draw it. This is the net under the *other* direction of the Flutter
    // single-row bug: deleting the single-row insets here would make the two
    // platforms agree by taking the value away from Web, and — before this
    // test — nothing in the repo would have said a word.
    test('every variant states a title inset', () {
      for (final variant in CoreAppBarVariant.values) {
        expect(
          CoreAppBarStyle.defaultsByVariant[variant]!.titlePadding,
          isNotNull,
          reason:
              'CoreAppBarVariant.${variant.name} has no titlePadding — the '
              'title would sit flush against the leading cluster',
        );
      }
    });

    test('single-row insets are symmetric space8, medium is 16 / 16 / 12', () {
      for (final variant in [
        CoreAppBarVariant.standard,
        CoreAppBarVariant.compact,
      ]) {
        expect(
          CoreAppBarStyle.defaultsByVariant[variant]!.titlePadding,
          const CoreEdgeInsets.symmetric(horizontal: CoreSpace.space8),
          reason:
              'single-row title inset for CoreAppBarVariant.${variant.name}',
        );
      }
      expect(
        CoreAppBarStyle
            .defaultsByVariant[CoreAppBarVariant.medium]!
            .titlePadding,
        const CoreEdgeInsets.only(
          left: CoreSpace.space16,
          right: CoreSpace.space16,
          bottom: CoreSpace.space12,
        ),
      );
      // Dense states a zero inset: the desktop title bar puts its title one
      // cluster gap away from its neighbours and no further.
      expect(
        CoreAppBarStyle
            .defaultsByVariant[CoreAppBarVariant.dense]!
            .titlePadding,
        CoreEdgeInsets.zero,
      );
    });
  });

  // Dense is the one row that states its own face and cluster gaps — the
  // desktop title bar on the chrome tier. The other rows leave those fields
  // unset so they keep reading the shared defaults; a row that suddenly
  // stated a face would move that variant off `surface` without anyone
  // having decided it.
  group('CoreAppBarStyle.defaultsByVariant — dense', () {
    final dense = CoreAppBarStyle.defaultsByVariant[CoreAppBarVariant.dense]!;

    test('face is surfaceContainerLow; the other rows state none', () {
      expect(
        dense.backgroundColor,
        const CoreColor.token(CoreColors.surfaceContainerLow),
      );
      for (final variant in [
        CoreAppBarVariant.standard,
        CoreAppBarVariant.compact,
        CoreAppBarVariant.medium,
        CoreAppBarVariant.prominent,
      ]) {
        expect(
          CoreAppBarStyle.defaultsByVariant[variant]!.backgroundColor,
          isNull,
          reason: '${variant.name} reads defaultBackgroundColor (surface)',
        );
      }
      expect(CoreAppBarStyle.defaultBackgroundColor, _kSurface);
    });

    test('clusters 14 apart, actions 8 apart; the other rows state none', () {
      expect(dense.spacing, CoreSpace.space14);
      expect(dense.actionSpacing, CoreSpace.space8);
      for (final variant in [
        CoreAppBarVariant.standard,
        CoreAppBarVariant.compact,
        CoreAppBarVariant.medium,
        CoreAppBarVariant.prominent,
      ]) {
        final row = CoreAppBarStyle.defaultsByVariant[variant]!;
        expect(row.spacing, isNull, reason: variant.name);
        expect(row.actionSpacing, isNull, reason: variant.name);
      }
    });

    test('title is labelLarge at semibold, onSurface', () {
      final title = dense.titleStyle!;
      expect(title.token, CoreTextStyles.labelLarge);
      expect(title.fontWeight, CoreFontWeight.semiBold);
      expect(title.color, _kOnSurface);
      // Only the weight is overlaid — size, leading and tracking stay the
      // role's, so the label keeps its optical curve.
      expect(title.fontSize, isNull);
      expect(title.lineHeight, isNull);
      expect(title.letterSpacing, isNull);
    });
  });

  // Prominent is a single row at the compact height whose title is the
  // screen's heading — a large, start-aligned `headlineSmall`. It states the
  // title's 20 inset itself (a 4 bar padding plus a 16 title inset) and no
  // face or cluster gaps, so it stays on `surface` like the other touch bars.
  group('CoreAppBarStyle.defaultsByVariant — prominent', () {
    final prominent =
        CoreAppBarStyle.defaultsByVariant[CoreAppBarVariant.prominent]!;

    test('is a 56px single row — the compact height', () {
      expect(prominent.height, _kHeightCompact);
    });

    test('title is headlineSmall on onSurface, with no overlay', () {
      final title = prominent.titleStyle!;
      expect(title.token, CoreTextStyles.headlineSmall);
      expect(title.color, _kOnSurface);
      // The role carries size, weight, leading and tracking whole — a value
      // written here would put the heading off the type scale.
      expect(title.fontSize, isNull);
      expect(title.fontWeight, isNull);
      expect(title.lineHeight, isNull);
      expect(title.letterSpacing, isNull);
    });

    test('title starts 20 in from the bar edge — 4 bar padding + 16 inset', () {
      expect(
        prominent.padding,
        const CoreEdgeInsets.symmetric(horizontal: CoreSpace.space4),
      );
      expect(
        prominent.titlePadding,
        const CoreEdgeInsets.symmetric(horizontal: CoreSpace.space16),
      );
      expect(CoreSpace.space4 + CoreSpace.space16, 20);
    });

    test('states no face and no cluster gaps', () {
      expect(prominent.backgroundColor, isNull);
      expect(prominent.spacing, isNull);
      expect(prominent.actionSpacing, isNull);
    });

    test('adding it moved no other row', () {
      expect(
        CoreAppBarStyle.defaultsByVariant[CoreAppBarVariant.standard]!.height,
        _kHeightStandard,
      );
      expect(
        CoreAppBarStyle.defaultsByVariant[CoreAppBarVariant.compact]!.padding,
        _kPaddingLg,
      );
      expect(CoreAppBarVariant.defaultVariant, CoreAppBarVariant.standard);
      // New members append — the existing four keep their positions.
      expect(CoreAppBarVariant.values.take(4), [
        CoreAppBarVariant.standard,
        CoreAppBarVariant.compact,
        CoreAppBarVariant.medium,
        CoreAppBarVariant.dense,
      ]);
    });
  });

  group('CoreAppBarTheme', () {
    test('style + variantStyles pass through', () {
      const style = CoreAppBarStyle(backgroundColor: _kSurface);
      const variantStyle = CoreAppBarStyle(backgroundColor: _kPrimary);
      const theme = CoreAppBarTheme(
        style: style,
        variantStyles: {
          .defaultVariant: variantStyle,
        },
      );
      expect(theme.style, style);
      expect(
        theme.variantStyles![CoreAppBarVariant.defaultVariant],
        variantStyle,
      );
    });

    test('null fields', () {
      const theme = CoreAppBarTheme();
      expect(theme.style, isNull);
      expect(theme.variantStyles, isNull);
    });

    test('equality', () {
      const a = CoreAppBarTheme(
        style: CoreAppBarStyle(backgroundColor: _kSurface),
        variantStyles: {
          .defaultVariant: CoreAppBarStyle(backgroundColor: _kPrimary),
        },
      );
      const b = CoreAppBarTheme(
        style: CoreAppBarStyle(backgroundColor: _kSurface),
        variantStyles: {
          .defaultVariant: CoreAppBarStyle(backgroundColor: _kPrimary),
        },
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CoreAppBarStyle.glassActionStyle', () {
    test('keeps the quiet glass line, not the Popup panel line', () {
      expect(
        CoreAppBarStyle.glassActionStyle.borderColor,
        const CoreColor.token(CoreColors.outlineSubtle),
      );
      expect(
        CorePopupStyle.defaultBorderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
    });

    test('is the shared glass capsule plus only that line', () {
      expect(
        CoreAppBarStyle.glassActionStyle,
        CoreToolbarGroupContract.glassPopupStyle.copyWith(
          borderColor: const CoreColor.token(CoreColors.outlineSubtle),
        ),
      );
    });
  });
}
