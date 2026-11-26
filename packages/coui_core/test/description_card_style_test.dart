// Tests for CoreDescriptionCardStyle / CoreDescriptionCardTheme
// (Epic #1370 phase 5 — flat-style + nested CoreTextStyle slot 통합).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kBgSurface = CoreColor.token(CoreColors.surface);
const _kBgPrimary = CoreColor.token(CoreColors.primary);
const _kBorderOutline = CoreColor.token(CoreColors.outline);
const _kBorderPrimary = CoreColor.token(CoreColors.primary);
const _kDividerOutline = CoreColor.token(CoreColors.outline);
const _kDividerError = CoreColor.token(CoreColors.error);
const List<CoreShadowLayer> _kShadowSoft = CoreShadow.xs;
const List<CoreShadowLayer> _kShadowHard = CoreShadow.md;

const double _kBorderWidthThin = 1;
const double _kBorderWidthThick = 2;
const _kPaddingSm = CoreEdgeInsets.all(12);
const _kPaddingMd = CoreEdgeInsets.all(16);
const _kRadiusSm = CoreBorderRadius.circular(8);
const _kRadiusMd = CoreBorderRadius.circular(16);

const _kLabelText = CoreTextStyle(
  fontSize: 14,
  fontWeight: CoreFontWeight.regular,
  color: CoreColor.token(CoreColors.onSurfaceVariant),
);

const _kValueText = CoreTextStyle(
  fontSize: 14,
  fontWeight: CoreFontWeight.medium,
  color: CoreColor.token(CoreColors.onSurface),
);

const _kEmphasizedLabelText = CoreTextStyle(
  fontWeight: CoreFontWeight.semiBold,
);

const _kEmphasizedValueText = CoreTextStyle(
  fontWeight: CoreFontWeight.bold,
  color: CoreColor.token(CoreColors.primary),
);

typedef _Style = CoreDescriptionCardStyle;
typedef _Theme = CoreDescriptionCardTheme;

void main() {
  group('CoreDescriptionCardStyle.merge', () {
    test('null other returns this', () {
      const a = _Style(backgroundColor: _kBgSurface);
      expect(a.merge(null), same(a));
    });

    test('right-most non-null wins on flat chrome fields', () {
      const base = _Style(
        backgroundColor: _kBgSurface,
        borderColor: _kBorderOutline,
        borderWidth: _kBorderWidthThin,
        borderRadius: _kRadiusSm,
        padding: _kPaddingSm,
        boxShadow: _kShadowSoft,
        dividerColor: _kDividerOutline,
      );
      const over = _Style(
        backgroundColor: _kBgPrimary,
        borderColor: _kBorderPrimary,
        borderWidth: _kBorderWidthThick,
        borderRadius: _kRadiusMd,
        padding: _kPaddingMd,
        boxShadow: _kShadowHard,
        dividerColor: _kDividerError,
      );
      final merged = base.merge(over);
      expect(merged.backgroundColor, _kBgPrimary);
      expect(merged.borderColor, _kBorderPrimary);
      expect(merged.borderWidth, _kBorderWidthThick);
      expect(merged.borderRadius, _kRadiusMd);
      expect(merged.padding, _kPaddingMd);
      expect(merged.boxShadow, _kShadowHard);
      expect(merged.dividerColor, _kDividerError);
    });

    test('null fields in other inherit from base', () {
      const base = _Style(
        backgroundColor: _kBgSurface,
        borderRadius: _kRadiusSm,
      );
      const over = _Style(borderRadius: _kRadiusMd);
      final merged = base.merge(over);
      expect(merged.backgroundColor, _kBgSurface);
      expect(merged.borderRadius, _kRadiusMd);
    });

    test('labelTextStyle merges recursively (other overrides per field)', () {
      const base = _Style(labelTextStyle: _kLabelText);
      const over = _Style(
        labelTextStyle: CoreTextStyle(color: CoreColor.token(CoreColors.error)),
      );
      final merged = base.merge(over);
      // Base fontSize/fontWeight inherited, color overridden.
      expect(merged.labelTextStyle!.fontSize, 14);
      expect(merged.labelTextStyle!.fontWeight, CoreFontWeight.regular);
      expect(
        merged.labelTextStyle!.color,
        const CoreColor.token(CoreColors.error),
      );
    });

    test('valueTextStyle merges recursively', () {
      const base = _Style(valueTextStyle: _kValueText);
      const over = _Style(
        valueTextStyle: CoreTextStyle(
          fontWeight: CoreFontWeight.bold,
        ),
      );
      final merged = base.merge(over);
      expect(merged.valueTextStyle!.fontSize, 14);
      expect(
        merged.valueTextStyle!.color,
        const CoreColor.token(CoreColors.onSurface),
      );
      expect(merged.valueTextStyle!.fontWeight, CoreFontWeight.bold);
    });

    test('emphasizedLabelTextStyle / emphasizedValueTextStyle merge', () {
      const base = _Style(
        emphasizedLabelTextStyle: _kEmphasizedLabelText,
        emphasizedValueTextStyle: _kEmphasizedValueText,
      );
      const over = _Style(
        emphasizedValueTextStyle: CoreTextStyle(
          color: CoreColor.token(CoreColors.error),
        ),
      );
      final merged = base.merge(over);
      // emphasizedLabel inherits entirely.
      expect(merged.emphasizedLabelTextStyle, _kEmphasizedLabelText);
      // emphasizedValue: bold preserved, color overridden.
      expect(merged.emphasizedValueTextStyle!.fontWeight, CoreFontWeight.bold);
      expect(
        merged.emphasizedValueTextStyle!.color,
        const CoreColor.token(CoreColors.error),
      );
    });

    test('merge with null nested slot keeps base nested slot', () {
      const base = _Style(labelTextStyle: _kLabelText);
      const over = _Style();
      final merged = base.merge(over);
      expect(merged.labelTextStyle, _kLabelText);
    });

    test('merge with null base nested slot picks up other slot', () {
      const base = _Style();
      const over = _Style(labelTextStyle: _kLabelText);
      final merged = base.merge(over);
      expect(merged.labelTextStyle, _kLabelText);
    });
  });

  group('CoreDescriptionCardStyle.copyWith', () {
    test('preserves existing values when no overrides supplied', () {
      const original = _Style(
        backgroundColor: _kBgSurface,
        labelTextStyle: _kLabelText,
      );
      final copy = original.copyWith();
      expect(copy.backgroundColor, _kBgSurface);
      expect(copy.labelTextStyle, _kLabelText);
    });

    test('overrides individual fields', () {
      const original = _Style(backgroundColor: _kBgSurface);
      final copy = original.copyWith(backgroundColor: _kBgPrimary);
      expect(copy.backgroundColor, _kBgPrimary);
    });
  });

  group('CoreDescriptionCardStyle equality / hashCode', () {
    test('identical styles compare equal', () {
      const a = _Style(
        backgroundColor: _kBgSurface,
        labelTextStyle: _kLabelText,
        emphasizedValueTextStyle: _kEmphasizedValueText,
      );
      const b = _Style(
        backgroundColor: _kBgSurface,
        labelTextStyle: _kLabelText,
        emphasizedValueTextStyle: _kEmphasizedValueText,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different chrome fields are not equal', () {
      const a = _Style(backgroundColor: _kBgSurface);
      const b = _Style(backgroundColor: _kBgPrimary);
      expect(a, isNot(equals(b)));
    });

    test('different nested label text style is not equal', () {
      const a = _Style(labelTextStyle: _kLabelText);
      const b = _Style(
        labelTextStyle: CoreTextStyle(color: CoreColor.token(CoreColors.error)),
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreDescriptionCardTheme', () {
    test('default constructor has null style', () {
      const theme = _Theme();
      expect(theme.style, isNull);
    });

    test('style passthrough', () {
      const style = _Style(backgroundColor: _kBgSurface);
      const theme = _Theme(style: style);
      expect(theme.style, same(style));
    });

    test('equality and hashCode follow style', () {
      const themeA = _Theme(style: _Style(backgroundColor: _kBgSurface));
      const themeB = _Theme(style: _Style(backgroundColor: _kBgSurface));
      const themeC = _Theme(style: _Style(backgroundColor: _kBgPrimary));
      expect(themeA, equals(themeB));
      expect(themeA.hashCode, equals(themeB.hashCode));
      expect(themeA, isNot(equals(themeC)));
    });
  });

  // #3773 — `defaultsBySize[size]!` is a Map lookup, not a `switch`, so
  // Dart's exhaustiveness checker never sees it. This group is the net
  // — it fails the moment a member is added without a matching entry,
  // before any `!` ever gets a chance to throw at runtime.
  group('CoreDescriptionCardStyle.defaultsBySize (#3773)', () {
    test('covers every CoreDescriptionCardSize member', () {
      for (final size in CoreDescriptionCardSize.values) {
        expect(
          CoreDescriptionCardStyle.defaultsBySize[size],
          isNotNull,
          reason:
              'missing size chrome for CoreDescriptionCardSize.${size.name}'
              ' — every `defaultsBySize[size]!` lookup in the resolvers '
              'assumes full coverage and would crash at runtime',
        );
      }
    });

    test('has exactly one entry per CoreDescriptionCardSize member', () {
      expect(
        CoreDescriptionCardStyle.defaultsBySize.length,
        CoreDescriptionCardSize.values.length,
      );
    });
  });

  group('CoreDescriptionCardStyle.defaultsBySize title', () {
    // The title heads the card, so it is drawn a size above the label at
    // every rung — a title the label's own size reads as one more row.
    for (final size in CoreDescriptionCardSize.values) {
      test('${size.name}: title is larger than the label', () {
        final row = CoreDescriptionCardStyle.defaultsBySize[size]!;
        expect(
          row.titleTextStyle!.fontSize,
          greaterThan(row.labelTextStyle!.fontSize!),
        );
      });
    }
  });

  group('CoreDescriptionCardStyle redesign defaults', () {
    test('outlined line is outline-variant, filled face surfaceContainer', () {
      final outlined =
          _Style.defaultsByVariant[CoreDescriptionCardVariant.outlined]!;
      final filled =
          _Style.defaultsByVariant[CoreDescriptionCardVariant.filled]!;
      expect(outlined.borderColor!.token, CoreColors.outlineVariant);
      expect(filled.backgroundColor!.token, CoreColors.surfaceContainer);
    });

    // #6470 — rows sit edge to edge (spacing 0) and carry their own
    // vertical inset; the card's padding, corner and section gap step
    // with the size.
    const sizes = CoreDescriptionCardSize.values;
    const padding = [12.0, 14.0, 16.0, 18.0, 20.0];
    const radius = [12.0, 14.0, 16.0, 16.0, 16.0];
    const sectionGap = [8.0, 8.0, 10.0, 10.0, 12.0];
    const rowInset = [6.0, 6.0, 8.0, 8.0, 10.0];
    const iconSize = [16.0, 16.0, 18.0, 20.0, 20.0];
    for (var i = 0; i < sizes.length; i += 1) {
      test('${sizes[i].name}: #6470 size row', () {
        final row = _Style.defaultsBySize[sizes[i]]!;
        expect(row.padding, CoreEdgeInsets.all(padding[i]));
        expect(row.borderRadius, CoreBorderRadius.all(radius[i]));
        expect(row.titleContentGapStyle!.size, sectionGap[i]);
        expect(row.rowSpacing, CoreSpace.space0);
        expect(row.rowPadding, CoreEdgeInsets.symmetric(vertical: rowInset[i]));
        expect(row.iconLabelGapStyle!.size, CoreSpace.space8);
        expect(row.titleLeadingIconStyle!.size, iconSize[i]);
        expect(
          row.titleLeadingIconStyle!.color!.token,
          CoreColors.onSurfaceVariant,
        );
      });
    }

    test('title is SemiBold, value aligns to the end', () {
      expect(_Style.defaultTitleTextStyle.fontWeight, CoreFontWeight.semiBold);
      expect(_Style.defaultTitleTextStyle.fontSize, isNull);
      expect(_Style.defaultValueTextAlign, CoreTextAlign.end);
    });

    test('disabled: content dims to opacity/disabled, Clickable does not', () {
      expect(_Style.defaultDisabledContentOpacity, CoreOpacity.disabled);
      expect(
        _Style.defaultClickableStyle.disabledOpacity,
        CoreOpacity.opacity100,
      );
      const a = CoreDescriptionCardStyle(disabledContentOpacity: 0.3);
      expect(
        const CoreDescriptionCardStyle().merge(a).disabledContentOpacity,
        0.3,
      );
      expect(a, isNot(const CoreDescriptionCardStyle()));
      expect(a.hashCode, a.copyWith().hashCode);
      expect(
        const CoreDescriptionCardStyle()
            .copyWith(disabledContentOpacity: 0.3)
            .disabledContentOpacity,
        0.3,
      );
    });

    test('enabled follows the tap target; only explicit false dims', () {
      expect(
        CoreDescriptionCardContract.effectiveEnabled(
          enabled: null,
          hasTapTarget: true,
        ),
        isTrue,
      );
      expect(
        CoreDescriptionCardContract.effectiveEnabled(
          enabled: null,
          hasTapTarget: false,
        ),
        isFalse,
      );
      expect(
        CoreDescriptionCardContract.effectiveEnabled(
          enabled: false,
          hasTapTarget: true,
        ),
        isFalse,
      );
      expect(
        CoreDescriptionCardContract.dimsContent(
          enabled: false,
          hasTapTarget: true,
        ),
        isTrue,
      );
      expect(
        CoreDescriptionCardContract.dimsContent(
          enabled: false,
          hasTapTarget: false,
        ),
        isFalse,
      );
      expect(
        CoreDescriptionCardContract.dimsContent(
          enabled: null,
          hasTapTarget: true,
        ),
        isFalse,
      );
    });

    test('ghost drops the left / right inset; the others keep it', () {
      const sizePadding = CoreEdgeInsets.all(CoreSpace.space16);
      expect(
        _Style.defaultsByVariant[CoreDescriptionCardVariant.ghost]!.paddingFor(
          sizePadding,
        ),
        const CoreEdgeInsets.fromLTRB(0, 16, 0, 16),
      );
      for (final v in [
        CoreDescriptionCardVariant.filled,
        CoreDescriptionCardVariant.outlined,
      ]) {
        expect(
          _Style.defaultsByVariant[v]!.paddingFor(sizePadding),
          sizePadding,
        );
      }
    });

    test('new fields take part in merge / copyWith / ==', () {
      const a = CoreDescriptionCardStyle(
        rowPadding: CoreEdgeInsets.all(CoreSpace.space4),
        titleLeadingIconStyle: CoreIconStyle(size: CoreSize.size24),
        valueTextAlign: CoreTextAlign.start,
      );
      final merged = const CoreDescriptionCardStyle(
        titleLeadingIconStyle: CoreIconStyle(
          color: CoreColor.token(CoreColors.primary),
        ),
      ).merge(a);
      expect(merged.rowPadding, a.rowPadding);
      expect(merged.valueTextAlign, CoreTextAlign.start);
      expect(merged.titleLeadingIconStyle!.size, CoreSize.size24);
      expect(merged.titleLeadingIconStyle!.color!.token, CoreColors.primary);
      expect(
        const CoreDescriptionCardStyle().copyWith(
          valueTextAlign: CoreTextAlign.start,
        ),
        isNot(const CoreDescriptionCardStyle()),
      );
      expect(a, a.copyWith());
      expect(a.hashCode, a.copyWith().hashCode);
    });

    test('label is Regular, value is Medium and never smaller than label', () {
      for (final size in CoreDescriptionCardSize.values) {
        final style = _Style.defaultsBySize[size]!;
        expect(style.labelTextStyle!.fontWeight, CoreFontWeight.regular);
        expect(style.valueTextStyle!.fontWeight, CoreFontWeight.medium);
        expect(
          style.valueTextStyle!.fontSize,
          greaterThanOrEqualTo(style.labelTextStyle!.fontSize!),
        );
      }
    });
  });
}
