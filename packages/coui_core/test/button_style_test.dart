// Tests for CoreButtonStyle (Epic #1302 — Story #1306).
//
// Mirrors the merge-chain pattern established by CoreCardStyle /
// CoreOutlinedContainerStyle / CoreIconStyle / CoreTextStyle: a single
// nested style flows through `design system default → theme.style →
// theme.variantStyles[v] → widget.buttonStyle`, with right-most
// non-null winning per field. Nested label / icon styles merge
// recursively so a partial override only touches the specified fields.
//
// Note: variant / size / shape are NOT part of CoreButtonStyle —
// Epic #1302 원칙 6/7. They live on the widget as parameters so the
// "same field in two places" anti-pattern is avoided.
// ignore_for_file: avoid_redundant_argument_values

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const double _kHeightSm = 32;
const double _kHeightMd = 40;
const _kPaddingHSm = CoreEdgeInsets.symmetric(horizontal: 12);
const _kPaddingHLg = CoreEdgeInsets.symmetric(horizontal: 24);
const _kGapSm = CoreGapStyle(size: 4);
const _kGapLg = CoreGapStyle(size: 12);
const double _kIconSm = 16;
const double _kIconMd = 20;
const double _kBorderThin = 1;
const double _kBorderThick = 2;
const _kRadiusSm = CoreBorderRadius.all(4);
const _kRadiusLg = CoreBorderRadius.all(12);
const double _kWidthFixed = 200;

// Epic #1415: button chrome color fields are now `CoreColor?` (no
// longer generic over Flutter `Color` / Web `String`).
const _kBgPrimary = CoreColor.token(CoreColors.primary);
const _kBgSecondary = CoreColor.token(CoreColors.secondary);
const _kFgOnPrimary = CoreColor.token(CoreColors.onPrimary);
const _kFgOnPrimaryClr = CoreColor.token(CoreColors.onPrimary);
const _kFgErrorClr = CoreColor.token(CoreColors.error);

const double _kFontBody = 14;
const double _kFontTitle = 18;
const int _kWeightRegular = CoreFontWeight.regular;
const int _kWeightBold = CoreFontWeight.bold;

/// A per-variant style override map covering every [CoreButtonVariant].
///
/// Used by the `CoreButtonTheme` tests so the map exercises the full enum
/// rather than a single arbitrary variant — keeping the pass-through and
/// equality assertions exhaustive.
const Map<CoreButtonVariant, CoreButtonStyle> _kAllVariantStyles = {
  CoreButtonVariant.primary: CoreButtonStyle(backgroundColor: _kBgPrimary),
  CoreButtonVariant.secondary: CoreButtonStyle(backgroundColor: _kBgSecondary),
  CoreButtonVariant.outline: CoreButtonStyle(backgroundColor: _kBgPrimary),
  CoreButtonVariant.ghost: CoreButtonStyle(backgroundColor: _kBgPrimary),
  CoreButtonVariant.plain: CoreButtonStyle(backgroundColor: _kBgPrimary),
  CoreButtonVariant.destructive: CoreButtonStyle(backgroundColor: _kBgPrimary),
  CoreButtonVariant.menu: CoreButtonStyle(backgroundColor: _kBgPrimary),
  CoreButtonVariant.menubar: CoreButtonStyle(backgroundColor: _kBgPrimary),
  CoreButtonVariant.fixed: CoreButtonStyle(backgroundColor: _kBgPrimary),
};

void main() {
  group('CoreButtonStyle.merge', () {
    test('null other returns this', () {
      const a = CoreButtonStyle(
        backgroundColor: _kBgPrimary,
        height: _kHeightMd,
      );
      expect(identical(a.merge(null), a), isTrue);
    });

    test('non-null fields in other override receiver', () {
      const base = CoreButtonStyle(
        backgroundColor: _kBgPrimary,
        foregroundColor: _kFgOnPrimary,
        height: _kHeightMd,
        padding: _kPaddingHLg,
      );
      const override = CoreButtonStyle(
        backgroundColor: _kBgSecondary,
        padding: _kPaddingHSm,
      );
      final merged = base.merge(override);
      expect(merged.backgroundColor, _kBgSecondary);
      expect(merged.foregroundColor, _kFgOnPrimary);
      expect(merged.height, _kHeightMd);
      expect(merged.padding, _kPaddingHSm);
    });

    test('chain — design system → theme.style → variantStyles → widget', () {
      const designSystem = CoreButtonStyle(
        height: _kHeightMd,
        padding: _kPaddingHLg,
        iconLabelGapStyle: _kGapLg,
      );
      const themeStyle = CoreButtonStyle(
        height: _kHeightSm,
      );
      const variantStyle = CoreButtonStyle(
        backgroundColor: _kBgPrimary,
        foregroundColor: _kFgOnPrimary,
      );
      const widgetStyle = CoreButtonStyle(
        padding: _kPaddingHSm,
        iconLabelGapStyle: _kGapSm,
      );

      final effective = designSystem
          .merge(themeStyle)
          .merge(variantStyle)
          .merge(widgetStyle);

      expect(effective.height, _kHeightSm); // theme override
      expect(effective.backgroundColor, _kBgPrimary); // variant override
      expect(effective.foregroundColor, _kFgOnPrimary); // variant override
      expect(effective.padding, _kPaddingHSm); // widget override
      expect(effective.iconLabelGapStyle, _kGapSm); // widget override
    });

    test('right-most non-null wins on each field', () {
      const a = CoreButtonStyle(
        height: _kHeightSm,
        padding: _kPaddingHSm,
      );
      const b = CoreButtonStyle(height: _kHeightMd);
      const c = CoreButtonStyle(padding: _kPaddingHLg);

      final result = a.merge(b).merge(c);

      expect(result.height, _kHeightMd); // from b (c is null)
      expect(result.padding, _kPaddingHLg); // from c overrides a
    });

    test('border / minWidth / maxWidth / width merge', () {
      const base = CoreButtonStyle(
        borderColor: _kFgOnPrimary,
        borderWidth: _kBorderThin,
        borderRadius: _kRadiusSm,
        width: _kWidthFixed,
        minWidth: _kHeightSm,
        maxWidth: _kHeightMd,
      );
      const override = CoreButtonStyle(
        borderWidth: _kBorderThick,
        borderRadius: _kRadiusLg,
      );
      final merged = base.merge(override);
      expect(merged.borderColor, _kFgOnPrimary);
      expect(merged.borderWidth, _kBorderThick);
      expect(merged.borderRadius, _kRadiusLg);
      expect(merged.minWidth, _kHeightSm);
      expect(merged.maxWidth, _kHeightMd);
      expect(merged.width, _kWidthFixed);
    });

    test('hover override colours merge (right-most non-null wins)', () {
      const base = CoreButtonStyle(
        hoverBackgroundColor: _kBgPrimary,
        hoverForegroundColor: _kFgOnPrimary,
        hoverBorderColor: _kFgOnPrimary,
      );
      const override = CoreButtonStyle(hoverBackgroundColor: _kBgSecondary);
      final merged = base.merge(override);
      expect(merged.hoverBackgroundColor, _kBgSecondary); // override wins
      expect(merged.hoverForegroundColor, _kFgOnPrimary); // base kept
      expect(merged.hoverBorderColor, _kFgOnPrimary); // base kept
    });
  });

  group('CoreButtonStyle.merge — nested label / icon styles', () {
    test('labelStyle merges recursively (subset override)', () {
      const base = CoreButtonStyle(
        labelStyle: CoreTextStyle(
          fontSize: _kFontBody,
          fontWeight: _kWeightRegular,
          color: _kFgOnPrimaryClr,
        ),
      );
      const override = CoreButtonStyle(
        labelStyle: CoreTextStyle(fontWeight: _kWeightBold),
      );
      final merged = base.merge(override);
      // fontSize / color from base, fontWeight from override.
      expect(merged.labelStyle?.fontSize, _kFontBody);
      expect(merged.labelStyle?.fontWeight, _kWeightBold);
      expect(merged.labelStyle?.color, _kFgOnPrimaryClr);
    });

    test('leadingIconStyle merges recursively', () {
      const base = CoreButtonStyle(
        leadingIconStyle: CoreIconStyle(
          size: _kIconMd,
          color: _kFgOnPrimaryClr,
        ),
      );
      const override = CoreButtonStyle(
        leadingIconStyle: CoreIconStyle(color: _kFgErrorClr),
      );
      final merged = base.merge(override);
      expect(merged.leadingIconStyle?.size, _kIconMd);
      expect(merged.leadingIconStyle?.color, _kFgErrorClr);
    });

    test('trailingIconStyle merges recursively', () {
      const base = CoreButtonStyle(
        trailingIconStyle: CoreIconStyle(
          size: _kIconSm,
          color: _kFgOnPrimaryClr,
        ),
      );
      const override = CoreButtonStyle(
        trailingIconStyle: CoreIconStyle(size: _kIconMd),
      );
      final merged = base.merge(override);
      expect(merged.trailingIconStyle?.size, _kIconMd);
      expect(merged.trailingIconStyle?.color, _kFgOnPrimaryClr);
    });

    test('null nested style on base inherits from override', () {
      const base = CoreButtonStyle();
      const override = CoreButtonStyle(
        labelStyle: CoreTextStyle(
          fontSize: _kFontTitle,
          color: _kFgErrorClr,
        ),
      );
      final merged = base.merge(override);
      expect(merged.labelStyle?.fontSize, _kFontTitle);
      expect(merged.labelStyle?.color, _kFgErrorClr);
    });

    test('null nested style on override keeps base', () {
      const base = CoreButtonStyle(
        leadingIconStyle: CoreIconStyle(size: _kIconMd),
      );
      const override = CoreButtonStyle();
      final merged = base.merge(override);
      expect(merged.leadingIconStyle?.size, _kIconMd);
    });
  });

  group('CoreButtonStyle equality', () {
    test('same fields → equal', () {
      const a = CoreButtonStyle(
        backgroundColor: _kBgPrimary,
        height: _kHeightMd,
        padding: _kPaddingHLg,
      );
      const b = CoreButtonStyle(
        backgroundColor: _kBgPrimary,
        height: _kHeightMd,
        padding: _kPaddingHLg,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different backgroundColor → not equal', () {
      const a = CoreButtonStyle(backgroundColor: _kBgPrimary);
      const b = CoreButtonStyle(backgroundColor: _kBgSecondary);
      expect(a, isNot(equals(b)));
    });

    test('different hoverBackgroundColor → not equal', () {
      const a = CoreButtonStyle(hoverBackgroundColor: _kBgPrimary);
      const b = CoreButtonStyle(hoverBackgroundColor: _kBgSecondary);
      expect(a, isNot(equals(b)));
    });

    test('different labelStyle → not equal', () {
      const a = CoreButtonStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontBody),
      );
      const b = CoreButtonStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontTitle),
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreButtonStyle.copyWith', () {
    test('only-supplied fields override', () {
      const base = CoreButtonStyle(
        backgroundColor: _kBgPrimary,
        height: _kHeightMd,
        padding: _kPaddingHLg,
      );
      final copy = base.copyWith(height: _kHeightSm);
      expect(copy.backgroundColor, _kBgPrimary);
      expect(copy.height, _kHeightSm);
      expect(copy.padding, _kPaddingHLg);
    });

    test('preserves nested styles when not specified', () {
      const base = CoreButtonStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontBody),
        leadingIconStyle: CoreIconStyle(size: _kIconMd),
      );
      final copy = base.copyWith(backgroundColor: _kBgSecondary);
      expect(copy.backgroundColor, _kBgSecondary);
      expect(copy.labelStyle?.fontSize, _kFontBody);
      expect(copy.leadingIconStyle?.size, _kIconMd);
    });

    test('hover override colours copyWith', () {
      const base = CoreButtonStyle(hoverBackgroundColor: _kBgPrimary);
      final copy = base.copyWith(
        hoverForegroundColor: _kFgErrorClr,
        hoverBorderColor: _kFgErrorClr,
      );
      expect(copy.hoverBackgroundColor, _kBgPrimary); // preserved
      expect(copy.hoverForegroundColor, _kFgErrorClr);
      expect(copy.hoverBorderColor, _kFgErrorClr);
    });
  });

  group('CoreButtonTheme', () {
    test('style + variantStyles + animationDuration + disableHoverEffect '
        'pass through', () {
      const style = CoreButtonStyle(
        padding: _kPaddingHLg,
        animationDuration: Duration(milliseconds: 150),
        disableHoverEffect: true,
      );
      const theme = CoreButtonTheme(
        style: style,
        variantStyles: _kAllVariantStyles,
      );
      expect(theme.style, style);
      expect(
        theme.variantStyles![CoreButtonVariant.primary],
        _kAllVariantStyles[CoreButtonVariant.primary],
      );
      expect(theme.style!.animationDuration, const Duration(milliseconds: 150));
      expect(theme.style!.disableHoverEffect, isTrue);
    });

    test('null style + null variantStyles', () {
      const theme = CoreButtonTheme();
      expect(theme.style, isNull);
      expect(theme.variantStyles, isNull);
    });

    test('equality with same variantStyles map content', () {
      const a = CoreButtonTheme(
        style: CoreButtonStyle(
          padding: _kPaddingHLg,
          animationDuration: Duration(milliseconds: 200),
        ),
        variantStyles: _kAllVariantStyles,
      );
      const b = CoreButtonTheme(
        style: CoreButtonStyle(
          padding: _kPaddingHLg,
          animationDuration: Duration(milliseconds: 200),
        ),
        variantStyles: _kAllVariantStyles,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CoreButtonStyle design-system defaults (Phase 6f)', () {
    test('defaultAnimationDuration is the CoreDuration.ms150 token', () {
      expect(
        CoreButtonStyle.defaultAnimationDuration,
        const Duration(milliseconds: CoreDuration.ms150),
      );
    });

    test('defaultsByVariant covers every CoreButtonVariant', () {
      for (final variant in CoreButtonVariant.values) {
        expect(
          CoreButtonStyle.defaultsByVariant[variant],
          isNotNull,
          reason: 'missing variant chrome for ${variant.name}',
        );
      }
    });

    test(
      'menu / menubar resting background is the hover hue at zero alpha '
      '(no transparent-black hover flicker)',
      () {
        // The resting fill must be the SAME token as the hover fill but at
        // opacity 0 — not the shared `transparent` (= transparent black)
        // sentinel — so the hover `AnimatedContainer` (Flutter) / CSS
        // `:hover` (Web) lerps alpha within the grey hue instead of
        // passing through a dark semi-transparent black mid-transition.
        for (final variant in [
          CoreButtonVariant.menu,
          CoreButtonVariant.menubar,
        ]) {
          final vs = CoreButtonStyle.defaultsByVariant[variant]!;
          expect(
            vs.backgroundColor?.token,
            CoreColors.surfaceContainerHighest,
            reason: '${variant.name} resting bg must share the hover token',
          );
          expect(
            vs.backgroundColor?.opacity,
            0,
            reason: '${variant.name} resting bg must be fully transparent',
          );
          // And it must match the hover token so only alpha differs.
          expect(vs.hoverBackgroundColor?.token, vs.backgroundColor?.token);
        }
      },
    );
  });

  // Issue #3293 — token category: a border slot must reference a *border*
  // alias, never a surface one.
  //
  // The outline variant used to point `borderColor` / `hoverBorderColor` at
  // `surfaceContainer`, the very slot its fill uses. On a page whose own
  // background is `surfaceContainer`, fill + border + page collapsed to a
  // single colour and the button lost its shape (1.004:1 measured in a
  // consumer app). Nothing in the type system prevents that, so guard it.
  group('token category (#3293)', () {
    test('no variant reads a border slot from a surface alias', () {
      for (final MapEntry(key: variant, value: style)
          in CoreButtonStyle.defaultsByVariant.entries) {
        final borderSlots = <String, CoreColor?>{
          'borderColor': style.borderColor,
          'hoverBorderColor': style.hoverBorderColor,
          'disabledBorderColor': style.disabledBorderColor,
          'selectedBorderColor': style.selectedBorderColor,
        };

        for (final MapEntry(key: slot, value: color) in borderSlots.entries) {
          final token = color?.token;
          if (token == null) continue;

          expect(
            token.name.startsWith('surface'),
            isFalse,
            reason:
                '${variant.name}.$slot references the surface alias '
                '"${token.name}". Border chrome must not depend on a slot '
                'whose whole job is to be a background — use `outline` '
                '(or `outlineVariant` for input chrome).',
          );
        }
      }
    });

    test('outline variant borders resolve to the outlineVariant alias', () {
      final style =
          CoreButtonStyle.defaultsByVariant[CoreButtonVariant.outline]!;

      // The pale boundary (designer decision 2026-10-23): the label says
      // "button", the stroke only marks the edge.
      expect(style.borderColor?.token, CoreColors.outlineVariant);
      expect(style.hoverBorderColor?.token, CoreColors.outlineVariant);
      expect(style.disabledBorderColor?.token, CoreColors.disabledOutline);
      // Fill is solid `surface`, not a translucent `surfaceContainer` wash
      // — the boundary is entirely the stroke above (see
      // `defaultsByVariant[.outline]`'s doc comment for why).
      expect(style.backgroundColor?.token, CoreColors.surface);
    });
  });

  // #3773 — `defaultsBySize[size]!` is a Map lookup, not a `switch`, so
  // Dart's exhaustiveness checker never sees it: changing xs from 32 to
  // 24 (the exact regression this issue measured) compiles clean, every
  // test still passes, and the only signal is a silent product-wide
  // pixel shift. This group is the net — it fails the moment a member
  // is added without a matching entry, before any `!` ever gets a
  // chance to throw at runtime.
  group('CoreButtonStyle.defaultsBySize (#3773)', () {
    test('covers every CoreComponentSize member', () {
      for (final size in CoreComponentSize.values) {
        expect(
          CoreButtonStyle.defaultsBySize[size],
          isNotNull,
          reason:
              'missing size chrome for CoreComponentSize.${size.name} — '
              'every `defaultsBySize[size]!` lookup in the resolvers '
              'assumes full coverage and would crash at runtime',
        );
      }
    });

    test('has exactly one entry per CoreComponentSize member', () {
      // Guards the other direction: a stale entry left behind after a
      // member is removed from CoreComponentSize.
      expect(
        CoreButtonStyle.defaultsBySize.length,
        CoreComponentSize.values.length,
      );
    });
  });

  // #4427 — the press shrink is a Core field both resolvers read, so
  // the value-type boilerplate has to carry it: a field left out of
  // `merge` drops a theme override, one left out of `==` makes a changed
  // scale compare equal and skip the rebuild.
  group('CoreButtonStyle.pressedScale (#4427)', () {
    test('the default is the hover scale-down factor, not a new number', () {
      expect(
        CoreButtonStyle.defaultPressedScale,
        CoreHoverStyle.defaultScaleDownFactor,
      );
    });

    test('merge — right-most non-null wins, null keeps the base', () {
      const base = CoreButtonStyle(pressedScale: 0.9);

      expect(
        base.merge(const CoreButtonStyle(pressedScale: 1)).pressedScale,
        1,
      );
      expect(base.merge(const CoreButtonStyle()).pressedScale, 0.9);
    });

    test('copyWith sets it and leaves it alone when unmentioned', () {
      const base = CoreButtonStyle(pressedScale: 0.9);

      expect(base.copyWith(pressedScale: 0.8).pressedScale, 0.8);
      expect(base.copyWith(height: 40).pressedScale, 0.9);
    });

    test('two styles differing only in it are not equal', () {
      const a = CoreButtonStyle(pressedScale: 0.9);
      const b = CoreButtonStyle(pressedScale: 0.8);

      expect(a, isNot(b));
      expect(a.hashCode, isNot(b.hashCode));
    });
  });

  // The icon, gap and label-weight values the size and variant rows state.
  // Both resolvers read these rows, so the numbers are pinned here once
  // rather than in each platform's tests.
  group('CoreButtonStyle.defaultsBySize — icon and gap ladders', () {
    double iconOf(CoreComponentSize s) =>
        CoreButtonStyle.defaultsBySize[s]!.leadingIconStyle!.size!;
    double trailingOf(CoreComponentSize s) =>
        CoreButtonStyle.defaultsBySize[s]!.trailingIconStyle!.size!;
    double shapeOf(CoreComponentSize s) =>
        CoreButtonStyle.defaultsBySize[s]!.iconShapeIconStyle!.size!;
    double gapOf(CoreComponentSize s) =>
        CoreButtonStyle.defaultsBySize[s]!.iconLabelGapStyle!.size!;
    const sizes = CoreComponentSize.values;

    test('the glyph beside a label is 12 · 14 · 16 · 18 · 20 · 24', () {
      expect(sizes.map(iconOf), [12, 14, 16, 18, 20, 24]);
      expect(sizes.map(trailingOf), sizes.map(iconOf));
    });

    test('the glyph of a square or circle button is 14 · 16 · 18 · 20 · 24 · '
        '28', () {
      expect(sizes.map(shapeOf), [14, 16, 18, 20, 24, 28]);
    });

    test('the icon-to-label gap is 4 · 6 · 6 · 6 · 8 · 8', () {
      expect(sizes.map(gapOf), [4, 6, 6, 6, 8, 8]);
    });

    test('a button with no label draws a step larger glyph than one with a '
        'label, at every size', () {
      for (final size in sizes) {
        expect(shapeOf(size), greaterThan(iconOf(size)), reason: size.name);
      }
    });
  });

  group('CoreButtonVariantStyle.labelStyle', () {
    test('no variant states a label weight — every label is its role', () {
      // A weight on a variant row would draw a button label at a weight no
      // other label of that size has, and detach the canvas text style.
      for (final entry in CoreButtonStyle.defaultsByVariant.entries) {
        expect(
          entry.value.labelStyle?.fontWeight,
          isNull,
          reason: entry.key.name,
        );
      }
    });

    test('a variant states the weight and nothing else of its label', () {
      // `labelStyleFor` reads the weight of this slot alone, so a statement
      // of a role, a size or a colour on a variant row would be dropped
      // without a trace.
      for (final entry in CoreButtonStyle.defaultsByVariant.entries) {
        final stated = entry.value.labelStyle;
        if (stated == null) continue;
        expect(
          stated,
          CoreTextStyle(fontWeight: stated.fontWeight),
          reason: entry.key.name,
        );
      }
    });

    test("menu · menubar · fixed state no label (the role's medium)", () {
      for (final variant in [
        CoreButtonVariant.menu,
        CoreButtonVariant.menubar,
        CoreButtonVariant.fixed,
      ]) {
        expect(
          CoreButtonStyle.defaultsByVariant[variant]!.labelStyle,
          isNull,
          reason: variant.name,
        );
      }
    });

    test('every variant is accounted for', () {
      expect(CoreButtonStyle.defaultsByVariant.keys.toSet(), {
        ...CoreButtonVariant.values,
      });
    });
  });

  group('CoreButtonStyle.labelStyleFor', () {
    const size = CoreComponentSize.md;
    final role = CoreButtonStyle.defaultsBySize[size]!.labelStyle!;
    const semibold = CoreTextStyle(fontWeight: CoreFontWeight.semiBold);

    test("a variant weight lands on top of the size row's role", () {
      final style = CoreButtonStyle.labelStyleFor(
        size: size,
        variantLabelStyle: semibold,
        labelStyle: null,
      );
      expect(style.token, role.token);
      expect(style.fontWeight, CoreFontWeight.semiBold);
    });

    test('no variant weight leaves the role as it is', () {
      expect(
        CoreButtonStyle.labelStyleFor(
          size: size,
          variantLabelStyle: null,
          labelStyle: null,
        ),
        role,
      );
    });

    test("only the weight of a variant's statement is read — a size, a line "
        'box or a colour on it never reaches the label', () {
      final style = CoreButtonStyle.labelStyleFor(
        size: size,
        variantLabelStyle: const CoreTextStyle(
          fontWeight: CoreFontWeight.semiBold,
          fontSize: 99,
          lineHeightPx: 99,
          letterSpacing: 9,
          fontFamily: 'Elsewhere',
          color: CoreColor.token(CoreColors.error),
        ),
        labelStyle: null,
      );
      expect(style.fontWeight, CoreFontWeight.semiBold);
      expect(style.token, role.token);
      expect(style.fontSize, role.fontSize);
      expect(style.lineHeightPx, role.lineHeightPx);
      expect(style.letterSpacing, role.letterSpacing);
      expect(style.fontFamily, role.fontFamily);
      expect(style.color, role.color);
    });

    test("a variant statement without a weight leaves the role's own", () {
      expect(
        CoreButtonStyle.labelStyleFor(
          size: size,
          variantLabelStyle: const CoreTextStyle(
            color: CoreColor.token(CoreColors.error),
          ),
          labelStyle: null,
        ),
        role,
      );
    });

    test('a label style that states only a colour or a size leaves the '
        'weight to the variant', () {
      final coloured = CoreButtonStyle.labelStyleFor(
        size: size,
        variantLabelStyle: semibold,
        labelStyle: const CoreTextStyle(
          color: CoreColor.token(CoreColors.error),
        ),
      );
      expect(coloured.fontWeight, CoreFontWeight.semiBold);
      expect(coloured.color, const CoreColor.token(CoreColors.error));

      final sized = CoreButtonStyle.labelStyleFor(
        size: size,
        variantLabelStyle: semibold,
        labelStyle: const CoreTextStyle(fontSize: 18),
      );
      expect(sized.fontWeight, CoreFontWeight.semiBold);
      expect(sized.fontSize, 18);
      expect(sized.token, role.token);
    });

    test("a composer that states a role token takes the role's own weight, "
        "not the variant's", () {
      final style = CoreButtonStyle.labelStyleFor(
        size: size,
        variantLabelStyle: semibold,
        labelStyle: const CoreTextStyle.token(CoreTextStyles.bodySmall),
      );
      expect(style.token, CoreTextStyles.bodySmall);
      // Null here means "the role's own weight" — the 400 of `bodySmall`,
      // read through the token at render time. Anything else would be the
      // variant's 600 leaking onto a label that named its own role.
      expect(style.fontWeight, isNull);
    });

    test('a composer that states a weight keeps that weight', () {
      final style = CoreButtonStyle.labelStyleFor(
        size: size,
        variantLabelStyle: semibold,
        labelStyle: const CoreTextStyle(fontWeight: CoreFontWeight.regular),
      );
      expect(style.fontWeight, CoreFontWeight.regular);
      expect(style.token, role.token);
    });

    test('the role comes from the size row', () {
      for (final entry in CoreButtonStyle.defaultsBySize.entries) {
        expect(
          CoreButtonStyle.labelStyleFor(
            size: entry.key,
            variantLabelStyle: semibold,
            labelStyle: null,
          ).token,
          entry.value.labelStyle!.token,
          reason: entry.key.name,
        );
      }
    });
  });

  group('CoreButtonStyle.iconSizeFor', () {
    const size = CoreComponentSize.sm;
    final row = CoreButtonStyle.defaultsBySize[size]!;

    double sizeFor({
      required bool iconShaped,
      CoreIconStyle? shape,
      CoreIconStyle? leading,
      CoreIconStyle? trailing,
    }) => CoreButtonStyle.iconSizeFor(
      size: size,
      iconShaped: iconShaped,
      iconShapeOverride: shape,
      leadingOverride: leading,
      trailingOverride: trailing,
    );

    test("a button with a label reads the row's leading glyph", () {
      expect(sizeFor(iconShaped: false), row.leadingIconStyle!.size);
    });

    test("a shaped button reads the row's shape glyph", () {
      expect(sizeFor(iconShaped: true), row.iconShapeIconStyle!.size);
      expect(sizeFor(iconShaped: true), isNot(row.leadingIconStyle!.size));
    });

    test('a slot statement beats the row, in either shape', () {
      const leading = CoreIconStyle(size: 22);
      const trailing = CoreIconStyle(size: 30);
      expect(sizeFor(iconShaped: false, leading: leading), 22);
      expect(sizeFor(iconShaped: true, leading: leading), 22);
      expect(
        sizeFor(iconShaped: false, leading: leading, trailing: trailing),
        22,
      );
      expect(sizeFor(iconShaped: true, trailing: trailing), 30);
    });

    test('the shape statement beats a slot statement, on a shaped button '
        'only', () {
      const shape = CoreIconStyle(size: 26);
      const leading = CoreIconStyle(size: 22);
      expect(sizeFor(iconShaped: true, shape: shape, leading: leading), 26);
      expect(
        sizeFor(iconShaped: false, shape: shape, leading: leading),
        22,
        reason: 'a button with a label never reads the shape glyph',
      );
      expect(
        sizeFor(iconShaped: false, shape: shape),
        row.leadingIconStyle!.size,
      );
    });
  });

  group('CoreButtonStyle.iconShapeIconStyle', () {
    const base = CoreButtonStyle(
      iconShapeIconStyle: CoreIconStyle(size: 16),
    );

    test('merge — right-most non-null wins, nested merge keeps the rest', () {
      expect(
        base
            .merge(
              const CoreButtonStyle(
                iconShapeIconStyle: CoreIconStyle(
                  color: CoreColor.token(CoreColors.error),
                ),
              ),
            )
            .iconShapeIconStyle,
        const CoreIconStyle(
          size: 16,
          color: CoreColor.token(CoreColors.error),
        ),
      );
      expect(base.merge(const CoreButtonStyle()).iconShapeIconStyle?.size, 16);
    });

    test('copyWith sets it and leaves it alone when unmentioned', () {
      expect(
        base
            .copyWith(iconShapeIconStyle: const CoreIconStyle(size: 20))
            .iconShapeIconStyle
            ?.size,
        20,
      );
      expect(base.copyWith(height: 40).iconShapeIconStyle?.size, 16);
    });

    test('two styles differing only in it are not equal', () {
      const other = CoreButtonStyle(
        iconShapeIconStyle: CoreIconStyle(size: 18),
      );
      expect(base, isNot(other));
      expect(base.hashCode, isNot(other.hashCode));
      expect(
        base,
        const CoreButtonStyle(iconShapeIconStyle: CoreIconStyle(size: 16)),
      );
    });
  });
}
