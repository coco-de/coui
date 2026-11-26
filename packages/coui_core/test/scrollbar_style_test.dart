// Tests for CoreScrollbarStyle.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kColorPrimary = CoreColor.token(CoreColors.primary);
const _kRadius8 = CoreBorderRadius.all(8);

void main() {
  group('CoreScrollbarStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreScrollbarStyle(
        thumbColor: _kColorPrimary,
        thumbRadius: _kRadius8,
        thickness: 7,
      );
      const themeStyle = CoreScrollbarStyle(thickness: 9);
      const widgetStyle = CoreScrollbarStyle(
        thumbRadius: CoreBorderRadius.all(2),
      );

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.thumbColor, _kColorPrimary);
      expect(effective.thickness, 9);
      expect(effective.thumbRadius, const CoreBorderRadius.all(2));
    });

    test('merge with null returns this', () {
      const a = CoreScrollbarStyle(thickness: 7);
      expect(a.merge(null), same(a));
    });

    test('equality + copyWith', () {
      const a = CoreScrollbarStyle(thumbColor: _kColorPrimary, thickness: 7);
      const b = CoreScrollbarStyle(thumbColor: _kColorPrimary, thickness: 7);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final copy = a.copyWith(thickness: 9);
      expect(copy.thickness, 9);
      expect(copy.thumbColor, _kColorPrimary);
    });

    test('design-system defaults', () {
      expect(CoreScrollbarStyle.defaultThickness, CoreSize.size6);
      expect(CoreScrollbarStyle.defaultHoverThickness, CoreSize.size8);
      expect(CoreScrollbarStyle.defaultThumbInset, CoreSpace.space2);
      expect(CoreScrollbarStyle.defaultMinThumbLength, CoreSize.size48);
      expect(
        CoreScrollbarStyle.defaultThumbRadius,
        const CoreBorderRadius.all(CoreRadius.radius9999),
      );
    });

    test(
      'thumb ink is the surface ink at half strength, stronger on hover',
      () {
        // The alpha lives in the colour, so one field carries the ink and how
        // strongly it shows — no separate opacity field.
        expect(
          CoreScrollbarStyle.defaultThumbColor,
          const CoreColor.token(
            CoreColors.onSurface,
            opacity: CoreOpacity.opacity50,
          ),
        );
        expect(
          CoreScrollbarStyle.defaultHoverThumbColor,
          const CoreColor.token(
            CoreColors.onSurface,
            opacity: CoreOpacity.opacity70,
          ),
        );
      },
    );

    test('thin halves a thickness by a plain number, not a stroke token', () {
      expect(CoreScrollbarStyle.thinThicknessFactor, 0.5);
    });

    test('hover and inset fields merge, copy and compare', () {
      const hoverInk = CoreColor.token(CoreColors.primary);
      const base = CoreScrollbarStyle(
        hoverThumbColor: hoverInk,
        hoverThickness: 8,
        thumbInset: 2,
      );

      // merge — the patch wins field by field, the rest is kept.
      final merged = base.merge(
        const CoreScrollbarStyle(hoverThickness: 10, thumbInset: 4),
      );
      expect(merged.hoverThumbColor, hoverInk);
      expect(merged.hoverThickness, 10);
      expect(merged.thumbInset, 4);

      // copyWith — same.
      final copy = base.copyWith(thumbInset: 1);
      expect(copy.hoverThumbColor, hoverInk);
      expect(copy.hoverThickness, 8);
      expect(copy.thumbInset, 1);

      // ==/hashCode — each new field is part of the identity. A field left
      // out of the comparison makes a theme swap that changes only it compare
      // equal, and the framework then skips the rebuild.
      const same = CoreScrollbarStyle(
        hoverThumbColor: hoverInk,
        hoverThickness: 8,
        thumbInset: 2,
      );
      expect(base, equals(same));
      expect(base.hashCode, same.hashCode);
      expect(
        base,
        isNot(
          equals(
            base.copyWith(
              hoverThumbColor: const CoreColor.token(CoreColors.secondary),
            ),
          ),
        ),
      );
      expect(base, isNot(equals(base.copyWith(hoverThickness: 9))));
      expect(base, isNot(equals(base.copyWith(thumbInset: 3))));
    });

    test('trackColor override field', () {
      const base = CoreScrollbarStyle(trackColor: CoreColor.transparent);
      const override = CoreScrollbarStyle(trackColor: _kColorPrimary);
      final merged = base.merge(override);
      expect(merged.trackColor, _kColorPrimary);
      final copy = base.copyWith(trackColor: _kColorPrimary);
      expect(copy.trackColor, _kColorPrimary);
      // Equality + hashCode include trackColor.
      const a = CoreScrollbarStyle(trackColor: CoreColor.transparent);
      const b = CoreScrollbarStyle(trackColor: CoreColor.transparent);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(override)));
      // Design-system default is the shared transparent sentinel.
      expect(CoreScrollbarStyle.defaultTrackColor, CoreColor.transparent);
    });

    test('minThumbLength override field', () {
      const base = CoreScrollbarStyle(minThumbLength: 48);
      const override = CoreScrollbarStyle(minThumbLength: 64);
      final merged = base.merge(override);
      expect(merged.minThumbLength, 64);
      final copy = base.copyWith(minThumbLength: 96);
      expect(copy.minThumbLength, 96);
      // Equality + hashCode include minThumbLength.
      const a = CoreScrollbarStyle(minThumbLength: 48);
      const b = CoreScrollbarStyle(minThumbLength: 48);
      const c = CoreScrollbarStyle(minThumbLength: 64);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });
  });

  group('CoreScrollbarTheme', () {
    test('passes through style', () {
      const style = CoreScrollbarStyle(thickness: 9);
      const theme = CoreScrollbarTheme(style: style);
      expect(theme.style, style);
    });

    test('equality', () {
      const a = CoreScrollbarTheme(style: CoreScrollbarStyle(thickness: 9));
      const b = CoreScrollbarTheme(style: CoreScrollbarStyle(thickness: 9));
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CoreScrollbarAxis / CoreScrollbarVisibility', () {
    test('defaults', () {
      expect(CoreScrollbarAxis.defaultAxis, CoreScrollbarAxis.both);
      expect(
        CoreScrollbarVisibility.defaultVisibility,
        CoreScrollbarVisibility.auto,
      );
    });
  });
}
