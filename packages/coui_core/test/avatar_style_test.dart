// Tests for CoreAvatarStyle (Epic #1302 — Story #1318).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const double _kFontLabel = 14;
const int _kWeightSemiBold = CoreFontWeight.semiBold;
const _kColorOnSurface = CoreColor.token(CoreColors.onSurface);
const _kColorTokenSurface = CoreColor.token(CoreColors.surface);
const _kColorTokenOutline = CoreColor.token(CoreColors.outline);
const double _kRingWidthBase = 2;
const double _kRingWidthWide = 3;
const double _kRadiusSmall = 8;
const double _kRadiusMedium = 12;

void main() {
  group('CoreAvatarStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreAvatarStyle(
        backgroundColor: _kColorTokenSurface,
        ringColor: _kColorTokenOutline,
        ringWidth: _kRingWidthBase,
        fallbackTextStyle: CoreTextStyle(
          fontSize: _kFontLabel,
          color: _kColorOnSurface,
        ),
      );
      const themeStyle = CoreAvatarStyle(
        fallbackTextStyle: CoreTextStyle(
          fontWeight: _kWeightSemiBold,
        ),
      );
      const widgetStyle = CoreAvatarStyle(ringWidth: _kRingWidthWide);

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.backgroundColor, _kColorTokenSurface);
      expect(effective.ringColor, _kColorTokenOutline);
      expect(effective.ringWidth, _kRingWidthWide);
      expect(effective.fallbackTextStyle?.fontSize, _kFontLabel);
      expect(effective.fallbackTextStyle?.fontWeight, _kWeightSemiBold);
      expect(effective.fallbackTextStyle?.color, _kColorOnSurface);
    });

    test('borderRadius / ringColor / ringWidth flat fields override', () {
      const a = CoreAvatarStyle(
        borderRadius: CoreBorderRadius.all(_kRadiusSmall),
        ringWidth: _kRingWidthBase,
      );
      const b = CoreAvatarStyle(
        borderRadius: CoreBorderRadius.all(_kRadiusMedium),
      );
      final merged = a.merge(b);
      expect(merged.borderRadius, const CoreBorderRadius.all(_kRadiusMedium));
      expect(merged.ringWidth, _kRingWidthBase);
    });

    test('badgeAlignment flat field overrides through merge', () {
      const a = CoreAvatarStyle(badgeAlignment: .topEnd);
      const b = CoreAvatarStyle(badgeAlignment: .bottomEnd);
      final merged = a.merge(b);
      expect(merged.badgeAlignment, CoreAlignment.bottomEnd);
    });

    test('copyWith preserves fallbackTextStyle when not specified', () {
      const base = CoreAvatarStyle(
        fallbackTextStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      final copy = base.copyWith(ringWidth: _kRingWidthBase);
      expect(copy.ringWidth, _kRingWidthBase);
      expect(copy.fallbackTextStyle?.fontSize, _kFontLabel);
    });

    test('equality', () {
      const a = CoreAvatarStyle(
        backgroundColor: _kColorTokenSurface,
        ringColor: _kColorTokenOutline,
      );
      const b = CoreAvatarStyle(
        backgroundColor: _kColorTokenSurface,
        ringColor: _kColorTokenOutline,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CoreAvatarTheme passes through style', () {
    test('CoreAvatarTheme', () {
      const style = CoreAvatarStyle(ringColor: _kColorTokenOutline);
      const theme = CoreAvatarTheme(style: style);
      expect(theme.style, style);
    });
  });

  group('size table', () {
    // One row per size: the diameter and the role the initials are drawn in.
    // The role is the type scale's, so the letters take its size, tracking
    // and leading rather than a fraction of the diameter.
    const rows = <(CoreComponentSize, double, CoreTextStyleToken)>[
      (CoreComponentSize.xs, 24, CoreTextStyles.labelXs),
      (CoreComponentSize.sm, 32, CoreTextStyles.labelMedium),
      (CoreComponentSize.md, 40, CoreTextStyles.labelXl),
      (CoreComponentSize.lg, 48, CoreTextStyles.titleMedium),
      (CoreComponentSize.xl, 64, CoreTextStyles.headlineSmall),
      (CoreComponentSize.xl2, 96, CoreTextStyles.headlineLarge),
    ];

    for (final (size, diameter, role) in rows) {
      test('${size.name}: $diameter px, ${role.name}', () {
        expect(CoreAvatarStyle.diameterFor(size), diameter);
        expect(CoreAvatarStyle.fallbackRoleFor(size).token, role);
      });
    }

    test('every size has a row', () {
      expect(
        CoreAvatarStyle.defaultsBySize.keys,
        containsAll(CoreComponentSize.values),
      );
    });

    test('colour and weight are shared, the role is not', () {
      expect(
        CoreAvatarStyle.defaultFallbackTextStyle.fontWeight,
        CoreFontWeight.semiBold,
      );
      expect(CoreAvatarStyle.defaultFallbackTextStyle.token, isNull);
      expect(
        CoreAvatarStyle.defaultFallbackTextStyle
            .merge(CoreAvatarStyle.fallbackRoleFor(CoreComponentSize.md))
            .fontWeight,
        CoreFontWeight.semiBold,
      );
    });

    test('the widget default is sm', () {
      expect(CoreAvatarContract.defaultSize, CoreComponentSize.sm);
    });

    test('a stated diameter wins for one instance', () {
      const base = CoreAvatarStyle(diameter: 32);
      expect(base.merge(const CoreAvatarStyle(diameter: 52)).diameter, 52);
      expect(base.merge(const CoreAvatarStyle()).diameter, 32);
      expect(base.copyWith(diameter: 128).diameter, 128);
      expect(
        const CoreAvatarStyle(diameter: 1),
        isNot(const CoreAvatarStyle()),
      );
    });
  });

  group('shape', () {
    // The corner the two shapes paint, the way both resolvers derive it:
    // the step's row, the shape's row over it, an override over both.
    CoreBorderRadius cornerOf(
      CoreComponentSize size,
      CoreAvatarShape shape, {
      CoreAvatarStyle? override,
    }) {
      final chrome = CoreAvatarStyle.defaultsBySize[size]!.merge(
        CoreAvatarStyle.defaultsByShape[shape],
      );
      return override?.borderRadius ?? chrome.borderRadius!;
    }

    test('the widget default is a disc', () {
      expect(CoreAvatarShape.defaultShape, CoreAvatarShape.circle);
    });

    test('every shape has a row', () {
      expect(
        CoreAvatarStyle.defaultsByShape.keys,
        containsAll(CoreAvatarShape.values),
      );
    });

    // The rounded tile's corner is a quarter of the step's diameter, written
    // per step — not computed — and every value is on the radius ladder so
    // Web resolves it through `--coui-radius-*` like any other corner.
    const tileCorners = {
      CoreComponentSize.xs: 6.0,
      CoreComponentSize.sm: 8.0,
      CoreComponentSize.md: 10.0,
      CoreComponentSize.lg: 12.0,
      CoreComponentSize.xl: 16.0,
      CoreComponentSize.xl2: 24.0,
    };

    for (final MapEntry(key: size, value: corner) in tileCorners.entries) {
      test('${size.name}: rounded $corner, circle the pill', () {
        expect(
          cornerOf(size, CoreAvatarShape.rounded),
          CoreBorderRadius.all(corner),
        );
        expect(corner, CoreAvatarStyle.diameterFor(size) * 0.25);
        expect(CoreRadius.steps, contains(corner));
        expect(
          cornerOf(size, CoreAvatarShape.circle),
          CoreAvatarStyle.defaultBorderRadius,
        );
      });
    }

    test('the disc corner is the pill', () {
      expect(
        CoreAvatarStyle.defaultBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius9999),
      );
    });

    test('a stated corner wins over both shapes', () {
      const override = CoreAvatarStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
      );
      for (final shape in CoreAvatarShape.values) {
        expect(
          cornerOf(CoreComponentSize.lg, shape, override: override),
          const CoreBorderRadius.all(CoreRadius.radius4),
        );
      }
    });

    test('a stated diameter keeps the step corner', () {
      const override = CoreAvatarStyle(diameter: 52);
      expect(
        cornerOf(
          CoreComponentSize.sm,
          CoreAvatarShape.rounded,
          override: override,
        ),
        const CoreBorderRadius.all(CoreRadius.radius8),
      );
    });

    // The reach avatar.md states: a density moves only the corners on the
    // control-row band (6 … 16), so the tile follows it for some steps and
    // not others, and 24 is outside the band under both.
    test('a density moves the tile corner only inside the row band', () {
      double tile(CoreComponentSize size) =>
          cornerOf(size, CoreAvatarShape.rounded).topLeft;

      const compact = {
        CoreComponentSize.xs: 6.0,
        CoreComponentSize.sm: 8.0,
        CoreComponentSize.md: 8.0,
        CoreComponentSize.lg: 10.0,
        CoreComponentSize.xl: 14.0,
        CoreComponentSize.xl2: 24.0,
      };
      const spacious = {
        CoreComponentSize.xs: 8.0,
        CoreComponentSize.sm: 10.0,
        CoreComponentSize.md: 12.0,
        CoreComponentSize.lg: 14.0,
        CoreComponentSize.xl: 16.0,
        CoreComponentSize.xl2: 24.0,
      };
      for (final size in CoreComponentSize.values) {
        expect(
          CoreDensity.standard.radius(tile(size)),
          tile(size),
          reason: '${size.name} at standard',
        );
        expect(
          CoreDensity.compact.radius(tile(size)),
          compact[size],
          reason: '${size.name} at compact',
        );
        expect(
          CoreDensity.spacious.radius(tile(size)),
          spacious[size],
          reason: '${size.name} at spacious',
        );
      }
    });
  });

  group('colours', () {
    test('the disc is primaryContainer, the initials onPrimaryContainer', () {
      expect(
        CoreAvatarStyle.defaultBackgroundColor,
        const CoreColor.token(CoreColors.primaryContainer),
      );
      expect(
        CoreAvatarStyle.defaultFallbackTextStyle.color,
        const CoreColor.token(CoreColors.onPrimaryContainer),
      );
    });
  });

  group('badge and child icon by step', () {
    // The scaffold's ladder: the badge grows with the step, the child icon is
    // about half the diameter.
    const badges = {
      CoreComponentSize.xs: 8.0,
      CoreComponentSize.sm: 10.0,
      CoreComponentSize.md: 12.0,
      CoreComponentSize.lg: 14.0,
      CoreComponentSize.xl: 16.0,
      CoreComponentSize.xl2: 20.0,
    };
    const icons = {
      CoreComponentSize.xs: 12.0,
      CoreComponentSize.sm: 16.0,
      CoreComponentSize.md: 20.0,
      CoreComponentSize.lg: 24.0,
      CoreComponentSize.xl: 32.0,
      CoreComponentSize.xl2: 48.0,
    };
    for (final size in CoreComponentSize.values) {
      test('${size.name}: badge ${badges[size]}, icon ${icons[size]}', () {
        expect(CoreAvatarStyle.badgeStyleFor(size).size, badges[size]);
        expect(CoreAvatarStyle.childIconStyleFor(size).size, icons[size]);
      });
    }

    test('a lone badge keeps the md size', () {
      expect(
        CoreAvatarBadgeStyle.defaultSize,
        CoreAvatarStyle.badgeStyleFor(CoreComponentSize.md).size,
      );
    });

    test('the nested slots merge field by field', () {
      const base = CoreAvatarStyle(
        badgeStyle: CoreAvatarBadgeStyle(size: 8),
        childIconStyle: CoreIconStyle(size: 12),
      );
      final merged = base.merge(
        const CoreAvatarStyle(
          badgeStyle: CoreAvatarBadgeStyle(backgroundColor: _kColorOnSurface),
          childIconStyle: CoreIconStyle(color: _kColorOnSurface),
        ),
      );
      expect(merged.badgeStyle?.size, 8);
      expect(merged.badgeStyle?.backgroundColor, _kColorOnSurface);
      expect(merged.childIconStyle?.size, 12);
      expect(merged.childIconStyle?.color, _kColorOnSurface);
      expect(
        base,
        isNot(base.copyWith(badgePlacement: CoreAvatarBadgePlacement.corner)),
      );
      expect(
        base.copyWith(badgePlacement: CoreAvatarBadgePlacement.corner),
        base.copyWith(badgePlacement: CoreAvatarBadgePlacement.corner),
      );
    });
  });

  group('badge placement', () {
    test('a disc centres its badge on the outline, a tile in its corner', () {
      expect(
        CoreAvatarStyle.badgePlacementFor(CoreAvatarShape.circle),
        CoreAvatarBadgePlacement.outline,
      );
      expect(
        CoreAvatarStyle.badgePlacementFor(CoreAvatarShape.rounded),
        CoreAvatarBadgePlacement.corner,
      );
      expect(CoreAvatarStyle.defaultBadgeInset, 0);
      expect(CoreAvatarStyle.defaultBadgeAlignment, CoreAlignment.topEnd);
    });

    // The badge's top-left, measured off the scaffold (`Avatar · 스캐폴드안`),
    // which rounds to whole px.
    ({double left, double top}) topLeftOf(
      CoreComponentSize size,
      CoreAvatarShape shape,
    ) {
      final badge = CoreAvatarStyle.badgeStyleFor(size).size!;
      final a = CoreAvatarStyle.badgeAnchorFor(
        diameter: CoreAvatarStyle.diameterFor(size),
        inset: CoreAvatarStyle.defaultBadgeInset,
        alignment: CoreAvatarStyle.defaultBadgeAlignment,
        placement: CoreAvatarStyle.badgePlacementFor(shape),
      );
      return (left: a.x - a.alignX * badge, top: a.y - a.alignY * badge);
    }

    const discs = {
      CoreComponentSize.xs: (16.0, 0.0),
      CoreComponentSize.sm: (22.0, 0.0),
      CoreComponentSize.md: (28.0, 0.0),
      CoreComponentSize.lg: (34.0, 0.0),
      CoreComponentSize.xl: (47.0, 1.0),
      CoreComponentSize.xl2: (72.0, 4.0),
    };
    const tiles = {
      CoreComponentSize.xs: (16.0, 0.0),
      CoreComponentSize.sm: (22.0, 0.0),
      CoreComponentSize.md: (28.0, 0.0),
      CoreComponentSize.lg: (34.0, 0.0),
      CoreComponentSize.xl: (48.0, 0.0),
      CoreComponentSize.xl2: (76.0, 0.0),
    };
    for (final size in CoreComponentSize.values) {
      test('${size.name}: the disc badge sits on the 45° point', () {
        final got = topLeftOf(size, CoreAvatarShape.circle);
        expect(got.left, closeTo(discs[size]!.$1, 0.5));
        expect(got.top, closeTo(discs[size]!.$2, 0.5));
        // Its centre is on the outline: r from the disc's centre, at 45°.
        final r = CoreAvatarStyle.diameterFor(size) / 2;
        final badge = CoreAvatarStyle.badgeStyleFor(size).size!;
        final cx = got.left + badge / 2 - r;
        final cy = r - (got.top + badge / 2);
        expect(cx, closeTo(cy, 1e-9));
        expect(cx * cx + cy * cy, closeTo(r * r, 1e-9));
      });
      test('${size.name}: the tile badge is flush in its corner', () {
        final got = topLeftOf(size, CoreAvatarShape.rounded);
        expect(got.left, tiles[size]!.$1);
        expect(got.top, tiles[size]!.$2);
      });
    }

    test('the anchor does not depend on the badge', () {
      final a = CoreAvatarStyle.badgeAnchorFor(
        diameter: 40,
        inset: 0,
        alignment: CoreAlignment.topEnd,
        placement: CoreAvatarBadgePlacement.outline,
      );
      expect(a.alignX, 0.5);
      expect(a.alignY, 0.5);
      final corner = CoreAvatarStyle.badgeAnchorFor(
        diameter: 40,
        inset: 4,
        alignment: CoreAlignment.bottomStart,
        placement: CoreAvatarBadgePlacement.corner,
      );
      expect(
        (corner.x, corner.y, corner.alignX, corner.alignY),
        (
          4.0,
          36.0,
          0.0,
          1.0,
        ),
      );
    });

    test('an inset pulls an outline badge toward the centre', () {
      final a = CoreAvatarStyle.badgeAnchorFor(
        diameter: 40,
        inset: 4,
        alignment: CoreAlignment.centerEnd,
        placement: CoreAvatarBadgePlacement.outline,
      );
      expect((a.x, a.y), (36.0, 20.0));
      final centre = CoreAvatarStyle.badgeAnchorFor(
        diameter: 40,
        inset: 0,
        alignment: CoreAlignment.center,
        placement: CoreAvatarBadgePlacement.outline,
      );
      expect((centre.x, centre.y), (20.0, 20.0));
    });

    test('a stated placement wins over the shape', () {
      const theme = CoreAvatarStyle(
        badgePlacement: CoreAvatarBadgePlacement.corner,
      );
      expect(
        CoreAvatarStyle.defaultsByShape[CoreAvatarShape.circle]!
            .merge(theme)
            .badgePlacement,
        CoreAvatarBadgePlacement.corner,
      );
    });
  });

  group('badge inner ring', () {
    test('a surface ring, stroke2 on its own', () {
      expect(
        CoreAvatarBadgeStyle.defaultBorderColor,
        const CoreColor.token(CoreColors.surface),
      );
      expect(CoreAvatarBadgeStyle.defaultBorderWidth, CoreStrokeWidth.stroke2);
    });

    test('the two smallest steps hand the badge stroke1', () {
      for (final size in CoreComponentSize.values) {
        final stated = CoreAvatarStyle.badgeStyleFor(size).borderWidth;
        final small =
            size == CoreComponentSize.xs || size == CoreComponentSize.sm;
        expect(
          stated ?? CoreAvatarBadgeStyle.defaultBorderWidth,
          small ? CoreStrokeWidth.stroke1 : CoreStrokeWidth.stroke2,
          reason: size.name,
        );
      }
    });

    test('merge, copyWith and equality carry the ring', () {
      const base = CoreAvatarBadgeStyle(borderWidth: 1);
      final merged = base.merge(
        const CoreAvatarBadgeStyle(borderColor: _kColorOnSurface),
      );
      expect(merged.borderWidth, 1);
      expect(merged.borderColor, _kColorOnSurface);
      expect(merged.copyWith(borderWidth: 3).borderWidth, 3);
      expect(base, const CoreAvatarBadgeStyle(borderWidth: 1));
      expect(base, isNot(const CoreAvatarBadgeStyle(borderWidth: 2)));
      expect(
        base.hashCode,
        const CoreAvatarBadgeStyle(borderWidth: 1).hashCode,
      );
    });
  });
}
