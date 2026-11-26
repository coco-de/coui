// Tests for CoreRadioGroupStyle (Epic #1302 — Story #1308 Radio).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const double _kSizeSm = 16;
const double _kSizeMd = 20;
const double _kBorderThin = 1;
const double _kBorderThick = 2;
const double _kGapSm = 4;
const double _kGapLg = 8;
const double _kItemGap = 12;
const CoreGapStyle _kGapSmStyle = CoreGapStyle(size: _kGapSm);
const CoreGapStyle _kGapLgStyle = CoreGapStyle(size: _kGapLg);

const _kBgSurface = CoreColor.token(CoreColors.surface);
const _kActivePrimary = CoreColor.token(CoreColors.primary);
const _kActiveSuccess = CoreColor.token(CoreColors.success);
const _kBorderOutline = CoreColor.token(CoreColors.outline);
const _kBgPrimaryClr = CoreColor.token(CoreColors.primary);
const _kActiveSuccessClr = CoreColor.token(CoreColors.success);
const _kBorderOutlineClr = CoreColor.token(CoreColors.outline);
const _kBorderErrorClr = CoreColor.token(CoreColors.error);

const double _kDotSm = 6;
const double _kDotMd = 8;
const double _kFontBody = 14;
const int _kWeightRegular = CoreFontWeight.regular;
const int _kWeightSemiBold = CoreFontWeight.semiBold;

void main() {
  test('selected card padding preserves opt-in through merge and copy', () {
    const padding = CoreEdgeInsets.symmetric(horizontal: 16, vertical: 14);
    const base = CoreRadioGroupStyle(tileSelectedPadding: padding);
    expect(const CoreRadioGroupStyle().tileSelectedPadding, isNull);
    expect(
      base.merge(const CoreRadioGroupStyle()).tileSelectedPadding,
      padding,
    );
    expect(const CoreRadioGroupStyle().merge(base), base);
    expect(base.copyWith(), base);
    expect(
      base.copyWith(tileSelectedPadding: CoreEdgeInsets.zero),
      isNot(equals(base)),
    );
    expect(base.copyWith().hashCode, base.hashCode);
  });
  group('CoreRadioGroupStyle.merge', () {
    test('null other returns this', () {
      const a = CoreRadioGroupStyle(
        indicatorBackgroundColor: _kBgSurface,
        indicatorSize: _kSizeMd,
      );
      expect(identical(a.merge(null), a), isTrue);
    });

    test('chain — design system → theme.style → variantStyles → widget', () {
      const designSystem = CoreRadioGroupStyle(
        indicatorBackgroundColor: _kBgSurface,
        indicatorBorderColor: _kBorderOutline,
        indicatorBorderWidth: _kBorderThin,
        indicatorSize: _kSizeMd,
        indicatorLabelGapStyle: _kGapLgStyle,
        itemSpacing: _kItemGap,
      );
      const themeStyle = CoreRadioGroupStyle(
        indicatorBorderWidth: _kBorderThick,
      );
      const variantStyle = CoreRadioGroupStyle(
        indicatorActiveColor: _kActivePrimary,
      );
      const widgetStyle = CoreRadioGroupStyle(
        indicatorLabelGapStyle: _kGapSmStyle,
      );

      final effective = designSystem
          .merge(themeStyle)
          .merge(variantStyle)
          .merge(widgetStyle);

      expect(effective.indicatorBackgroundColor, _kBgSurface);
      expect(effective.indicatorBorderColor, _kBorderOutline);
      expect(effective.indicatorBorderWidth, _kBorderThick); // theme override
      expect(effective.indicatorSize, _kSizeMd);
      expect(
        effective.indicatorActiveColor,
        _kActivePrimary,
      ); // variant override
      // widget override
      expect(effective.indicatorLabelGapStyle?.size, _kGapSm);
      expect(effective.itemSpacing, _kItemGap);
    });

    test('right-most non-null wins on each field', () {
      const a = CoreRadioGroupStyle(
        indicatorBorderWidth: _kBorderThin,
        indicatorSize: _kSizeSm,
      );
      const b = CoreRadioGroupStyle(indicatorSize: _kSizeMd);
      const c = CoreRadioGroupStyle(indicatorBorderWidth: _kBorderThick);

      final result = a.merge(b).merge(c);

      expect(result.indicatorSize, _kSizeMd);
      expect(result.indicatorBorderWidth, _kBorderThick);
    });

    test('indicatorDotStyle merges recursively', () {
      const base = CoreRadioGroupStyle(
        indicatorDotStyle: CoreIconStyle(
          size: _kDotMd,
          color: _kBgPrimaryClr,
        ),
      );
      const override = CoreRadioGroupStyle(
        indicatorDotStyle: CoreIconStyle(color: _kBorderErrorClr),
      );
      final merged = base.merge(override);
      expect(merged.indicatorDotStyle?.size, _kDotMd);
      expect(merged.indicatorDotStyle?.color, _kBorderErrorClr);
    });

    test('labelStyle merges recursively (subset override)', () {
      const base = CoreRadioGroupStyle(
        labelStyle: CoreTextStyle(
          fontSize: _kFontBody,
          fontWeight: _kWeightRegular,
          color: _kBorderOutlineClr,
        ),
      );
      const override = CoreRadioGroupStyle(
        labelStyle: CoreTextStyle(fontWeight: _kWeightSemiBold),
      );
      final merged = base.merge(override);
      expect(merged.labelStyle?.fontSize, _kFontBody);
      expect(merged.labelStyle?.fontWeight, _kWeightSemiBold);
      expect(merged.labelStyle?.color, _kBorderOutlineClr);
    });

    test('null nested style on base inherits from override', () {
      const base = CoreRadioGroupStyle();
      const override = CoreRadioGroupStyle(
        indicatorDotStyle: CoreIconStyle(
          size: _kDotSm,
          color: _kActiveSuccessClr,
        ),
      );
      final merged = base.merge(override);
      expect(merged.indicatorDotStyle?.size, _kDotSm);
      expect(merged.indicatorDotStyle?.color, _kActiveSuccessClr);
    });
  });

  group('CoreRadioGroupStyle equality', () {
    test('same fields → equal', () {
      const a = CoreRadioGroupStyle(
        indicatorActiveColor: _kActivePrimary,
        indicatorSize: _kSizeMd,
        indicatorLabelGapStyle: _kGapSmStyle,
      );
      const b = CoreRadioGroupStyle(
        indicatorActiveColor: _kActivePrimary,
        indicatorSize: _kSizeMd,
        indicatorLabelGapStyle: _kGapSmStyle,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different indicatorActiveColor → not equal', () {
      const a = CoreRadioGroupStyle(indicatorActiveColor: _kActivePrimary);
      const b = CoreRadioGroupStyle(indicatorActiveColor: _kActiveSuccess);
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreRadioGroupStyle.copyWith', () {
    test('only-supplied fields override', () {
      const base = CoreRadioGroupStyle(
        indicatorBorderColor: _kBorderOutline,
        indicatorSize: _kSizeMd,
        indicatorLabelGapStyle: _kGapLgStyle,
      );
      final copy = base.copyWith(indicatorSize: _kSizeSm);
      expect(copy.indicatorSize, _kSizeSm);
      expect(copy.indicatorBorderColor, _kBorderOutline);
      expect(copy.indicatorLabelGapStyle?.size, _kGapLg);
    });

    test('preserves nested styles when not specified', () {
      const base = CoreRadioGroupStyle(
        indicatorDotStyle: CoreIconStyle(size: _kDotMd),
        labelStyle: CoreTextStyle(fontSize: _kFontBody),
      );
      final copy = base.copyWith(indicatorActiveColor: _kActiveSuccess);
      expect(copy.indicatorActiveColor, _kActiveSuccess);
      expect(copy.labelStyle?.fontSize, _kFontBody);
      expect(copy.indicatorDotStyle?.size, _kDotMd);
    });
  });

  group('CoreRadioGroupTheme', () {
    test('style + variantStyles pass through', () {
      const style = CoreRadioGroupStyle(indicatorLabelGapStyle: _kGapLgStyle);
      const variantStyle = CoreRadioGroupStyle(
        indicatorActiveColor: _kActivePrimary,
      );
      const theme = CoreRadioGroupTheme(
        style: style,
        variantStyles: {
          .defaultVariant: variantStyle,
        },
      );
      expect(theme.style, style);
      expect(
        theme.variantStyles![CoreRadioGroupVariant.defaultVariant],
        variantStyle,
      );
    });

    test('null fields', () {
      const theme = CoreRadioGroupTheme();
      expect(theme.style, isNull);
      expect(theme.variantStyles, isNull);
    });

    test('equality', () {
      const a = CoreRadioGroupTheme(
        style: CoreRadioGroupStyle(indicatorLabelGapStyle: _kGapLgStyle),
        variantStyles: {
          .defaultVariant: CoreRadioGroupStyle(
            indicatorActiveColor: _kActivePrimary,
          ),
        },
      );
      const b = CoreRadioGroupTheme(
        style: CoreRadioGroupStyle(indicatorLabelGapStyle: _kGapLgStyle),
        variantStyles: {
          .defaultVariant: CoreRadioGroupStyle(
            indicatorActiveColor: _kActivePrimary,
          ),
        },
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  // The redesign's ladders and tokens, read back off the single source both
  // platforms and the Figma builder consume. A row that drifts (a ring that
  // does not leave the hole it should, a stroke that steps at the wrong
  // tier, a label that stays 14 while the ring grows) fails here before it
  // reaches a pixel on either platform.
  group('CoreRadioGroupStyle redesign defaults', () {
    // No dot by default: the selected ring carries the selection.
    const dotBySize = {
      CoreComponentSize.xs: CoreSpace.space0,
      CoreComponentSize.sm: CoreSpace.space0,
      CoreComponentSize.md: CoreSpace.space0,
      CoreComponentSize.lg: CoreSpace.space0,
      CoreComponentSize.xl: CoreSpace.space0,
      CoreComponentSize.xl2: CoreSpace.space0,
    };
    // The resting ring: the active boundary through `lg`, 2 from `xl`.
    const strokeBySize = {
      CoreComponentSize.xs: CoreStrokeWidth.stroke1,
      CoreComponentSize.sm: CoreStrokeWidth.stroke1,
      CoreComponentSize.md: CoreStrokeWidth.stroke1,
      CoreComponentSize.lg: CoreStrokeWidth.stroke1,
      CoreComponentSize.xl: CoreStrokeWidth.stroke1,
      CoreComponentSize.xl2: CoreStrokeWidth.stroke1,
    };
    // The selected ring: every row states one.
    const selectedStrokeBySize = <CoreComponentSize, double?>{
      CoreComponentSize.xs: CoreStrokeWidth.stroke3,
      CoreComponentSize.sm: CoreStrokeWidth.stroke4,
      CoreComponentSize.md: CoreStrokeWidth.stroke4,
      CoreComponentSize.lg: CoreStrokeWidth.stroke5,
      CoreComponentSize.xl: CoreStrokeWidth.stroke5,
      CoreComponentSize.xl2: CoreStrokeWidth.stroke6,
    };
    // The hole a selected ring leaves open: `indicatorSize − 2 × selected`.
    const holeBySize = <CoreComponentSize, double>{
      CoreComponentSize.xs: 6,
      CoreComponentSize.sm: 6,
      CoreComponentSize.md: 8,
      CoreComponentSize.lg: 8,
      CoreComponentSize.xl: 10,
      CoreComponentSize.xl2: 12,
    };
    const gapBySize = {
      CoreComponentSize.xs: CoreSpace.space6,
      CoreComponentSize.sm: CoreSpace.space8,
      CoreComponentSize.md: CoreSpace.space8,
      CoreComponentSize.lg: CoreSpace.space8,
      CoreComponentSize.xl: CoreSpace.space10,
      CoreComponentSize.xl2: CoreSpace.space12,
    };
    const labelSizeBySize = {
      CoreComponentSize.xs: CoreFontSize.s12,
      CoreComponentSize.sm: CoreFontSize.s13,
      CoreComponentSize.md: CoreFontSize.s14,
      CoreComponentSize.lg: CoreFontSize.s16,
      CoreComponentSize.xl: CoreFontSize.s16,
      CoreComponentSize.xl2: CoreFontSize.s16,
    };

    test('dot / stroke / gap / label ladders per size', () {
      for (final size in CoreComponentSize.values) {
        final row = CoreRadioGroupStyle.defaultsBySize[size]!;
        expect(row.innerDotSize, dotBySize[size], reason: '${size.name} dot');
        expect(
          row.indicatorBorderWidth,
          strokeBySize[size],
          reason: '${size.name} stroke',
        );
        expect(
          row.selectedIndicatorBorderWidth,
          selectedStrokeBySize[size],
          reason: '${size.name} selected stroke',
        );
        expect(
          row.indicatorLabelGapStyle?.size,
          gapBySize[size],
          reason: '${size.name} gap',
        );
        expect(
          row.labelStyle?.fontSize,
          labelSizeBySize[size],
          reason: '${size.name} label fontSize',
        );
        // The ladder is Button's, so a radio and the button beside it read
        // at one size — read Button's role back to compare as numbers.
        expect(
          row.labelStyle?.fontSize,
          CoreButtonStyle.defaultsBySize[size]!.labelStyle!.token!
              .read(CoreTypography.coui)
              .fontSize,
          reason: "${size.name} label drifted from Button's",
        );
        // The size row carries only the step — role and colour stay on the
        // field, so the merge in the resolvers keeps both.
        expect(row.labelStyle?.token, isNull);
        expect(row.labelStyle?.color, isNull);
      }
    });

    test('a selected ring leaves a hole of 6 / 6 / 8 / 8 / 10 / 12', () {
      // `indicatorSize − 2 × selectedIndicatorBorderWidth` — the stroke is
      // drawn inside the box on both platforms, so the hole is what is left.
      // Every size is held — a row that states no selected ring is not
      // skipped over.
      expect(holeBySize.keys, unorderedEquals(CoreComponentSize.values));
      for (final entry in holeBySize.entries) {
        final row = CoreRadioGroupStyle.defaultsBySize[entry.key]!;
        expect(
          row.indicatorSize! - 2 * row.selectedIndicatorBorderWidth!,
          entry.value,
          reason: '${entry.key.name} hole',
        );
        // The selection must read as a thicker ring than the resting one.
        expect(
          row.selectedIndicatorBorderWidth,
          greaterThan(row.indicatorBorderWidth!),
          reason: '${entry.key.name} selected ring is not heavier than rest',
        );
      }
    });

    test('every stated selected width is a step the stroke ladder has', () {
      const ladder = <double>[
        CoreStrokeWidth.stroke0,
        CoreStrokeWidth.stroke0_5,
        CoreStrokeWidth.stroke1,
        CoreStrokeWidth.stroke1_5,
        CoreStrokeWidth.stroke2,
        CoreStrokeWidth.stroke3,
        CoreStrokeWidth.stroke4,
        CoreStrokeWidth.stroke5,
        CoreStrokeWidth.stroke6,
        CoreStrokeWidth.stroke8,
      ];
      for (final row in CoreRadioGroupStyle.defaultsBySize.values) {
        final selected = row.selectedIndicatorBorderWidth;
        if (selected != null) expect(ladder, contains(selected));
      }
    });

    test('selected ring width rides merge / copyWith / ==', () {
      const base = CoreRadioGroupStyle(
        indicatorBorderWidth: CoreStrokeWidth.stroke2,
      );
      const over = CoreRadioGroupStyle(
        selectedIndicatorBorderWidth: CoreStrokeWidth.stroke6,
      );
      final merged = base.merge(over);
      // Independent of the resting width: restating one leaves the other.
      expect(merged.indicatorBorderWidth, CoreStrokeWidth.stroke2);
      expect(merged.selectedIndicatorBorderWidth, CoreStrokeWidth.stroke6);
      expect(
        over.merge(base).selectedIndicatorBorderWidth,
        CoreStrokeWidth.stroke6,
        reason:
            'a later layer that states only the resting width must not '
            'clear the selected one',
      );
      final copy = merged.copyWith(
        selectedIndicatorBorderWidth: CoreStrokeWidth.stroke3,
      );
      expect(copy.selectedIndicatorBorderWidth, CoreStrokeWidth.stroke3);
      expect(copy.indicatorBorderWidth, CoreStrokeWidth.stroke2);
      expect(merged, equals(base.merge(over)));
      expect(merged.hashCode, base.merge(over).hashCode);
      expect(
        merged,
        isNot(equals(merged.copyWith(selectedIndicatorBorderWidth: 8))),
      );
      expect(
        const CoreRadioGroupStyle(selectedIndicatorBorderWidth: 3).hashCode,
        isNot(
          const CoreRadioGroupStyle(selectedIndicatorBorderWidth: 4).hashCode,
        ),
      );
    });

    test('label role is regular-weight body prose, on-surface', () {
      expect(
        CoreRadioGroupStyle.defaultLabelStyle.token,
        CoreTextStyles.bodySmall,
      );
      expect(
        CoreRadioGroupStyle.defaultLabelStyle.color,
        const CoreColor.token(CoreColors.onSurface),
      );
    });

    test('resting ring is outline on no fill; disabled is the '
        'disabled trio, so a restated dot stays visible when disabled', () {
      final vs = CoreRadioGroupStyle
          .defaultsByVariant[CoreRadioGroupVariant.defaultVariant]!;
      expect(vs.borderColor, const CoreColor.token(CoreColors.outline));
      expect(vs.uncheckedBackground, CoreColor.transparent);
      expect(vs.activeColor, const CoreColor.token(CoreColors.primary));
      expect(
        vs.disabledBackgroundColor,
        const CoreColor.token(CoreColors.disabledContainer),
      );
      expect(
        vs.disabledBorderColor,
        const CoreColor.token(CoreColors.disabledOutline),
      );
      expect(
        vs.disabledActiveColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
      expect(
        vs.disabledForegroundColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
      // A dot restated on a disabled radio must not vanish into the fill it
      // sits on.
      expect(vs.disabledActiveColor, isNot(vs.disabledBackgroundColor));
    });

    test('state layer defaults — standard ramp, on-surface ink, +4 halo', () {
      expect(CoreRadioGroupStyle.defaultStateLayer, CoreStateLayer.standard);
      expect(CoreRadioGroupStyle.defaultStateLayer.hover, CoreOpacity.opacity8);
      expect(
        CoreRadioGroupStyle.defaultStateLayer.pressed,
        CoreOpacity.opacity16,
      );
      expect(
        CoreRadioGroupStyle.defaultStateLayerColor,
        const CoreColor.token(CoreColors.onSurface),
      );
      expect(CoreRadioGroupStyle.defaultStateLayerSpread, CoreSpace.space4);
    });

    test('state layer fields ride merge / copyWith / ==', () {
      const base = CoreRadioGroupStyle(stateLayerSpread: CoreSpace.space2);
      const over = CoreRadioGroupStyle(
        stateLayer: CoreStateLayer.subtle,
        stateLayerColor: _kActivePrimary,
      );
      final merged = base.merge(over);
      expect(merged.stateLayer, CoreStateLayer.subtle);
      expect(merged.stateLayerColor, _kActivePrimary);
      expect(merged.stateLayerSpread, CoreSpace.space2);
      final copy = merged.copyWith(stateLayerSpread: CoreSpace.space6);
      expect(copy.stateLayerSpread, CoreSpace.space6);
      expect(copy.stateLayer, CoreStateLayer.subtle);
      expect(
        merged,
        isNot(equals(merged.copyWith(stateLayer: CoreStateLayer.strong))),
      );
      expect(merged, equals(base.merge(over)));
    });
  });

  // #3773 — `defaultsBySize[size]!` is a Map lookup, not a `switch`, so
  // Dart's exhaustiveness checker never sees it. This group is the net
  // — it fails the moment a member is added without a matching entry,
  // before any `!` ever gets a chance to throw at runtime.
  group('CoreRadioGroupStyle.defaultsBySize (#3773)', () {
    test('covers every CoreComponentSize member', () {
      for (final size in CoreComponentSize.values) {
        expect(
          CoreRadioGroupStyle.defaultsBySize[size],
          isNotNull,
          reason:
              'missing size chrome for CoreComponentSize.${size.name} — '
              'every `defaultsBySize[size]!` lookup in the resolvers '
              'assumes full coverage and would crash at runtime',
        );
      }
    });

    test('has exactly one entry per CoreComponentSize member', () {
      expect(
        CoreRadioGroupStyle.defaultsBySize.length,
        CoreComponentSize.values.length,
      );
    });
  });
}
