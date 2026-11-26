// Tests for CoreToastStyle (Epic #1302 — Story #1310 Toast).
// ignore_for_file: avoid_redundant_argument_values

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kRadiusSm = CoreBorderRadius.all(4);
const _kRadiusLg = CoreBorderRadius.all(12);
const _kPaddingSm = CoreEdgeInsets.all(12);
const _kPaddingLg = CoreEdgeInsets.all(16);
const _kGapSm = CoreGapStyle(size: 8);
const _kGapLg = CoreGapStyle(size: 12);

const _kBgSurface = CoreColor.token(CoreColors.surface);
const _kBgError = CoreColor.token(CoreColors.error);
const _kBorderOutline = CoreColor.token(CoreColors.outline);

const double _kFontTitle = 14;
const int _kWeightSemiBold = CoreFontWeight.semiBold;
const int _kWeightRegular = CoreFontWeight.regular;
const _kColorOnSurface = CoreColor.token(CoreColors.onSurface);
const _kColorOnSurfaceVariant = CoreColor.token(CoreColors.onSurfaceVariant);

void main() {
  group('CoreToastStyle.merge', () {
    test('null other returns this', () {
      const a = CoreToastStyle(
        panelBackgroundColor: _kBgSurface,
        panelBorderRadius: _kRadiusLg,
      );
      expect(identical(a.merge(null), a), isTrue);
    });

    test('chain — design system → theme.style → variantStyles → widget', () {
      const designSystem = CoreToastStyle(
        panelBackgroundColor: _kBgSurface,
        panelBorderColor: _kBorderOutline,
        panelBorderRadius: _kRadiusSm,
        panelPadding: _kPaddingSm,
        contentActionGapStyle: _kGapSm,
      );
      const themeStyle = CoreToastStyle(
        panelBorderRadius: _kRadiusLg,
      );
      const variantStyle = CoreToastStyle(
        panelBackgroundColor: _kBgError,
      );
      const widgetStyle = CoreToastStyle(
        panelPadding: _kPaddingLg,
      );

      final effective = designSystem
          .merge(themeStyle)
          .merge(variantStyle)
          .merge(widgetStyle);

      expect(effective.panelBackgroundColor, _kBgError); // variant
      expect(effective.panelBorderColor, _kBorderOutline);
      expect(effective.panelBorderRadius, _kRadiusLg); // theme
      expect(effective.panelPadding, _kPaddingLg); // widget
      expect(effective.contentActionGapStyle, _kGapSm);
    });

    test('right-most non-null wins on each field', () {
      const a = CoreToastStyle(
        panelPadding: _kPaddingSm,
        contentActionGapStyle: _kGapSm,
      );
      const b = CoreToastStyle(panelPadding: _kPaddingLg);
      const c = CoreToastStyle(contentActionGapStyle: _kGapLg);

      final result = a.merge(b).merge(c);

      expect(result.panelPadding, _kPaddingLg);
      expect(result.contentActionGapStyle, _kGapLg);
    });

    test('messageStyle / descriptionStyle merge recursively', () {
      const base = CoreToastStyle(
        messageStyle: CoreTextStyle(
          fontSize: _kFontTitle,
          fontWeight: _kWeightSemiBold,
          color: _kColorOnSurface,
        ),
        descriptionStyle: CoreTextStyle(
          color: _kColorOnSurfaceVariant,
        ),
      );
      const override = CoreToastStyle(
        messageStyle: CoreTextStyle(fontWeight: _kWeightRegular),
        descriptionStyle: CoreTextStyle(color: _kColorOnSurface),
      );
      final merged = base.merge(override);
      expect(merged.messageStyle?.fontSize, _kFontTitle);
      expect(merged.messageStyle?.fontWeight, _kWeightRegular);
      expect(merged.messageStyle?.color, _kColorOnSurface);
      expect(merged.descriptionStyle?.color, _kColorOnSurface);
    });

    test('actionButtonStyle merges recursively', () {
      const base = CoreToastStyle(
        actionButtonStyle: CoreButtonStyle(
          backgroundColor: _kBgSurface,
          padding: CoreEdgeInsets.symmetric(horizontal: 16),
        ),
      );
      const override = CoreToastStyle(
        actionButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 24),
        ),
      );
      final merged = base.merge(override);
      expect(
        merged.actionButtonStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 24),
      );
      expect(merged.actionButtonStyle?.backgroundColor, _kBgSurface);
    });

    test('null nested style on base inherits from override', () {
      const base = CoreToastStyle();
      const override = CoreToastStyle(
        messageStyle: CoreTextStyle(fontSize: _kFontTitle),
      );
      final merged = base.merge(override);
      expect(merged.messageStyle?.fontSize, _kFontTitle);
    });
  });

  group('CoreToastStyle equality', () {
    test('same fields → equal', () {
      const a = CoreToastStyle(
        panelBackgroundColor: _kBgSurface,
        panelBorderRadius: _kRadiusLg,
      );
      const b = CoreToastStyle(
        panelBackgroundColor: _kBgSurface,
        panelBorderRadius: _kRadiusLg,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different panelBackgroundColor → not equal', () {
      const a = CoreToastStyle(panelBackgroundColor: _kBgSurface);
      const b = CoreToastStyle(panelBackgroundColor: _kBgError);
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreToastStyle.copyWith', () {
    test('only-supplied fields override', () {
      const base = CoreToastStyle(
        panelBackgroundColor: _kBgSurface,
        panelPadding: _kPaddingLg,
        contentActionGapStyle: _kGapSm,
      );
      final copy = base.copyWith(contentActionGapStyle: _kGapLg);
      expect(copy.panelBackgroundColor, _kBgSurface);
      expect(copy.panelPadding, _kPaddingLg);
      expect(copy.contentActionGapStyle, _kGapLg);
    });

    test('preserves nested styles when not specified', () {
      const base = CoreToastStyle(
        messageStyle: CoreTextStyle(fontSize: _kFontTitle),
        actionButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 16),
        ),
      );
      final copy = base.copyWith(panelPadding: _kPaddingSm);
      expect(copy.panelPadding, _kPaddingSm);
      expect(copy.messageStyle?.fontSize, _kFontTitle);
      expect(
        copy.actionButtonStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 16),
      );
    });
  });

  group('CoreToastTheme', () {
    test('style + variantStyles pass through', () {
      const style = CoreToastStyle(panelPadding: _kPaddingLg);
      const variantStyle = CoreToastStyle(panelBackgroundColor: _kBgError);
      const theme = CoreToastTheme(
        style: style,
        variantStyles: {
          .success: variantStyle,
          .destructive: variantStyle,
        },
      );
      expect(theme.style, style);
      expect(
        theme.variantStyles![CoreToastVariant.destructive],
        variantStyle,
      );
    });

    test('null fields', () {
      const theme = CoreToastTheme();
      expect(theme.style, isNull);
      expect(theme.variantStyles, isNull);
    });

    test('equality', () {
      const a = CoreToastTheme(
        style: CoreToastStyle(panelPadding: _kPaddingLg),
      );
      const b = CoreToastTheme(
        style: CoreToastStyle(panelPadding: _kPaddingLg),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('defaults', () {
    test('the panel is a surface-role bubble, 44 high at least', () {
      expect(
        CoreToastStyle.defaultPanelBorderRadius,
        const CoreBorderRadius.all(CoreRadiusRole.surface),
      );
      expect(CoreToastStyle.defaultPanelBorderRadius.topLeft, 16);
      expect(CoreToastStyle.defaultMinHeight, 44);
    });

    test('the glyph and the text are 10 apart', () {
      expect(CoreToastStyle.defaultIconContentGapStyle.size, 10);
    });

    test('the message is labelLarge with a semibold overlay', () {
      expect(
        CoreToastStyle.defaultMessageStyle.token,
        CoreTextStyles.labelLarge,
      );
      expect(
        CoreToastStyle.defaultMessageStyle.fontWeight,
        CoreFontWeight.semiBold,
      );
    });

    test('the bubble is 18 inline and 14 block, the close side 48', () {
      expect(
        CoreToastStyle.defaultPanelPadding,
        const CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space18,
          vertical: CoreSpace.space14,
        ),
      );
      expect(
        CoreToastStyle.defaultPanelPaddingWithDismiss,
        const CoreEdgeInsets.directional(
          start: CoreSpace.space18,
          top: CoreSpace.space14,
          end: CoreSpace.space48,
          bottom: CoreSpace.space14,
        ),
      );
    });

    test('the message and description are 2 apart', () {
      expect(CoreToastStyle.defaultMessageDescriptionGapStyle.size, 2);
    });

    test('the bubble casts the small shadow', () {
      expect(CoreToastStyle.defaultPanelBoxShadow, CoreShadow.sm);
    });

    test('the close button is a circle — Banner\'s dismiss shape', () {
      expect(
        CoreToastStyle.defaultCloseButtonStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius9999),
      );
      // The square shape reads its own zero inset, not a forwarded one.
      expect(CoreToastStyle.defaultCloseButtonStyle.padding, isNull);
    });

    test(
      'the close sits 8 from the trailing edge, centred on the block axis',
      () {
        expect(
          CoreToastStyle.defaultCloseInset,
          const CoreEdgeInsets.symmetric(horizontal: CoreSpace.space8),
        );
      },
    );
  });

  group('the bubble is the inverse pair', () {
    test('fill and edge are inverse-surface, text inverse-on-surface', () {
      for (final variant in CoreToastVariant.values) {
        final row = CoreToastStyle.defaultsByVariant[variant]!;
        expect(
          row.backgroundColor,
          const CoreColor.token(CoreColors.inverseSurface),
          reason: variant.name,
        );
        expect(
          row.borderColor,
          const CoreColor.token(CoreColors.inverseSurface),
          reason: variant.name,
        );
        expect(
          row.foregroundColor,
          const CoreColor.token(CoreColors.inverseOnSurface),
          reason: variant.name,
        );
      }
    });

    test('the description rests at 75 %, the close glyph at 70 %', () {
      for (final variant in CoreToastVariant.values) {
        final row = CoreToastStyle.defaultsByVariant[variant]!;
        expect(
          row.descriptionForeground,
          const CoreColor.token(
            CoreColors.inverseOnSurface,
            opacity: CoreOpacity.opacity75,
          ),
          reason: variant.name,
        );
        expect(
          row.closeForeground,
          const CoreColor.token(
            CoreColors.inverseOnSurface,
            opacity: CoreOpacity.opacity70,
          ),
          reason: variant.name,
        );
        expect(
          row.closeHoverForeground,
          const CoreColor.token(CoreColors.inverseOnSurface),
          reason: variant.name,
        );
      }
    });
  });
}
