// Tests for CoreWindowStyle and CoreWindowPanelStyle nested merge.
//
// Mirrors the merge-chain pattern established by CoreFrameStyle:
// `design system default → theme.style → widget.windowStyle` with
// right-most non-null winning per field.
// ignore_for_file: avoid_redundant_argument_values

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const double _kTitleBarShort = 28;
const double _kTitleBarTall = 40;
const double _kDimSmall = 6;
const double _kDimLarge = 12;
const double _kRadiusSm = 4;
const double _kRadiusLg = 16;

// `CoreWindowPanelStyle.titleBarColor` is `CoreColor?` (Epic #1415 Phase 6f).
const _kTitleBarBg = CoreColor.token(CoreColors.surfaceContainer);
const _kTitleBarBgAlt = CoreColor.token(CoreColors.surface);

void main() {
  group('CoreWindowStyle.merge', () {
    test('null other returns this', () {
      const a = CoreWindowStyle(titleBarHeight: _kTitleBarShort);
      expect(identical(a.merge(null), a), isTrue);
    });

    test('non-null fields in other override receiver', () {
      const base = CoreWindowStyle(
        titleBarHeight: _kTitleBarShort,
        snapBarTileSpacing: _kDimSmall,
      );
      const override = CoreWindowStyle(titleBarHeight: _kTitleBarTall);
      final merged = base.merge(override);
      expect(merged.titleBarHeight, _kTitleBarTall);
      expect(merged.snapBarTileSpacing, _kDimSmall);
    });

    test('null fields in other preserve receiver', () {
      const base = CoreWindowStyle(
        titleBarHeight: _kTitleBarShort,
        snapBarTileSpacing: _kDimSmall,
      );
      const override = CoreWindowStyle();
      final merged = base.merge(override);
      expect(merged.titleBarHeight, _kTitleBarShort);
      expect(merged.snapBarTileSpacing, _kDimSmall);
    });
  });

  group('CoreWindowStyle.copyWith', () {
    test('replaces supplied fields, keeps the rest', () {
      const base = CoreWindowStyle(
        titleBarHeight: _kTitleBarShort,
        snapBarTileSpacing: _kDimSmall,
      );
      final next = base.copyWith(snapBarTileSpacing: _kDimLarge);
      expect(next.titleBarHeight, _kTitleBarShort);
      expect(next.snapBarTileSpacing, _kDimLarge);
    });
  });

  group('CoreWindowStyle equality', () {
    test('identical field values compare equal', () {
      const a = CoreWindowStyle(titleBarHeight: _kTitleBarShort);
      const b = CoreWindowStyle(titleBarHeight: _kTitleBarShort);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different field values compare unequal', () {
      const a = CoreWindowStyle(titleBarHeight: _kTitleBarShort);
      const b = CoreWindowStyle(titleBarHeight: _kTitleBarTall);
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreWindowPanelStyle.merge', () {
    test('null other returns this', () {
      const a = CoreWindowPanelStyle(
        borderRadius: CoreBorderRadius.all(_kRadiusSm),
      );
      expect(identical(a.merge(null), a), isTrue);
    });

    test('non-null fields in other override receiver', () {
      const base = CoreWindowPanelStyle(
        borderRadius: CoreBorderRadius.all(_kRadiusSm),
        titleBarColor: _kTitleBarBg,
      );
      const override = CoreWindowPanelStyle(
        borderRadius: CoreBorderRadius.all(_kRadiusLg),
      );
      final merged = base.merge(override);
      expect(merged.borderRadius, const CoreBorderRadius.all(_kRadiusLg));
      expect(merged.titleBarColor, _kTitleBarBg);
    });

    test('null fields in other preserve receiver', () {
      const base = CoreWindowPanelStyle(
        borderRadius: CoreBorderRadius.all(_kRadiusSm),
        titleBarColor: _kTitleBarBg,
      );
      const override = CoreWindowPanelStyle();
      final merged = base.merge(override);
      expect(merged.borderRadius, const CoreBorderRadius.all(_kRadiusSm));
      expect(merged.titleBarColor, _kTitleBarBg);
    });
  });

  group('CoreWindowPanelStyle.copyWith', () {
    test('replaces supplied fields, keeps the rest', () {
      const base = CoreWindowPanelStyle(
        borderRadius: CoreBorderRadius.all(_kRadiusSm),
        titleBarColor: _kTitleBarBg,
      );
      final next = base.copyWith(titleBarColor: _kTitleBarBgAlt);
      expect(next.borderRadius, const CoreBorderRadius.all(_kRadiusSm));
      expect(next.titleBarColor, _kTitleBarBgAlt);
    });

    test('replaces dimensional fields', () {
      const base = CoreWindowPanelStyle(
        titleBarHeight: _kTitleBarShort,
        contentPadding: CoreEdgeInsets.all(_kDimLarge),
      );
      final next = base.copyWith(
        titleBarHeight: _kTitleBarTall,
        controlSpacing: _kDimSmall,
      );
      expect(next.titleBarHeight, _kTitleBarTall);
      expect(next.contentPadding, const CoreEdgeInsets.all(_kDimLarge));
      expect(next.controlSpacing, _kDimSmall);
    });
  });

  group('CoreWindowPanelStyle dimensional fields', () {
    test('non-null dimensional fields override receiver via merge', () {
      const base = CoreWindowPanelStyle(
        titleBarHeight: _kTitleBarShort,
        titleBarPadding: CoreEdgeInsets.symmetric(horizontal: _kDimSmall),
        contentPadding: CoreEdgeInsets.all(_kDimSmall),
        controlButtonStyle: CoreButtonStyle(width: _kDimSmall),
        controlSpacing: _kDimSmall,
      );
      const override = CoreWindowPanelStyle(
        titleBarHeight: _kTitleBarTall,
        contentPadding: CoreEdgeInsets.all(_kDimLarge),
      );
      final merged = base.merge(override);
      expect(merged.titleBarHeight, _kTitleBarTall);
      expect(
        merged.titleBarPadding,
        const CoreEdgeInsets.symmetric(horizontal: _kDimSmall),
      );
      expect(merged.contentPadding, const CoreEdgeInsets.all(_kDimLarge));
      expect(merged.controlButtonStyle?.width, _kDimSmall);
      expect(merged.controlSpacing, _kDimSmall);
    });
  });

  group('CoreWindowPanelStyle equality', () {
    test('identical field values compare equal', () {
      const a = CoreWindowPanelStyle(
        borderRadius: CoreBorderRadius.all(_kRadiusSm),
        titleBarColor: _kTitleBarBg,
      );
      const b = CoreWindowPanelStyle(
        borderRadius: CoreBorderRadius.all(_kRadiusSm),
        titleBarColor: _kTitleBarBg,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different field values compare unequal', () {
      const a = CoreWindowPanelStyle(
        borderRadius: CoreBorderRadius.all(_kRadiusSm),
      );
      const b = CoreWindowPanelStyle(
        borderRadius: CoreBorderRadius.all(_kRadiusLg),
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreWindowTheme.style slot', () {
    test('default style is null', () {
      const t = CoreWindowTheme();
      expect(t.style, isNull);
    });

    test('copyWith replaces style', () {
      const base = CoreWindowTheme();
      const style = CoreWindowStyle(titleBarHeight: _kTitleBarTall);
      final next = base.copyWith(style: style);
      expect(next.style, style);
    });

    test('equality covers style slot', () {
      const a = CoreWindowTheme(
        style: CoreWindowStyle(titleBarHeight: _kTitleBarShort),
      );
      const b = CoreWindowTheme(
        style: CoreWindowStyle(titleBarHeight: _kTitleBarShort),
      );
      const c = CoreWindowTheme(
        style: CoreWindowStyle(titleBarHeight: _kTitleBarTall),
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('CoreWindowPanelTheme.style slot', () {
    test('default style is null', () {
      const t = CoreWindowPanelTheme();
      expect(t.style, isNull);
    });

    test('copyWith replaces style', () {
      const base = CoreWindowPanelTheme();
      const style = CoreWindowPanelStyle(
        borderRadius: CoreBorderRadius.all(_kRadiusLg),
      );
      final next = base.copyWith(style: style);
      expect(next.style, style);
    });

    test('equality covers style slot', () {
      const a = CoreWindowPanelTheme(
        style: CoreWindowPanelStyle(
          borderRadius: CoreBorderRadius.all(_kRadiusSm),
        ),
      );
      const b = CoreWindowPanelTheme(
        style: CoreWindowPanelStyle(
          borderRadius: CoreBorderRadius.all(_kRadiusSm),
        ),
      );
      const c = CoreWindowPanelTheme(
        style: CoreWindowPanelStyle(
          borderRadius: CoreBorderRadius.all(_kRadiusLg),
        ),
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('CoreWindowPanelStyle default chrome', () {
    test('the frame corner is the panel role (12)', () {
      expect(CoreWindowPanelStyle.defaultOuterRadius, CoreRadiusRole.panel);
      expect(CoreWindowPanelStyle.defaultOuterRadius, 12);
      expect(
        CoreWindowPanelStyle.defaultBorderRadius,
        const CoreBorderRadius.all(12),
      );
    });

    test(
      'the title bar pads its sides by space12 and not its top or bottom',
      () {
        expect(
          CoreWindowPanelStyle.defaultTitleBarPadding,
          const CoreEdgeInsets.symmetric(horizontal: CoreSpace.space12),
        );
      },
    );

    test('the frame casts the md step and the strength sits on the layer', () {
      expect(CoreWindowPanelStyle.defaultShadow, CoreShadow.md);
      // The base colour is the opaque `shadow` token — a second alpha on it
      // would multiply the step's own strength (0.1 × 0.1).
      expect(
        CoreWindowPanelStyle.defaultShadowColor,
        const CoreColor.token(CoreColors.shadow),
      );
    });

    test('a window shares the panel corner instead of restating it', () {
      expect(
        CoreWindowStyle.defaultPanelStyle.borderRadius,
        CoreWindowPanelStyle.defaultBorderRadius,
      );
    });
  });

  group('CoreWindowStyle snap bar and tile defaults', () {
    test('the banner and the preview take the panel corner', () {
      expect(
        CoreWindowStyle.defaultSnapBarBorderRadius,
        const CoreBorderRadius.all(CoreRadiusRole.panel),
      );
      expect(
        CoreWindowStyle.defaultSnapPreviewBorderRadius,
        const CoreBorderRadius.all(CoreRadiusRole.panel),
      );
    });

    test('a tile keeps its own corners, concentric with the banner', () {
      // One banner padding inside the banner: 12 - 8 = 4 on the outer edge,
      // half of that where two tiles abut.
      expect(
        CoreWindowStyle.defaultSnapTileBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius4),
      );
      expect(
        CoreWindowStyle.defaultSnapTileInnerBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius2),
      );
      expect(
        CoreWindowStyle.defaultSnapTileBorderRadius.topLeft,
        CoreRadiusRole.panel - CoreSpace.space8,
      );
    });

    test('the banner casts the lg step', () {
      expect(CoreWindowStyle.defaultSnapBarShadow, CoreShadow.lg);
    });

    test('banner and tile colours', () {
      expect(
        CoreWindowStyle.defaultSnapBarBorderColor,
        const CoreColor.token(CoreColors.outlineSubtle),
      );
      expect(
        CoreWindowStyle.defaultSnapBarBackgroundColor,
        const CoreColor.token(CoreColors.surfaceBright),
      );
      expect(
        CoreWindowStyle.defaultSnapTileBorderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
    });

    test('the new fields merge, copy and compare', () {
      const inner = CoreBorderRadius.all(CoreRadius.radius6);
      const outer = CoreBorderRadius.all(CoreRadius.radius8);
      const base = CoreWindowStyle(
        snapTileBorderRadius: outer,
        snapTileInnerBorderRadius: inner,
        snapBarShadow: CoreShadow.sm,
      );

      final merged = const CoreWindowStyle().merge(base);
      expect(merged.snapTileBorderRadius, outer);
      expect(merged.snapTileInnerBorderRadius, inner);
      expect(merged.snapBarShadow, CoreShadow.sm);

      final copied = base.copyWith(snapBarShadow: CoreShadow.md);
      expect(copied.snapBarShadow, CoreShadow.md);
      expect(copied.snapTileBorderRadius, outer);

      // Equal layers in a different list are the same style — and a different
      // step is a different one, so a theme swap that only changes the cast
      // is not mistaken for no change.
      expect(
        base == base.copyWith(snapBarShadow: List.of(CoreShadow.sm)),
        isTrue,
      );
      expect(base == copied, isFalse);
      expect(
        base.hashCode,
        base.copyWith(snapBarShadow: List.of(CoreShadow.sm)).hashCode,
      );
      expect(
        base == base.copyWith(snapTileInnerBorderRadius: outer),
        isFalse,
      );
    });
  });

  group('CoreWindowPanelStyle control button defaults', () {
    test('the close button rests on the same glyph colour as the others', () {
      // The designer's copy draws the close × in the surface-variant tone
      // every other control glyph wears — the error token is for hover only.
      expect(
        CoreWindowPanelStyle.defaultCloseButtonStyle.foregroundColor,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      expect(
        CoreWindowPanelStyle.defaultCloseButtonStyle.foregroundColor,
        CoreWindowPanelStyle.defaultControlButtonStyle.foregroundColor,
      );
    });

    test('the close button keeps its error emphasis on hover', () {
      expect(
        CoreWindowPanelStyle.defaultCloseButtonStyle.hoverBackgroundColor,
        const CoreColor.token(CoreColors.error),
      );
      expect(
        CoreWindowPanelStyle.defaultCloseButtonStyle.hoverForegroundColor,
        const CoreColor.token(CoreColors.onError),
      );
    });
  });
}
