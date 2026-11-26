// Tests for CorePaginationStyle / CorePaginationTheme.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const double _kFontLabel = 14;
const _kColorPrimary = CoreColor.token(CoreColors.primary);
const _kColorOnPrimary = CoreColor.token(CoreColors.onPrimary);
const _kColorOnSurface = CoreColor.token(CoreColors.onSurface);
const _kColorOutline = CoreColor.token(CoreColors.outline);

void main() {
  group('CorePaginationStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CorePaginationStyle(
        itemSpacing: 4,
        buttonSize: 40,
        activeBackgroundColor: _kColorPrimary,
        activeTextStyle: CoreTextStyle(color: _kColorOnPrimary),
        ellipsisStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      const widgetStyle = CorePaginationStyle(
        itemSpacing: 8,
        textStyle: CoreTextStyle(color: _kColorOnSurface),
      );
      final effective = designSystem.merge(widgetStyle);
      expect(effective.itemSpacing, 8);
      expect(effective.buttonSize, 40);
      expect(effective.activeBackgroundColor, _kColorPrimary);
      expect(effective.activeTextStyle?.color, _kColorOnPrimary);
      expect(effective.textStyle?.color, _kColorOnSurface);
      expect(effective.ellipsisStyle?.fontSize, _kFontLabel);
    });

    test('null field on base inherits from override', () {
      const base = CorePaginationStyle();
      const override = CorePaginationStyle(
        buttonRadius: CoreBorderRadius.all(CoreRadius.radius8),
        textStyle: CoreTextStyle(color: _kColorOnSurface),
      );
      final merged = base.merge(override);
      expect(merged.textStyle?.color, _kColorOnSurface);
      expect(
        merged.buttonRadius,
        const CoreBorderRadius.all(CoreRadius.radius8),
      );
    });

    test('equality + different ellipsisStyle → not equal', () {
      const a = CorePaginationStyle(
        ellipsisStyle: CoreTextStyle(color: _kColorOnSurface),
      );
      const b = CorePaginationStyle(
        ellipsisStyle: CoreTextStyle(color: _kColorOutline),
      );
      expect(a, isNot(equals(b)));
    });

    test('copyWith preserves unchanged fields', () {
      const base = CorePaginationStyle(
        itemSpacing: 8,
        buttonSize: 40,
        activeBackgroundColor: _kColorPrimary,
      );
      final copy = base.copyWith(itemSpacing: 4);
      expect(copy.itemSpacing, 4);
      expect(copy.buttonSize, 40);
      expect(copy.activeBackgroundColor, _kColorPrimary);
    });

    test('hoverDuration override field', () {
      const base = CorePaginationStyle(
        hoverDuration: Duration(milliseconds: 150),
      );
      const override = CorePaginationStyle(
        hoverDuration: Duration(milliseconds: 300),
      );
      final merged = base.merge(override);
      expect(merged.hoverDuration, const Duration(milliseconds: 300));
      final copy = base.copyWith(
        hoverDuration: const Duration(milliseconds: 200),
      );
      expect(copy.hoverDuration, const Duration(milliseconds: 200));
      // Equality + hashCode include hoverDuration.
      const a = CorePaginationStyle(
        hoverDuration: Duration(milliseconds: 150),
      );
      const b = CorePaginationStyle(
        hoverDuration: Duration(milliseconds: 150),
      );
      const c = CorePaginationStyle(
        hoverDuration: Duration(milliseconds: 300),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });
  });

  group('CorePaginationStyle redesign (#5965)', () {
    test('defaults state the redesigned values', () {
      expect(CorePaginationStyle.defaultButtonSize, 36);
      expect(CorePaginationStyle.defaultItemSpacing, 4);
      expect(
        CorePaginationStyle.defaultButtonTextStyle.token,
        CoreTextStyles.bodyMedium,
      );
      // The selected number alone is `labelLarge` at semibold.
      expect(
        CorePaginationStyle.defaultActiveButtonTextStyle.token,
        CoreTextStyles.labelLarge,
      );
      expect(
        CorePaginationStyle.defaultActiveButtonTextStyle.fontWeight,
        CoreFontWeight.semiBold,
      );
      expect(
        CorePaginationStyle.defaultTextStyle.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      expect(
        CorePaginationStyle.defaultHoverTextStyle.color,
        const CoreColor.token(CoreColors.onSurface),
      );
      expect(
        CorePaginationStyle.defaultActiveTextStyle.color,
        const CoreColor.token(CoreColors.onPrimary),
      );
      expect(
        CorePaginationStyle.defaultEllipsisStyle.color,
        const CoreColor.token(CoreColors.onSurfaceSubtle),
      );
      expect(
        CorePaginationStyle.defaultDisabledColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
      expect(
        CorePaginationStyle.defaultDisabledBackgroundColor,
        const CoreColor.token(CoreColors.disabledContainer),
      );
      expect(CorePaginationStyle.defaultIconStyle.size, 16);
      // The focus ring is drawn at the cell's own corner (+ the ring reach).
      expect(
        CorePaginationStyle.defaultClickableStyle.borderRadius,
        CorePaginationStyle.defaultButtonRadius,
      );
    });

    test('the new fields take part in merge, copyWith and equality', () {
      const a = CorePaginationStyle(
        activeButtonTextStyle: CoreTextStyle(fontSize: _kFontLabel),
        disabledColor: _kColorOnSurface,
        disabledBackgroundColor: _kColorOutline,
        iconStyle: CoreIconStyle(size: 20),
      );
      const same = CorePaginationStyle(
        activeButtonTextStyle: CoreTextStyle(fontSize: _kFontLabel),
        disabledColor: _kColorOnSurface,
        disabledBackgroundColor: _kColorOutline,
        iconStyle: CoreIconStyle(size: 20),
      );
      expect(a, same);
      expect(a.hashCode, same.hashCode);
      expect(a.copyWith(disabledColor: _kColorPrimary), isNot(a));
      expect(a.copyWith(disabledBackgroundColor: _kColorPrimary), isNot(a));
      expect(a.copyWith(iconStyle: const CoreIconStyle(size: 12)), isNot(a));
      expect(
        a.copyWith(activeButtonTextStyle: const CoreTextStyle(fontSize: 16)),
        isNot(a),
      );

      final merged = a.merge(
        const CorePaginationStyle(iconStyle: CoreIconStyle(size: 12)),
      );
      expect(merged.iconStyle?.size, 12);
      expect(merged.disabledColor, _kColorOnSurface);
      expect(merged.activeButtonTextStyle?.fontSize, _kFontLabel);
    });
  });

  group('CorePaginationTheme', () {
    test('passes through style', () {
      const style = CorePaginationStyle(itemSpacing: 4);
      const theme = CorePaginationTheme(style: style);
      expect(theme.style, style);
    });
  });
}
