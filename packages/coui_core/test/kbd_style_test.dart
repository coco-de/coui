// Tests for CoreKbdStyle.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kColorOnSurface = CoreColor.token(CoreColors.onSurface);
const _kFontLabel = 14.0;
const _kFontTitle = 18.0;
const int _kWeightSemiBold = CoreFontWeight.semiBold;

void main() {
  group('CoreKbdStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreKbdStyle(
        keyPadding: CoreEdgeInsets.symmetric(horizontal: 6, vertical: 4),
        keySeparatorSpacing: 2,
        keyRadius: CoreBorderRadius.all(4),
        keyTextStyle: CoreTextStyle(
          fontSize: _kFontLabel,
          color: _kColorOnSurface,
        ),
      );
      const themeStyle = CoreKbdStyle(
        keyPadding: CoreEdgeInsets.symmetric(horizontal: 8, vertical: 4),
        keyTextStyle: CoreTextStyle(fontWeight: _kWeightSemiBold),
      );
      const widgetStyle = CoreKbdStyle(keyRadius: CoreBorderRadius.all(8));

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(
        effective.keyPadding,
        const CoreEdgeInsets.symmetric(horizontal: 8, vertical: 4),
      );
      expect(effective.keySeparatorSpacing, 2);
      expect(effective.keyRadius, const CoreBorderRadius.all(8));
      expect(effective.keyTextStyle?.fontSize, _kFontLabel);
      expect(effective.keyTextStyle?.fontWeight, _kWeightSemiBold);
      expect(effective.keyTextStyle?.color, _kColorOnSurface);
    });

    test('text styles merge recursively', () {
      const base = CoreKbdStyle(
        keyTextStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      const override = CoreKbdStyle(
        keyTextStyle: CoreTextStyle(fontSize: _kFontTitle),
      );
      final merged = base.merge(override);
      expect(merged.keyTextStyle?.fontSize, _kFontTitle);
    });

    test('equality + copyWith', () {
      const a = CoreKbdStyle(
        keySeparatorSpacing: 2,
        keyRadius: CoreBorderRadius.all(4),
      );
      const b = CoreKbdStyle(
        keySeparatorSpacing: 2,
        keyRadius: CoreBorderRadius.all(4),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final copy = a.copyWith(
        keyPadding: const CoreEdgeInsets.symmetric(horizontal: 8),
      );
      expect(
        copy.keyPadding,
        const CoreEdgeInsets.symmetric(horizontal: 8),
      );
      expect(copy.keyRadius, const CoreBorderRadius.all(4));
      expect(copy.keySeparatorSpacing, 2);
    });
  });

  group('key cap defaults', () {
    test('the fill is the page face and the edge is the subtle hairline', () {
      expect(
        CoreKbdStyle.defaultKeyBackgroundColor,
        const CoreColor.token(CoreColors.surface),
      );
      expect(
        CoreKbdStyle.defaultKeyBorderColor,
        const CoreColor.token(CoreColors.outlineSubtle),
      );
      expect(CoreKbdStyle.defaultKeyBorderWidth, CoreStrokeWidth.stroke0_5);
    });

    test('a key casts no shadow unless a style states one', () {
      expect(CoreKbdStyle.defaultKeyShadow, isEmpty);
      expect(CoreKbdStyle.defaultKeyShadow, CoreShadow.none);
    });

    test('padding is 6 across and 2 down — the cap is 19.4 tall', () {
      // labelXs is 11px × 1.4 = 15.4; 2 + 15.4 + 2 = 19.4 inside the
      // border, which adds 0.5 on each edge for the default hairline.
      expect(
        CoreKbdStyle.defaultKeyPadding,
        const CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space6,
          vertical: CoreSpace.space2,
        ),
      );
    });

    test(
      'the minimum square is 18 off the size scale, not the spacing one',
      () {
        expect(CoreKbdStyle.defaultKeyMinSize, CoreSize.size18);
        expect(CoreKbdStyle.defaultKeyMinSize, 18);
      },
    );

    test('adjacent keys sit space/4 apart — no glyph between them', () {
      // No `+` is drawn, so the gap alone keeps neighbouring key boxes apart.
      // Two platforms read this one number.
      expect(CoreKbdStyle.defaultKeySeparatorSpacing, CoreSpace.space4);
    });
  });

  group('keyShadow', () {
    const hard = <CoreShadowLayer>[
      (
        offsetX: 2,
        offsetY: 2,
        blurRadius: 0,
        spreadRadius: 0,
        opacity: 1,
        inset: false,
      ),
    ];

    test('merges by replacement — the later stack wins whole', () {
      const base = CoreKbdStyle(keyShadow: CoreShadow.xs);
      const override = CoreKbdStyle(keyShadow: hard);
      expect(base.merge(override).keyShadow, hard);
      expect(base.merge(const CoreKbdStyle()).keyShadow, CoreShadow.xs);
    });

    test('an empty stack is a stated "no shadow", not an absent field', () {
      const none = CoreKbdStyle(keyShadow: CoreShadow.none);
      expect(
        const CoreKbdStyle(keyShadow: CoreShadow.xs).merge(none).keyShadow,
        isEmpty,
      );
    });

    test('takes part in equality, hashCode and copyWith', () {
      const a = CoreKbdStyle(keyShadow: CoreShadow.xs);
      const b = CoreKbdStyle(keyShadow: CoreShadow.xs);
      const c = CoreKbdStyle(keyShadow: hard);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(const CoreKbdStyle())));
      expect(a.copyWith(keyShadow: hard).keyShadow, hard);
      expect(a.copyWith().keyShadow, CoreShadow.xs);
    });
  });

  group('CoreKbdTheme passes through style', () {
    test('CoreKbdTheme', () {
      const style = CoreKbdStyle(keyRadius: CoreBorderRadius.all(8));
      const theme = CoreKbdTheme(style: style);
      expect(theme.style, style);
    });
  });
}
