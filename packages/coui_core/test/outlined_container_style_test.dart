// Tests for CoreOutlinedContainerStyle (Epic #1302 — Story #1317).
//
// Mirrors the merge-chain pattern established by CoreCardStyle /
// CoreIconStyle / CoreTextStyle: a single nested style flows through
// `design system default → theme.style → widget.containerStyle`, with
// right-most non-null winning per field.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const CoreEdgeInsets _kPaddingSm = CoreEdgeInsets.all(8);
const CoreEdgeInsets _kPaddingMd = CoreEdgeInsets.all(16);
const CoreBorderRadius _kRadiusSm = CoreBorderRadius.all(4);
const CoreBorderRadius _kRadiusLg = CoreBorderRadius.all(16);
const double _kBorderThin = 1;
const double _kBorderThick = 2;
const double _kBlurNone = 0;
const double _kBlurSoft = 12;
const double _kOpacityFull = 1;
const double _kOpacityMuted = 0.6;
const double _kWidthFixed = 240;
const double _kHeightFixed = 120;

const _kBgSurface = CoreColor.token(CoreColors.surface);
const _kBgPrimary = CoreColor.token(CoreColors.primary);
const _kBorderOutline = CoreColor.token(CoreColors.outline);
const _kBorderError = CoreColor.token(CoreColors.error);

const Duration _kDurationShort = Duration(milliseconds: 150);
const Duration _kDurationLong = Duration(milliseconds: 300);

void main() {
  test('transparent border flag participates in style merge and identity', () {
    const initial = CoreOutlinedContainerStyle();
    const preserve = CoreOutlinedContainerStyle(
      preserveTransparentBorder: true,
    );
    expect(
      CoreOutlinedContainerStyle.defaultPreserveTransparentBorder,
      isFalse,
    );
    expect(initial.merge(preserve), preserve);
    expect(initial.copyWith(preserveTransparentBorder: true), preserve);
    expect(initial, isNot(preserve));
    expect(
      preserve.copyWith(preserveTransparentBorder: false),
      const CoreOutlinedContainerStyle(preserveTransparentBorder: false),
    );
  });
  group('CoreOutlinedContainerStyle.merge', () {
    test('null other returns this', () {
      const a = CoreOutlinedContainerStyle(
        backgroundColor: _kBgSurface,
        padding: _kPaddingMd,
      );
      expect(identical(a.merge(null), a), isTrue);
    });

    test('non-null fields in other override receiver', () {
      const base = CoreOutlinedContainerStyle(
        backgroundColor: _kBgSurface,
        borderColor: _kBorderOutline,
        borderWidth: _kBorderThin,
        padding: _kPaddingSm,
      );
      const override = CoreOutlinedContainerStyle(
        backgroundColor: _kBgPrimary,
        padding: _kPaddingMd,
      );
      final merged = base.merge(override);
      expect(merged.backgroundColor, _kBgPrimary);
      expect(merged.padding, _kPaddingMd);
      expect(merged.borderColor, _kBorderOutline);
      expect(merged.borderWidth, _kBorderThin);
    });

    test('null fields in other inherit from receiver', () {
      const base = CoreOutlinedContainerStyle(
        backgroundColor: _kBgSurface,
        borderRadius: _kRadiusLg,
        padding: _kPaddingMd,
      );
      const override = CoreOutlinedContainerStyle(
        backgroundColor: _kBgPrimary,
      );
      final merged = base.merge(override);
      expect(merged.backgroundColor, _kBgPrimary);
      expect(merged.borderRadius, _kRadiusLg);
      expect(merged.padding, _kPaddingMd);
    });

    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreOutlinedContainerStyle(
        backgroundColor: _kBgSurface,
        borderColor: _kBorderOutline,
        borderRadius: _kRadiusLg,
        borderWidth: _kBorderThin,
        padding: _kPaddingMd,
        clipBehavior: .antiAlias,
      );
      const themeStyle = CoreOutlinedContainerStyle(
        borderRadius: _kRadiusSm,
      );
      const widgetStyle = CoreOutlinedContainerStyle(
        backgroundColor: _kBgPrimary,
        elevation: .soft,
      );

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.backgroundColor, _kBgPrimary); // widget override
      expect(effective.borderColor, _kBorderOutline);
      expect(effective.borderRadius, _kRadiusSm); // theme override
      expect(effective.borderWidth, _kBorderThin);
      expect(effective.padding, _kPaddingMd);
      expect(effective.elevation, CoreOutlinedContainerElevation.soft);
      expect(effective.clipBehavior, CoreClipBehavior.antiAlias);
    });

    test('right-most non-null wins on each field', () {
      const a = CoreOutlinedContainerStyle(
        borderColor: _kBorderOutline,
        padding: _kPaddingSm,
      );
      const b = CoreOutlinedContainerStyle(
        padding: _kPaddingMd,
      );
      const c = CoreOutlinedContainerStyle(
        borderColor: _kBorderError,
      );

      final result = a.merge(b).merge(c);

      expect(result.padding, _kPaddingMd); // from b (c is null)
      expect(result.borderColor, _kBorderError); // from c overrides a
    });

    test('borderStyle / elevation / surface effects merge', () {
      const base = CoreOutlinedContainerStyle(
        borderStyle: .dashed,
        elevation: .soft,
        surfaceOpacity: _kOpacityFull,
        surfaceBlur: _kBlurNone,
      );
      const override = CoreOutlinedContainerStyle(
        borderStyle: .solid,
        surfaceBlur: _kBlurSoft,
      );
      final merged = base.merge(override);
      expect(merged.borderStyle, CoreOutlinedContainerBorderStyle.solid);
      expect(merged.elevation, CoreOutlinedContainerElevation.soft);
      expect(merged.surfaceOpacity, _kOpacityFull);
      expect(merged.surfaceBlur, _kBlurSoft);
    });

    test('width / height / duration merge independently', () {
      const base = CoreOutlinedContainerStyle(
        width: _kWidthFixed,
        height: _kHeightFixed,
        duration: _kDurationShort,
      );
      const override = CoreOutlinedContainerStyle(
        duration: _kDurationLong,
      );
      final merged = base.merge(override);
      expect(merged.width, _kWidthFixed);
      expect(merged.height, _kHeightFixed);
      expect(merged.duration, _kDurationLong);
    });
  });

  group('CoreOutlinedContainerStyle.backgroundGradient', () {
    const gradient = CoreGradient(
      type: CoreGradientType.linear,
      colors: [_kBgSurface, _kBgPrimary],
      stops: [0, 1],
      begin: CoreAlignment.topCenter,
      end: CoreAlignment.bottomCenter,
    );
    const sameGradient = CoreGradient(
      type: CoreGradientType.linear,
      colors: [_kBgSurface, _kBgPrimary],
      stops: [0, 1],
      begin: CoreAlignment.topCenter,
      end: CoreAlignment.bottomCenter,
    );

    test('absent by default: a solid fill, not a gradient', () {
      expect(const CoreOutlinedContainerStyle().backgroundGradient, isNull);
    });

    test('merges, copies and compares like every other field', () {
      const base = CoreOutlinedContainerStyle(backgroundColor: _kBgSurface);
      const withGradient = CoreOutlinedContainerStyle(
        backgroundGradient: gradient,
      );
      final merged = base.merge(withGradient);
      expect(merged.backgroundGradient, gradient);
      // The colour survives: it is the fill when the gradient is absent.
      expect(merged.backgroundColor, _kBgSurface);
      expect(base.copyWith(backgroundGradient: gradient), merged);
      // Value equality, not identity: a rebuild with the same gradient is not
      // a change.
      expect(
        withGradient,
        const CoreOutlinedContainerStyle(backgroundGradient: sameGradient),
      );
      expect(withGradient, isNot(equals(const CoreOutlinedContainerStyle())));
    });
  });

  group('CoreOutlinedContainerStyle.shadowBaseColor', () {
    const black = CoreColor(0xFF000000);

    test('defaults to the palette shadow slot; the field is unset', () {
      expect(
        CoreOutlinedContainerStyle.defaultShadowBaseColor,
        const CoreColor.token(CoreColors.shadow),
      );
      expect(const CoreOutlinedContainerStyle().shadowBaseColor, isNull);
    });

    test('merges, copies and compares like every other field', () {
      const base = CoreOutlinedContainerStyle(boxShadow: CoreShadow.xl);
      const pinned = CoreOutlinedContainerStyle(shadowBaseColor: black);
      final merged = base.merge(pinned);
      expect(merged.shadowBaseColor, black);
      // The stack survives: the base colour tints it, it does not replace it.
      expect(merged.boxShadow, CoreShadow.xl);
      expect(base.copyWith(shadowBaseColor: black), merged);
      // A field outside equality means no rebuild when only it changes.
      expect(merged, isNot(equals(base)));
      expect(merged.hashCode, isNot(equals(base.hashCode)));
      expect(
        pinned,
        const CoreOutlinedContainerStyle(
          shadowBaseColor: CoreColor(0xFF000000),
        ),
      );
    });

    test('a null in the right-most layer inherits it', () {
      const pinned = CoreOutlinedContainerStyle(shadowBaseColor: black);
      expect(pinned.merge(const CoreOutlinedContainerStyle()), pinned);
    });
  });

  group('CoreOutlinedContainerStyle.shadowStrengthens', () {
    test('defaults to strengthening; the field is unset', () {
      expect(CoreOutlinedContainerStyle.defaultShadowStrengthens, isTrue);
      expect(const CoreOutlinedContainerStyle().shadowStrengthens, isNull);
    });

    test('merges, copies and compares like every other field', () {
      const base = CoreOutlinedContainerStyle(boxShadow: CoreShadow.xl);
      const pinned = CoreOutlinedContainerStyle(shadowStrengthens: false);
      final merged = base.merge(pinned);
      expect(merged.shadowStrengthens, isFalse);
      // The stack survives: the flag says how the dark draws it.
      expect(merged.boxShadow, CoreShadow.xl);
      expect(base.copyWith(shadowStrengthens: false), merged);
      expect(merged, isNot(equals(base)));
      expect(merged.hashCode, isNot(equals(base.hashCode)));
      // A null in the right-most layer inherits it; a stated true wins.
      expect(pinned.merge(const CoreOutlinedContainerStyle()), pinned);
      expect(
        pinned
            .merge(const CoreOutlinedContainerStyle(shadowStrengthens: true))
            .shadowStrengthens,
        isTrue,
      );
    });
  });

  group('CoreOutlinedContainerStyle equality', () {
    test('same fields → equal', () {
      const a = CoreOutlinedContainerStyle(
        backgroundColor: _kBgSurface,
        borderRadius: _kRadiusLg,
        padding: _kPaddingMd,
        clipBehavior: .antiAlias,
      );
      const b = CoreOutlinedContainerStyle(
        backgroundColor: _kBgSurface,
        borderRadius: _kRadiusLg,
        padding: _kPaddingMd,
        clipBehavior: .antiAlias,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different padding → not equal', () {
      const a = CoreOutlinedContainerStyle(padding: _kPaddingSm);
      const b = CoreOutlinedContainerStyle(padding: _kPaddingMd);
      expect(a, isNot(equals(b)));
    });

    test('different borderStyle → not equal', () {
      const a = CoreOutlinedContainerStyle(
        borderStyle: .dashed,
      );
      const b = CoreOutlinedContainerStyle(
        borderStyle: .dotted,
      );
      expect(a, isNot(equals(b)));
    });

    test('different surfaceOpacity → not equal', () {
      const a = CoreOutlinedContainerStyle(
        surfaceOpacity: _kOpacityFull,
      );
      const b = CoreOutlinedContainerStyle(
        surfaceOpacity: _kOpacityMuted,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreOutlinedContainerStyle.copyWith', () {
    test('only-supplied fields override', () {
      const base = CoreOutlinedContainerStyle(
        backgroundColor: _kBgSurface,
        borderColor: _kBorderOutline,
        borderWidth: _kBorderThin,
        padding: _kPaddingSm,
      );
      final copy = base.copyWith(
        backgroundColor: _kBgPrimary,
        borderWidth: _kBorderThick,
      );
      expect(copy.backgroundColor, _kBgPrimary);
      expect(copy.borderColor, _kBorderOutline);
      expect(copy.borderWidth, _kBorderThick);
      expect(copy.padding, _kPaddingSm);
    });
  });

  group('CoreOutlinedContainerTheme', () {
    test('style passes through', () {
      const style = CoreOutlinedContainerStyle(padding: _kPaddingMd);
      const theme = CoreOutlinedContainerTheme(style: style);
      expect(theme.style, style);
    });

    test('null style', () {
      const theme = CoreOutlinedContainerTheme();
      expect(theme.style, isNull);
    });

    test('equality', () {
      const a = CoreOutlinedContainerTheme(
        style: CoreOutlinedContainerStyle(padding: _kPaddingMd),
      );
      const b = CoreOutlinedContainerTheme(
        style: CoreOutlinedContainerStyle(padding: _kPaddingMd),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
