// Tests for CoreDropdownMenuStyle (Epic #2676 — nested menuStyle + offset).
// ignore_for_file: avoid_redundant_argument_values

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kRadius8 = CoreBorderRadius.all(8);
const _kRadius16 = CoreBorderRadius.all(16);
const _kPadH8 = CoreEdgeInsets.symmetric(horizontal: 8);
const _kPadH16 = CoreEdgeInsets.symmetric(horizontal: 16);

void main() {
  group('CoreDropdownMenuStyle.merge', () {
    test('null other returns this', () {
      const a = CoreDropdownMenuStyle(menuOffset: 4);
      expect(identical(a.merge(null), a), isTrue);
    });

    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreDropdownMenuStyle(
        menuStyle: CoreMenuStyle(
          popupStyle: CorePopupStyle(borderRadius: _kRadius8),
          itemStyle: CoreMenuItemStyle(padding: _kPadH8),
        ),
        menuOffset: 2,
      );
      const themeStyle = CoreDropdownMenuStyle(
        menuStyle: CoreMenuStyle(
          popupStyle: CorePopupStyle(borderRadius: _kRadius16),
        ),
      );
      const widgetStyle = CoreDropdownMenuStyle(menuOffset: 8);

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      // Nested menuStyle merges recursively — radius from theme, item
      // padding from design system.
      expect(effective.menuStyle?.popupStyle?.borderRadius, _kRadius16);
      expect(effective.menuStyle?.itemStyle?.padding, _kPadH8);
      // Flat menuOffset — right-most non-null wins.
      expect(effective.menuOffset, 8);
    });

    test('null nested menuStyle on base inherits from override', () {
      const base = CoreDropdownMenuStyle(menuOffset: 4);
      const override = CoreDropdownMenuStyle(
        menuStyle: CoreMenuStyle(
          itemStyle: CoreMenuItemStyle(padding: _kPadH16),
        ),
      );
      final merged = base.merge(override);
      expect(merged.menuStyle?.itemStyle?.padding, _kPadH16);
      expect(merged.menuOffset, 4);
    });

    test('menuOffset — right-most non-null wins; null preserves base', () {
      const base = CoreDropdownMenuStyle(menuOffset: 2);
      const override = CoreDropdownMenuStyle(menuOffset: 6);
      expect(base.merge(override).menuOffset, 6);
      expect(base.merge(const CoreDropdownMenuStyle()).menuOffset, 2);
    });
  });

  group('CoreDropdownMenuStyle.copyWith', () {
    test('only-supplied field replaces, others preserved', () {
      const base = CoreDropdownMenuStyle(
        menuStyle: CoreMenuStyle(
          popupStyle: CorePopupStyle(borderRadius: _kRadius8),
        ),
        menuOffset: 4,
      );
      final copy = base.copyWith(menuOffset: 8);
      expect(copy.menuOffset, 8);
      // copyWith replaces the whole slot (no recursive merge); menuStyle
      // preserved since not supplied.
      expect(copy.menuStyle?.popupStyle?.borderRadius, _kRadius8);
    });
  });

  group('CoreDropdownMenuStyle equality', () {
    test('same fields → equal', () {
      const a = CoreDropdownMenuStyle(menuOffset: 4);
      const b = CoreDropdownMenuStyle(menuOffset: 4);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different menuOffset → not equal', () {
      const a = CoreDropdownMenuStyle(menuOffset: 4);
      const b = CoreDropdownMenuStyle(menuOffset: 8);
      expect(a, isNot(equals(b)));
    });

    test('different menuStyle → not equal', () {
      const a = CoreDropdownMenuStyle(
        menuStyle: CoreMenuStyle(
          itemStyle: CoreMenuItemStyle(padding: _kPadH8),
        ),
      );
      const b = CoreDropdownMenuStyle(
        menuStyle: CoreMenuStyle(
          itemStyle: CoreMenuItemStyle(padding: _kPadH16),
        ),
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreDropdownMenuStyle defaults', () {
    test('default menuOffset is space4 (matches the legacy raw offset)', () {
      expect(CoreDropdownMenuStyle.defaultMenuOffset, CoreSpace.space4);
    });
  });

  group('CoreDropdownMenuTheme', () {
    test('style passes through', () {
      const style = CoreDropdownMenuStyle(menuOffset: 8);
      const theme = CoreDropdownMenuTheme(style: style);
      expect(theme.style, style);
    });

    test('null style', () {
      const theme = CoreDropdownMenuTheme();
      expect(theme.style, isNull);
    });

    test('equality', () {
      const a = CoreDropdownMenuTheme(
        style: CoreDropdownMenuStyle(menuOffset: 4),
      );
      const b = CoreDropdownMenuTheme(
        style: CoreDropdownMenuStyle(menuOffset: 4),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
