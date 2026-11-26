// Tests for CoreThemeControllerStyle.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kColorPrimary = CoreColor.token(CoreColors.primary);
const _kRadius8 = CoreBorderRadius.all(8);

void main() {
  group('CoreThemeControllerStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreThemeControllerStyle(
        buttonSize: 48,
        buttonRadius: _kRadius8,
        selectedBorderColor: _kColorPrimary,
      );
      const themeStyle = CoreThemeControllerStyle(buttonSize: 56);
      const widgetStyle = CoreThemeControllerStyle(
        buttonRadius: CoreBorderRadius.all(2),
      );

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.selectedBorderColor, _kColorPrimary);
      expect(effective.buttonSize, 56);
      expect(effective.buttonRadius, const CoreBorderRadius.all(2));
    });

    test('merge with null returns this', () {
      const a = CoreThemeControllerStyle(buttonSize: 48);
      expect(a.merge(null), same(a));
    });

    test('equality + copyWith', () {
      const a = CoreThemeControllerStyle(
        buttonSize: 48,
        selectedBorderColor: _kColorPrimary,
      );
      const b = CoreThemeControllerStyle(
        buttonSize: 48,
        selectedBorderColor: _kColorPrimary,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final copy = a.copyWith(buttonSize: 56);
      expect(copy.buttonSize, 56);
      expect(copy.selectedBorderColor, _kColorPrimary);
    });

    test('design-system defaults', () {
      // The flat defaults are the md rung.
      expect(CoreThemeControllerStyle.defaultButtonSize, CoreSize.size40);
      expect(CoreThemeControllerStyle.defaultPreviewSize, CoreSize.size32);
      // Twelve between the cells, the same on every rung.
      expect(CoreThemeControllerStyle.defaultButtonSpacing, CoreSpace.space12);
      expect(
        CoreThemeControllerStyle.defaultSelectedBorderWidth,
        CoreStrokeWidth.stroke2,
      );
      // An unselected swatch at rest is the bare palette — no ring.
      expect(
        CoreThemeControllerStyle.defaultUnselectedBorderWidth,
        CoreStrokeWidth.stroke0,
      );
      expect(
        CoreThemeControllerStyle.defaultButtonRadius,
        const CoreBorderRadius.all(CoreRadius.radius20),
      );
      final md =
          CoreThemeControllerStyle.defaultsBySize[CoreThemeControllerSize.md]!;
      expect(md.buttonSize, CoreThemeControllerStyle.defaultButtonSize);
      expect(md.previewSize, CoreThemeControllerStyle.defaultPreviewSize);
      expect(md.buttonSpacing, CoreThemeControllerStyle.defaultButtonSpacing);
      expect(md.buttonRadius, CoreThemeControllerStyle.defaultButtonRadius);
    });

    test('the button is a ring with no body', () {
      expect(
        CoreThemeControllerStyle.defaultButtonBackgroundColor,
        CoreColor.transparent,
      );
      expect(
        CoreThemeControllerStyle.defaultPreviewBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius9999),
      );
    });

    test('the selection is a strong ring and a strong label', () {
      // The ring is the only selection mark there is (no badge), so it
      // wears the strong ink, and the label turns to the same ink.
      expect(
        CoreThemeControllerStyle.defaultSelectedBorderColor,
        const CoreColor.token(CoreColors.onSurface),
      );
      expect(
        CoreThemeControllerStyle.defaultSelectedLabelColor,
        const CoreColor.token(CoreColors.onSurface),
      );
      expect(
        CoreThemeControllerStyle.defaultLabelColor,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
    });

    test('hover and press grow a light ring as wide as the selected one', () {
      expect(
        CoreThemeControllerStyle.defaultHoverBorderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(
        CoreThemeControllerStyle.defaultHoverBorderWidth,
        CoreStrokeWidth.stroke2,
      );
      expect(
        CoreThemeControllerStyle.defaultHoverBorderWidth,
        CoreThemeControllerStyle.defaultSelectedBorderWidth,
      );
    });

    test('the palette gives up a pixel a side while pressed', () {
      expect(CoreThemeControllerStyle.defaultPressedPreviewShrink, 2);
    });

    test('the ladder is three rungs, and only those', () {
      // A 32 / 40 / 48 circle around a 24 / 32 / 40 palette (the canvas
      // ladder, Figma ❖ ThemeSwatch). Every `defaultsBySize[size]!` in the
      // resolvers assumes full coverage.
      const button = {
        CoreThemeControllerSize.sm: CoreSize.size32,
        CoreThemeControllerSize.md: CoreSize.size40,
        CoreThemeControllerSize.lg: CoreSize.size48,
      };
      const preview = {
        CoreThemeControllerSize.sm: CoreSize.size24,
        CoreThemeControllerSize.md: CoreSize.size32,
        CoreThemeControllerSize.lg: CoreSize.size40,
      };
      const radius = {
        CoreThemeControllerSize.sm: CoreRadius.radius16,
        CoreThemeControllerSize.md: CoreRadius.radius20,
        CoreThemeControllerSize.lg: CoreRadius.radius24,
      };
      const label = {
        CoreThemeControllerSize.sm: CoreTextStyles.labelSmall,
        CoreThemeControllerSize.md: CoreTextStyles.labelMedium,
        CoreThemeControllerSize.lg: CoreTextStyles.labelLarge,
      };
      for (final size in CoreThemeControllerSize.values) {
        final row = CoreThemeControllerStyle.defaultsBySize[size]!;
        expect(
          row.buttonSpacing,
          CoreSpace.space12,
          reason: '${size.name} 칸 사이 — 크기를 따라 자라지 않는다',
        );
        expect(row.buttonSize, button[size], reason: '${size.name} 버튼');
        expect(row.previewSize, preview[size], reason: '${size.name} 프리뷰');
        // The button is a circle: its radius is half its size.
        expect(
          row.buttonRadius,
          CoreBorderRadius.all(radius[size]!),
          reason: '${size.name} 버튼 모서리',
        );
        expect(row.buttonRadius!.topLeft, row.buttonSize! / 2);
        expect(
          row.labelStyle,
          CoreTextStyle.token(label[size]!),
          reason: '${size.name} 라벨 롤',
        );
        // Six on every rung — the gap no longer grows with the size.
        expect(
          row.labelGapStyle,
          const CoreGapStyle(size: CoreSpace.space6),
          reason: '${size.name} 라벨 간격',
        );
      }
      expect(
        CoreThemeControllerStyle.defaultsBySize.length,
        CoreThemeControllerSize.values.length,
      );
      expect(CoreThemeControllerSize.defaultSize, CoreThemeControllerSize.md);
    });

    test('a swatch cell is at least 48 wide — a floor, not a width', () {
      expect(CoreThemeControllerStyle.defaultSwatchMinWidth, CoreSize.size48);
      // The ladder states no width of its own: the floor is one number for
      // every rung, and the name can only widen a cell, never narrow it.
      for (final row in CoreThemeControllerStyle.defaultsBySize.values) {
        expect(row.swatchMinWidth, isNull);
      }
    });

    test('swatchMinWidth takes part in merge, copyWith and equality', () {
      // A field left out of `==` would make a style that differs only in it
      // compare equal, and the framework would skip the rebuild.
      const base = CoreThemeControllerStyle();
      final wider = base.copyWith(swatchMinWidth: 64);
      expect(wider.swatchMinWidth, 64);
      expect(wider, isNot(equals(base)));
      expect(wider.hashCode, isNot(base.hashCode));
      expect(base.merge(wider), wider);
    });

    test('disabled is colour tokens, not a fade', () {
      // A fade over an already-chosen colour makes the contrast depend on
      // whatever is underneath; the three tokens do not. Same shape
      // Checkbox / Chip / Toggle use.
      expect(
        CoreThemeControllerStyle.defaultClickableStyle.disabledOpacity,
        CoreOpacity.opacity100,
      );
      expect(
        CoreThemeControllerStyle.defaultDisabledBorderColor,
        const CoreColor.token(CoreColors.disabledOutline),
      );
      expect(
        CoreThemeControllerStyle.defaultDisabledPreviewColor,
        const CoreColor.token(CoreColors.disabledContainer),
      );
      expect(
        CoreThemeControllerStyle.defaultDisabledLabelColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
    });

    test('the new fields take part in merge, copyWith and equality', () {
      // A field left out of `==` would make a style that differs only in
      // it compare equal, and the framework would skip the rebuild.
      const base = CoreThemeControllerStyle();
      const hoverColor = CoreColor.token(CoreColors.primary);
      final styles = <CoreThemeControllerStyle>[
        base.copyWith(hoverBorderColor: hoverColor),
        base.copyWith(hoverBorderWidth: 3),
        base.copyWith(pressedPreviewShrink: 4),
        base.copyWith(selectedLabelColor: hoverColor),
      ];
      for (final style in styles) {
        expect(style, isNot(equals(base)));
        expect(style.hashCode, isNot(base.hashCode));
        expect(base.merge(style), style);
      }
    });

    test('nested slots merge recursively', () {
      // A caller retuning the label colour must not lose its weight.
      const a = CoreThemeControllerStyle(
        labelStyle: CoreTextStyle(fontWeight: CoreFontWeight.semiBold),
      );
      const b = CoreThemeControllerStyle(
        labelStyle: CoreTextStyle(color: _kColorPrimary),
      );
      final merged = a.merge(b);
      expect(merged.labelStyle!.fontWeight, CoreFontWeight.semiBold);
      expect(merged.labelStyle!.color, _kColorPrimary);
    });
  });

  group('CoreThemeControllerTheme', () {
    test('passes through style', () {
      const style = CoreThemeControllerStyle(buttonSize: 56);
      const theme = CoreThemeControllerTheme(style: style);
      expect(theme.style, style);
    });

    test('equality', () {
      const a = CoreThemeControllerTheme(
        style: CoreThemeControllerStyle(buttonSize: 56),
      );
      const b = CoreThemeControllerTheme(
        style: CoreThemeControllerStyle(buttonSize: 56),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CoreThemeOption', () {
    test('equality + hashCode', () {
      const a = CoreThemeOption(
        name: 'Ocean',
        primaryColor: CoreColor.fromRGB(14, 165, 233),
      );
      const b = CoreThemeOption(
        name: 'Ocean',
        primaryColor: CoreColor.fromRGB(14, 165, 233),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('enabled is part of identity and defaults to true', () {
      // A locked theme is a different value from the same theme unlocked
      // — otherwise flipping it would not rebuild anything.
      const on = CoreThemeOption(name: 'Ocean', primaryColor: _kColorPrimary);
      const off = CoreThemeOption(
        name: 'Ocean',
        primaryColor: _kColorPrimary,
        enabled: false,
      );
      expect(on.enabled, isTrue);
      expect(on, isNot(equals(off)));
    });
  });
}
