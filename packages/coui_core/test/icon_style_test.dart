// Tests for the leaf Style API (Epic #1302).
// ignore_for_file: avoid_redundant_argument_values

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const double _kSizeDefault = CoreSize.size24;
const double _kSizeTheme = CoreSize.size18;
const double _kSizeWidget = CoreSize.size16;
const double _kSizeAlt = CoreSize.size20;

const _kColorOnSurface = CoreColor.token(CoreColors.onSurface);
const _kColorPrimary = CoreColor.token(CoreColors.primary);
const _kColorTertiary = CoreColor.token(CoreColors.tertiary);
const _kColorError = CoreColor.token(CoreColors.error);

void main() {
  group('CoreIconStyle.merge', () {
    test('null other returns this', () {
      const a = CoreIconStyle(
        size: _kSizeAlt,
        color: _kColorPrimary,
      );
      expect(identical(a.merge(null), a), isTrue);
    });

    test('non-null fields in other override receiver', () {
      const base = CoreIconStyle(
        size: _kSizeAlt,
        color: _kColorPrimary,
      );
      const override = CoreIconStyle(
        size: _kSizeWidget,
        color: _kColorError,
      );
      final merged = base.merge(override);
      expect(merged.size, _kSizeWidget);
      expect(merged.color, _kColorError);
    });

    test('null fields in other inherit from receiver', () {
      const base = CoreIconStyle(
        size: _kSizeAlt,
        color: _kColorPrimary,
      );
      const override = CoreIconStyle(size: _kSizeWidget);
      final merged = base.merge(override);
      expect(merged.size, _kSizeWidget);
      expect(merged.color, _kColorPrimary);
    });

    test('chain — design system → theme → widget', () {
      const designSystem = CoreIconStyle(
        size: _kSizeDefault,
        color: _kColorOnSurface,
      );
      const themeOverride = CoreIconStyle(size: _kSizeTheme);
      const widgetOverride = CoreIconStyle(color: _kColorTertiary);

      final effective = designSystem.merge(themeOverride).merge(widgetOverride);

      expect(effective.size, _kSizeTheme);
      expect(effective.color, _kColorTertiary);
    });

    test('right-most non-null wins on each field', () {
      const a = CoreIconStyle(size: _kSizeDefault);
      const b = CoreIconStyle(
        size: _kSizeAlt,
        color: _kColorPrimary,
      );
      const c = CoreIconStyle(color: _kColorError);

      final result = a.merge(b).merge(c);

      expect(result.size, _kSizeAlt); // from b (c is null)
      expect(result.color, _kColorError); // from c overrides b
    });
  });

  group('CoreIconStyle equality', () {
    test('same fields → equal', () {
      const a = CoreIconStyle(
        size: _kSizeAlt,
        color: _kColorPrimary,
      );
      const b = CoreIconStyle(
        size: _kSizeAlt,
        color: _kColorPrimary,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different size → not equal', () {
      const a = CoreIconStyle(size: _kSizeAlt);
      const b = CoreIconStyle(size: _kSizeWidget);
      expect(a, isNot(equals(b)));
    });

    test('different color → not equal', () {
      const a = CoreIconStyle(color: _kColorPrimary);
      const b = CoreIconStyle(color: _kColorError);
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreIconStyle.copyWith', () {
    test('only-supplied fields override', () {
      const base = CoreIconStyle(
        size: _kSizeAlt,
        color: _kColorPrimary,
      );
      final copy = base.copyWith(size: _kSizeWidget);
      expect(copy.size, _kSizeWidget);
      expect(copy.color, _kColorPrimary);
    });
  });

  group('CoreIconTheme', () {
    test('style passes through', () {
      const style = CoreIconStyle(size: _kSizeTheme);
      const theme = CoreIconTheme(style: style);
      expect(theme.style, style);
    });

    test('null style', () {
      const theme = CoreIconTheme();
      expect(theme.style, isNull);
    });

    test('equality', () {
      const a = CoreIconTheme(
        style: CoreIconStyle(size: _kSizeTheme),
      );
      const b = CoreIconTheme(
        style: CoreIconStyle(size: _kSizeTheme),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
