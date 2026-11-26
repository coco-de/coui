// Tests for CoreTabsStyle / CoreTabsTheme / CoreTabPaneStyle.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const double _kFontLabel = 14;
const double _kFontTitle = 18;
const _kColorPrimary = CoreColor.token(CoreColors.primary);
const _kColorSurface = CoreColor.token(CoreColors.surface);

void main() {
  group('CoreTabsStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreTabsStyle(
        activeIndicatorColor: _kColorPrimary,
        activeIndicatorThickness: 2,
        tabBarPadding: CoreEdgeInsets.symmetric(horizontal: 12),
      );
      const themeStyle = CoreTabsStyle(
        tabBarPadding: CoreEdgeInsets.symmetric(horizontal: 16),
      );
      const widgetStyle = CoreTabsStyle(
        activeIndicatorThickness: 3,
      );
      final effective = designSystem.merge(themeStyle).merge(widgetStyle);
      expect(effective.activeIndicatorColor, _kColorPrimary);
      expect(effective.activeIndicatorThickness, 3);
      expect(
        effective.tabBarPadding,
        const CoreEdgeInsets.symmetric(horizontal: 16),
      );
    });

    test('contentTextStyle merges recursively', () {
      const a = CoreTabsStyle(
        contentTextStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      const b = CoreTabsStyle(
        contentTextStyle: CoreTextStyle(fontSize: _kFontTitle),
      );
      final merged = a.merge(b);
      expect(merged.contentTextStyle?.fontSize, _kFontTitle);
    });

    test('equality + copyWith', () {
      const a = CoreTabsStyle(
        activeIndicatorRadius: CoreBorderRadius.all(4),
        tabSpacing: 8,
      );
      const b = CoreTabsStyle(
        activeIndicatorRadius: CoreBorderRadius.all(4),
        tabSpacing: 8,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      final copy = a.copyWith(tabSpacing: 12);
      expect(copy.activeIndicatorRadius, const CoreBorderRadius.all(4));
      expect(copy.tabSpacing, 12);
    });

    test('indicatorTransitionDuration override field', () {
      const base = CoreTabsStyle(
        indicatorTransitionDuration: Duration(milliseconds: 100),
      );
      const override = CoreTabsStyle(
        indicatorTransitionDuration: Duration(milliseconds: 250),
      );
      final merged = base.merge(override);
      expect(
        merged.indicatorTransitionDuration,
        const Duration(milliseconds: 250),
      );
      final copy = base.copyWith(
        indicatorTransitionDuration: const Duration(milliseconds: 100),
      );
      expect(
        copy.indicatorTransitionDuration,
        const Duration(milliseconds: 100),
      );
    });

    test('clickableStyle merges recursively', () {
      const a = CoreTabsStyle(
        clickableStyle: CoreClickableStyle(pressedScale: 1),
      );
      const b = CoreTabsStyle(
        clickableStyle: CoreClickableStyle(disabledOpacity: 0.3),
      );
      final merged = a.merge(b);
      expect(merged.clickableStyle?.pressedScale, 1);
      expect(merged.clickableStyle?.disabledOpacity, 0.3);
    });

    test('swipeSensitivity override field', () {
      const base = CoreTabsStyle(swipeSensitivity: 20);
      const override = CoreTabsStyle(swipeSensitivity: 40);
      final merged = base.merge(override);
      expect(merged.swipeSensitivity, 40);
      final copy = base.copyWith(swipeSensitivity: 30);
      expect(copy.swipeSensitivity, 30);
      // Equality + hashCode include swipeSensitivity.
      const a = CoreTabsStyle(swipeSensitivity: 20);
      const b = CoreTabsStyle(swipeSensitivity: 20);
      const c = CoreTabsStyle(swipeSensitivity: 30);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('itemHeight override field (#3885 — Epic K axis 8-2)', () {
      const base = CoreTabsStyle(itemHeight: 40);
      const override = CoreTabsStyle(itemHeight: 48);
      final merged = base.merge(override);
      expect(merged.itemHeight, 48);
      final copy = base.copyWith(itemHeight: 56);
      expect(copy.itemHeight, 56);
      // Equality + hashCode include itemHeight.
      const a = CoreTabsStyle(itemHeight: 40);
      const b = CoreTabsStyle(itemHeight: 40);
      const c = CoreTabsStyle(itemHeight: 48);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('defaultsByVariant covers every variant', () {
      for (final variant in CoreTabVariant.values) {
        expect(CoreTabsStyle.defaultsByVariant[variant], isNotNull);
      }
      final pill = CoreTabsStyle.defaultsByVariant[CoreTabVariant.pill]!;
      expect(pill.backgroundColor, isNotNull);
      expect(pill.borderColor, isNull);
      final underline =
          CoreTabsStyle.defaultsByVariant[CoreTabVariant.underline]!;
      expect(underline.backgroundColor, isNull);
      expect(underline.borderColor, isNotNull);
    });

    test('the underline rule is the outlineSubtle hairline in every mode', () {
      final rule = CoreTabsStyle
          .defaultsByVariant[CoreTabVariant.underline]!
          .borderColor!;
      for (final (mode, scheme) in [
        ('light', CouiColorPresets.source.light()),
        ('dark', CouiColorPresets.source.dark()),
        ('high-contrast light', CouiColorPresets.source.highContrastLight()),
        ('high-contrast dark', CouiColorPresets.source.highContrastDark()),
      ]) {
        expect(
          scheme.resolve(rule).argb,
          scheme.resolve(const CoreColor.token(CoreColors.outlineSubtle)).argb,
          reason: mode,
        );
      }
    });
  });

  group('CoreTabsStyle.defaultsByVariant rows', () {
    const underline = CoreTabVariant.underline;
    const pill = CoreTabVariant.pill;
    final underlineRow = CoreTabsStyle.defaultsByVariant[underline]!;
    final pillRow = CoreTabsStyle.defaultsByVariant[pill]!;

    test("underline draws its rung's role, 600 selected / 500 idle", () {
      expect(underlineRow.contentTextStyle, isNull);
      expect(underlineRow.activeFontWeight, CoreFontWeight.semiBold);
      expect(underlineRow.inactiveFontWeight, CoreFontWeight.medium);
    });

    test('underline rule spans the label: no tab inset, 20 between tabs', () {
      expect(underlineRow.tabPadding, CoreEdgeInsets.zero);
      expect(underlineRow.tabSpacing, CoreSpace.space20);
      expect(underlineRow.tabSpacing, 20);
      // The ruled row has no container inset, and no platform reads one.
      expect(underlineRow.tabBarPadding, CoreEdgeInsets.zero);
    });

    test(
      "pill states no role of its own: 600 selected, the role's 500 idle",
      () {
        expect(pillRow.contentTextStyle, isNull);
        expect(pillRow.activeFontWeight, CoreFontWeight.semiBold);
        expect(pillRow.inactiveFontWeight, CoreFontWeight.medium);
      },
    );

    test('an idle tab reads the subtle ink on both variants', () {
      for (final row in [pillRow, underlineRow]) {
        expect(
          row.inactiveContentColor,
          const CoreColor.token(CoreColors.onSurfaceSubtle),
        );
      }
    });

    test('pill track insets 2 on every side, tabs 2 apart', () {
      expect(pillRow.tabBarPadding, const CoreEdgeInsets.all(CoreSpace.space2));
      expect(pillRow.tabSpacing, CoreSpace.space2);
      expect(pillRow.tabSpacing, 2);
    });

    test('pill selected chip is the raised face on the surface-container '
        'track', () {
      expect(
        pillRow.activeIndicatorColor,
        const CoreColor.token(CoreColors.surfaceRaised),
      );
      expect(
        pillRow.backgroundColor,
        const CoreColor.token(CoreColors.surfaceContainer),
      );
      // A disabled selected chip is still an area — the container token.
      expect(
        pillRow.disabledIndicatorColor,
        const CoreColor.token(CoreColors.disabledContainer),
      );
      // The chip is a different face from the track in every mode, so the
      // selection never rests on the label colour alone.
      for (final (mode, scheme) in [
        ('light', CouiColorPresets.source.light()),
        ('dark', CouiColorPresets.source.dark()),
        ('high-contrast light', CouiColorPresets.source.highContrastLight()),
        ('high-contrast dark', CouiColorPresets.source.highContrastDark()),
      ]) {
        expect(
          scheme.resolve(pillRow.activeIndicatorColor).argb,
          isNot(scheme.resolve(pillRow.backgroundColor!).argb),
          reason: mode,
        );
      }
    });

    test('pill chip radius is 6, the flat default tab gap stays 0', () {
      expect(
        CoreTabsStyle.defaultActiveIndicatorRadius,
        const CoreBorderRadius.all(CoreRadius.radius6),
      );
      expect(CoreTabsStyle.defaultTabSpacing, 0);
    });

    test('label ↔ badge spacer is 6', () {
      expect(CoreTabsStyle.defaultLabelBadgeGapStyle.size, CoreSpace.space6);
      expect(CoreTabsStyle.defaultLabelBadgeGapStyle.size, 6);
    });

    test('the pill row leaves the rung ladder as the label role', () {
      // The ladder rows keep their role, so a variant that states none
      // (pill) reads 13 / 14 / 15 from them.
      expect(
        CoreTabsStyle.defaultsBySize[CoreTabsSize.sm]!.contentTextStyle!.token,
        CoreTextStyles.labelMedium,
      );
    });
  });

  // Exhaustiveness net (#3773 philosophy): catches a `CoreTabsSize`
  // member added without a matching `defaultsBySize` entry, before any
  // `!` ever gets a chance to throw at runtime. Narrowed from the
  // 6-step `CoreComponentSize` ladder to `CoreTabsSize` (sm/md/lg) by
  // the 2026-09-14 redesign — `xs`/`xl`/`xl2` had 0 live instances.
  group('CoreTabsStyle.defaultsBySize', () {
    test('covers every CoreTabsSize member', () {
      for (final size in CoreTabsSize.values) {
        expect(
          CoreTabsStyle.defaultsBySize[size],
          isNotNull,
          reason:
              'missing size chrome for CoreTabsSize.${size.name} — '
              'every `defaultsBySize[size]!` lookup in the resolvers '
              'assumes full coverage and would crash at runtime',
        );
      }
    });

    test('has exactly one entry per CoreTabsSize member', () {
      // Guards the other direction: a stale entry left behind after a
      // member is removed from CoreTabsSize.
      expect(CoreTabsStyle.defaultsBySize.length, CoreTabsSize.values.length);
    });

    test('the rungs are the control ladder: 32 / 40 / 48', () {
      expect(CoreTabsStyle.defaultsBySize[CoreTabsSize.sm]!.itemHeight, 32);
      expect(CoreTabsStyle.defaultsBySize[CoreTabsSize.md]!.itemHeight, 40);
      expect(CoreTabsStyle.defaultsBySize[CoreTabsSize.lg]!.itemHeight, 48);
    });

    test('each variant row states whether the rung is the track: pill yes, '
        'underline no', () {
      expect(
        CoreTabsStyle.defaultsByVariant[CoreTabVariant.pill]!.sizeRungIsTrack,
        isTrue,
      );
      expect(
        CoreTabsStyle
            .defaultsByVariant[CoreTabVariant.underline]!
            .sizeRungIsTrack,
        isFalse,
      );
    });

    test('tabHeight takes the track inset out of the rung when the rung is '
        'the track, and leaves it alone otherwise', () {
      expect(
        CoreTabsStyle.tabHeight(
          rung: 40,
          trackInset: 4,
          sizeRungIsTrack: true,
        ),
        36,
      );
      expect(
        CoreTabsStyle.tabHeight(
          rung: 40,
          trackInset: 4,
          sizeRungIsTrack: false,
        ),
        40,
      );
      // An inset taller than the rung leaves no tab, never a negative one.
      expect(
        CoreTabsStyle.tabHeight(
          rung: 4,
          trackInset: 10,
          sizeRungIsTrack: true,
        ),
        0,
      );
    });

    test('the stated rows land on 28 / 36 / 44 pill tabs and 32 / 40 / 48 '
        'underline tabs', () {
      double heightOf(CoreTabVariant variant, CoreTabsSize size) {
        final row = CoreTabsStyle.defaultsByVariant[variant]!;
        return CoreTabsStyle.tabHeight(
          rung: CoreTabsStyle.defaultsBySize[size]!.itemHeight!,
          trackInset: row.tabBarPadding.top + row.tabBarPadding.bottom,
          sizeRungIsTrack: row.sizeRungIsTrack,
        );
      }

      expect(
        {
          for (final size in CoreTabsSize.values)
            size: heightOf(CoreTabVariant.pill, size),
        },
        {
          CoreTabsSize.sm: 28,
          CoreTabsSize.md: 36,
          CoreTabsSize.lg: 44,
        },
      );
      expect(
        {
          for (final size in CoreTabsSize.values)
            size: heightOf(CoreTabVariant.underline, size),
        },
        {
          CoreTabsSize.sm: 32,
          CoreTabsSize.md: 40,
          CoreTabsSize.lg: 48,
        },
      );
    });

    test('the variant row is a value: the flag takes part in ==, hashCode and '
        'copyWith', () {
      final pill = CoreTabsStyle.defaultsByVariant[CoreTabVariant.pill]!;
      final flipped = pill.copyWith(sizeRungIsTrack: false);
      expect(flipped.sizeRungIsTrack, isFalse);
      expect(flipped, isNot(pill));
      expect(flipped.hashCode, isNot(pill.hashCode));
      expect(pill.copyWith(), pill);
      expect(pill.copyWith().hashCode, pill.hashCode);
      // Everything else is carried over untouched.
      expect(flipped.copyWith(sizeRungIsTrack: true), pill);
    });

    test('label typography is per-size — one label role per rung, '
        'sm labelMedium, md labelLarge, lg labelXl', () {
      const sizes = CoreTabsStyle.defaultsBySize;
      final sm = sizes[CoreTabsSize.sm]!.contentTextStyle!;
      final md = sizes[CoreTabsSize.md]!.contentTextStyle!;
      final lg = sizes[CoreTabsSize.lg]!.contentTextStyle!;
      expect(sm.token, CoreTextStyles.labelMedium);
      expect(md.token, CoreTextStyles.labelLarge);
      expect(lg.token, CoreTextStyles.labelXl);
      // The rows state the role only, so each draws at the label role's
      // own weight (500) — no weight overlay on any rung.
      for (final style in [sm, md, lg]) {
        expect(style.fontWeight, isNull);
        expect(
          style.token!.read(CoreTypography.coui).fontWeight,
          CoreFontWeight.medium,
        );
      }
      // The unsized default is the `md` rung.
      expect(md, CoreTabsStyle.defaultContentTextStyle);
    });

    test(
      'itemHeight instance override wins over the size-keyed default',
      () {
        const merged = CoreTabsStyle(itemHeight: 100);
        expect(merged.itemHeight, 100);
      },
    );
  });

  group('CoreTabVariant', () {
    test('defaultVariant is pill', () {
      expect(CoreTabVariant.defaultVariant, CoreTabVariant.pill);
    });
  });

  group('CoreTabsTheme', () {
    test('passes through style + variantStyles', () {
      const style = CoreTabsStyle(
        activeIndicatorColor: _kColorPrimary,
      );
      const variantStyle = CoreTabsStyle(tabSpacing: 4);
      const theme = CoreTabsTheme(
        style: style,
        variantStyles: {
          .pill: variantStyle,
          .underline: variantStyle,
        },
      );
      expect(theme.style, style);
      expect(theme.variantStyles?[CoreTabVariant.underline], variantStyle);
    });

    test('equality', () {
      const a = CoreTabsTheme(
        style: CoreTabsStyle(tabSpacing: 8),
      );
      const b = CoreTabsTheme(
        style: CoreTabsStyle(tabSpacing: 8),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CoreTabPaneStyle', () {
    test('merge — non-null fields win', () {
      const base = CoreTabPaneStyle(
        backgroundColor: _kColorSurface,
        barHeight: 32,
      );
      const override = CoreTabPaneStyle(barHeight: 40);
      final merged = base.merge(override);
      expect(merged.backgroundColor, _kColorSurface);
      expect(merged.barHeight, 40);
    });

    test('contentTextStyle merges recursively', () {
      const a = CoreTabPaneStyle(
        contentTextStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      const b = CoreTabPaneStyle(
        contentTextStyle: CoreTextStyle(fontSize: _kFontTitle),
      );
      final merged = a.merge(b);
      expect(merged.contentTextStyle?.fontSize, _kFontTitle);
    });

    test('equality + copyWith', () {
      const a = CoreTabPaneStyle(borderWidth: 1, barHeight: 32);
      const b = CoreTabPaneStyle(borderWidth: 1, barHeight: 32);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      final copy = a.copyWith(barHeight: 40);
      expect(copy.borderWidth, 1);
      expect(copy.barHeight, 40);
    });

    test('dragOpacity override field', () {
      const base = CoreTabPaneStyle(dragOpacity: 0.5);
      const override = CoreTabPaneStyle(dragOpacity: 0.8);
      final merged = base.merge(override);
      expect(merged.dragOpacity, 0.8);
      final copy = base.copyWith(dragOpacity: 0.2);
      expect(copy.dragOpacity, 0.2);
    });
  });

  group('CoreTabPaneTheme', () {
    test('passes through style', () {
      const style = CoreTabPaneStyle(backgroundColor: _kColorSurface);
      const theme = CoreTabPaneTheme(style: style);
      expect(theme.style, style);
    });

    test('passes through variantStyles', () {
      const theme = CoreTabPaneTheme(
        variantStyles: {
          CoreTabPaneVariant.editorStrip: CoreTabPaneStyle(tabSpacing: 4),
        },
      );
      expect(
        theme.variantStyles?[CoreTabPaneVariant.editorStrip]?.tabSpacing,
        4,
      );
    });
  });

  group('CoreTabPaneStyle.editorStrip', () {
    test('preset uses existing fields for IDE chrome', () {
      const preset = CoreTabPaneStyle.editorStrip;
      expect(preset.tabSpacing, 0);
      expect(preset.borderRadius, CoreBorderRadius.zero);
      expect(
        preset.tabSeparatorColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(
        preset.stripBackgroundColor,
        const CoreColor.token(CoreColors.surfaceContainerLow),
      );
      expect(
        CoreTabPaneStyle.defaultsByVariant[CoreTabPaneVariant.editorStrip],
        preset,
      );
      expect(
        CoreTabPaneStyle.defaultsByVariant[CoreTabPaneVariant.boxed],
        CoreTabPaneStyle.boxed,
      );
    });

    test('the strip is 36 px tall; the boxed bar is 44', () {
      expect(CoreTabPaneStyle.editorStrip.barHeight, CoreSize.size36);
      expect(CoreTabPaneStyle.editorStrip.barHeight, 36);
      expect(CoreTabPaneStyle.boxed.barHeight, CoreSize.size44);
      expect(CoreTabPaneStyle.defaultBarHeight, CoreSize.size32);
    });

    test('the chip padding is directional start 12 / end 8, no vertical', () {
      final padding = CoreTabPaneStyle.editorStrip.tabPadding!;
      expect(
        padding,
        const CoreEdgeInsets.directional(
          start: CoreSpace.space12,
          end: CoreSpace.space8,
        ),
      );
      // Reading-order statement, not left / right (cross-platform/
      // localization.md): flattening it would be wrong in a right-to-left
      // locale with nothing to see.
      expect(padding.isDirectional, isTrue);
      expect(padding.start, 12);
      expect(padding.end, 8);
      expect(padding.top, 0);
      expect(padding.bottom, 0);
      // The boxed default is the symmetric one it always was.
      expect(CoreTabPaneStyle.defaultTabPadding.isDirectional, isFalse);
    });

    test('the label is the codeSm role', () {
      expect(
        CoreTabPaneStyle.editorStrip.contentTextStyle,
        const CoreTextStyle.token(CoreTextStyles.codeSm),
      );
      expect(
        CoreTabPaneStyle.defaultContentTextStyle,
        const CoreTextStyle.token(CoreTextStyles.bodyMedium),
      );
      // The boxed label is labelLarge (Medium 14).
      expect(
        CoreTabPaneStyle.boxed.contentTextStyle,
        const CoreTextStyle.token(CoreTextStyles.labelLarge),
      );
      // The row's role replaces the default's; it is not stacked on it.
      expect(
        CoreTabPaneStyle.defaultContentTextStyle
            .merge(CoreTabPaneStyle.editorStrip.contentTextStyle)
            .token,
        CoreTextStyles.codeSm,
      );
    });

    test('borderWidth is the bottom line thickness; borderColor is its '
        'colour, outlineVariant', () {
      expect(CoreTabPaneStyle.editorStrip.borderWidth, CoreStrokeWidth.stroke1);
      expect(
        CoreTabPaneStyle.editorStrip.borderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      // The boxed row states the same hairline: the bar's bottom line and the
      // card's edge are one outlineVariant rule, at the default width.
      expect(
        CoreTabPaneStyle.boxed.borderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(CoreTabPaneStyle.boxed.borderWidth, isNull);
      expect(
        CoreTabPaneStyle.boxed.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius12),
      );
    });

    test('a rule between tabs: the separator is outlineVariant at the '
        'default width', () {
      const preset = CoreTabPaneStyle.editorStrip;
      expect(
        preset.tabSeparatorColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      // A width is only consulted once a colour is stated, so the row keeps
      // none; the default (stroke1) applies.
      expect(preset.tabSeparatorWidth, isNull);
      expect(preset.tabSpacing, 0);
      expect(
        CoreTabPaneStyle.defaultTabSeparatorColor,
        CoreColor.transparent,
      );
    });

    test('the tab focus ring sits inside the tab box and keeps the system '
        'ring colour and width', () {
      final ring =
          CoreTabPaneStyle.editorStrip.clickableStyle!.focusOutlineStyle!;
      // `align` is the ring's outer edge measured from the box edge: 0 puts
      // the ring flush inside; the Clickable's default puts it outside.
      expect(ring.align, 0);
      expect(ring.align, lessThan(CoreFocusOutlineStyle.defaultAlign));
      expect(ring.borderColor, isNull);
      expect(ring.borderWidth, isNull);
      expect(ring.offsetColor, isNull);
      // Resolved over the Clickable's own default, the colour is the system
      // focus ring and the width the system 2.
      final resolved = CoreClickableStyle.defaultFocusOutlineStyle.merge(ring);
      expect(resolved.borderColor, CoreFocusOutlineStyle.defaultBorderColor);
      expect(resolved.borderWidth, CoreFocusOutlineStyle.defaultBorderWidth);
      expect(resolved.align, 0);
      // Boxed keeps the default ring.
      expect(
        CoreTabPaneStyle
            .defaultsByVariant[CoreTabPaneVariant.boxed]!
            .clickableStyle,
        isNull,
      );
    });

    test('merging a style over the row keeps the row for fields it omits', () {
      final merged = CoreTabPaneStyle.editorStrip.merge(
        const CoreTabPaneStyle(
          borderColor: CoreColor.token(CoreColors.primary),
        ),
      );
      expect(merged.borderColor, const CoreColor.token(CoreColors.primary));
      expect(merged.barHeight, 36);
      expect(merged.borderWidth, CoreStrokeWidth.stroke1);
      expect(merged.tabPadding, CoreTabPaneStyle.editorStrip.tabPadding);
    });

    test('the selected-tab indicator is primary at stroke2 on both rows; the '
        'boxed bar rounds its top corners', () {
      expect(
        CoreTabPaneStyle.editorStrip.indicatorColor,
        const CoreColor.token(CoreColors.primary),
      );
      // The width is not stated on the row: it follows the default.
      expect(CoreTabPaneStyle.editorStrip.indicatorWidth, isNull);
      expect(CoreTabPaneStyle.defaultIndicatorWidth, CoreStrokeWidth.stroke2);
      expect(CoreTabPaneStyle.defaultIndicatorColor, CoreColor.transparent);
      expect(
        CoreTabPaneStyle.boxed.indicatorColor,
        const CoreColor.token(CoreColors.primary),
      );
      expect(CoreTabPaneStyle.boxed.indicatorWidth, isNull);
      // The editor strip's bar is flat; the boxed one rounds its two top
      // corners (the corners away from the bar's bottom line).
      expect(CoreTabPaneStyle.editorStrip.indicatorBorderRadius, isNull);
      expect(
        CoreTabPaneStyle.defaultIndicatorBorderRadius,
        CoreBorderRadius.zero,
      );
      expect(
        CoreTabPaneStyle.boxed.indicatorBorderRadius,
        const CoreBorderRadius.only(
          topLeft: CoreRadius.radius2,
          topRight: CoreRadius.radius2,
        ),
      );
      // The boxed focused tab states no outline: the indicator marks it.
      expect(CoreTabPaneStyle.boxed.tabBorderColor, CoreColor.transparent);
    });

    test('the boxed bar insets its tabs 16 each side; the strip is flush', () {
      expect(
        CoreTabPaneStyle.boxed.barPadding,
        const CoreEdgeInsets.symmetric(horizontal: CoreSpace.space16),
      );
      expect(CoreTabPaneStyle.editorStrip.barPadding, isNull);
      expect(CoreTabPaneStyle.defaultBarPadding, CoreEdgeInsets.zero);
    });

    test('the close box is 20x20, no padding, radius 4; the glyph is 12 in '
        'onSurfaceSubtle', () {
      const box = CoreTabPaneStyle.editorStripCloseButtonStyle;
      expect(box.width, CoreSize.size20);
      expect(box.height, CoreSize.size20);
      expect(box.padding, CoreEdgeInsets.zero);
      expect(box.borderRadius, const CoreBorderRadius.all(CoreRadius.radius4));
      const glyph = CoreTabPaneStyle.editorStripCloseIconStyle;
      expect(glyph.size, CoreIconSize.size12);
      expect(glyph.color, const CoreColor.token(CoreColors.onSurfaceSubtle));

      // The row states them; the variant-free default stays an empty
      // partial so the boxed close Button keeps its own row.
      expect(CoreTabPaneStyle.editorStrip.closeButtonStyle, box);
      expect(CoreTabPaneStyle.editorStrip.closeIconStyle, glyph);
      expect(CoreTabPaneStyle.defaultCloseButtonStyle, const CoreButtonStyle());
      expect(CoreTabPaneStyle.defaultCloseIconStyle, const CoreIconStyle());
      // The boxed glyph states no colour: it follows its ghost button
      // (the colour is the editorStrip row's alone).
      expect(CoreTabPaneStyle.defaultCloseIconStyle.color, isNull);
      expect(
        CoreTabPaneStyle
            .defaultsByVariant[CoreTabPaneVariant.boxed]!
            .closeButtonStyle,
        isNull,
      );
      expect(
        CoreTabPaneStyle
            .defaultsByVariant[CoreTabPaneVariant.boxed]!
            .closeIconStyle,
        isNull,
      );
    });

    test('the close slots merge recursively: a colour keeps the row size', () {
      final merged = CoreTabPaneStyle.editorStrip.merge(
        const CoreTabPaneStyle(
          closeIconStyle: CoreIconStyle(
            color: CoreColor.token(CoreColors.primary),
          ),
          closeButtonStyle: CoreButtonStyle(width: 28),
        ),
      );
      expect(merged.closeIconStyle?.size, CoreIconSize.size12);
      expect(
        merged.closeIconStyle?.color,
        const CoreColor.token(CoreColors.primary),
      );
      expect(merged.closeButtonStyle?.width, 28);
      expect(merged.closeButtonStyle?.height, CoreSize.size20);
      expect(merged.closeButtonStyle?.padding, CoreEdgeInsets.zero);
    });

    test('indicator and close fields count in ==, hashCode and copyWith', () {
      const base = CoreTabPaneStyle();
      final variants = <CoreTabPaneStyle>[
        base.copyWith(indicatorColor: CoreColor.transparent),
        base.copyWith(indicatorWidth: 3),
        base.copyWith(closeButtonStyle: const CoreButtonStyle(width: 20)),
        base.copyWith(closeIconStyle: const CoreIconStyle(size: 10)),
      ];
      for (final v in variants) {
        expect(v, isNot(equals(base)));
        expect(v.hashCode, isNot(base.hashCode));
        expect(
          v,
          equals(
            CoreTabPaneStyle(
              indicatorColor: v.indicatorColor,
              indicatorWidth: v.indicatorWidth,
              closeButtonStyle: v.closeButtonStyle,
              closeIconStyle: v.closeIconStyle,
            ),
          ),
        );
      }
      // `merge` carries them too.
      expect(base.merge(variants[1]).indicatorWidth, 3);
      expect(base.merge(variants[0]).indicatorColor, CoreColor.transparent);
    });
  });
}
