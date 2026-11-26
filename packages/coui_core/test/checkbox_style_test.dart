// Tests for CoreCheckboxStyle (Epic #1302 — Story #1308 Checkbox).
//
// Mirrors the merge-chain pattern of #1316 / #1317 / #1306 / #1307.
// variant / size are NOT in CoreCheckboxStyle — they live on the
// widget (Epic #1302 원칙 6/7).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const double _kBoxSizeSm = 16;
const double _kBoxSizeMd = 20;
const _kBoxRadiusSm = CoreBorderRadius.all(2);
const _kBoxRadiusLg = CoreBorderRadius.all(6);
const double _kBoxBorderThin = 1;
const double _kBoxBorderThick = 2;
const _kGapSm = CoreGapStyle(size: 4);
const _kGapLg = CoreGapStyle(size: 8);

const _kBgSurface = CoreColor.token(CoreColors.surface);
const _kActivePrimary = CoreColor.token(CoreColors.primary);
const _kActiveSuccess = CoreColor.token(CoreColors.success);
const _kBorderOutline = CoreColor.token(CoreColors.outline);
// `CoreTextStyle.color` / `CoreIconStyle.color` are now `CoreColor?`
// (Epic #1415 Phase 2). These tokens are used in nested text/icon slots.
const _kBgPrimaryClr = CoreColor.token(CoreColors.primary);
const _kActiveSuccessClr = CoreColor.token(CoreColors.success);
const _kBorderOutlineClr = CoreColor.token(CoreColors.outline);
const _kBorderErrorClr = CoreColor.token(CoreColors.error);

const double _kIconSm = 12;
const double _kIconMd = 16;

const double _kFontBody = 14;
const int _kWeightRegular = CoreFontWeight.regular;
const int _kWeightSemiBold = CoreFontWeight.semiBold;

void main() {
  group('CoreCheckboxStyle.merge', () {
    test('null other returns this', () {
      const a = CoreCheckboxStyle(
        boxBackgroundColor: _kBgSurface,
        boxSize: _kBoxSizeMd,
      );
      expect(identical(a.merge(null), a), isTrue);
    });

    test('non-null fields in other override receiver', () {
      const base = CoreCheckboxStyle(
        boxBackgroundColor: _kBgSurface,
        boxBorderColor: _kBorderOutline,
        boxBorderRadius: _kBoxRadiusSm,
        boxSize: _kBoxSizeMd,
        indicatorLabelGapStyle: _kGapLg,
      );
      const override = CoreCheckboxStyle(
        boxBorderRadius: _kBoxRadiusLg,
        indicatorLabelGapStyle: _kGapSm,
      );
      final merged = base.merge(override);
      expect(merged.boxBackgroundColor, _kBgSurface);
      expect(merged.boxBorderColor, _kBorderOutline);
      expect(merged.boxBorderRadius, _kBoxRadiusLg);
      expect(merged.boxSize, _kBoxSizeMd);
      expect(merged.indicatorLabelGapStyle, _kGapSm);
    });

    test('chain — design system → theme.style → parent slot → widget', () {
      const designSystem = CoreCheckboxStyle(
        boxBackgroundColor: _kBgSurface,
        boxBorderColor: _kBorderOutline,
        boxBorderWidth: _kBoxBorderThin,
        boxBorderRadius: _kBoxRadiusSm,
        boxSize: _kBoxSizeMd,
        indicatorLabelGapStyle: _kGapLg,
      );
      const themeStyle = CoreCheckboxStyle(
        boxBorderRadius: _kBoxRadiusLg,
      );
      const parentSlotStyle = CoreCheckboxStyle(
        boxActiveColor: _kActivePrimary,
      );
      const widgetStyle = CoreCheckboxStyle(
        indicatorLabelGapStyle: _kGapSm,
      );

      final effective = designSystem
          .merge(themeStyle)
          .merge(parentSlotStyle)
          .merge(widgetStyle);

      expect(effective.boxBackgroundColor, _kBgSurface);
      expect(effective.boxBorderColor, _kBorderOutline);
      expect(effective.boxBorderWidth, _kBoxBorderThin);
      expect(effective.boxBorderRadius, _kBoxRadiusLg); // theme override
      expect(effective.boxSize, _kBoxSizeMd);
      expect(effective.boxActiveColor, _kActivePrimary); // parent override
      expect(effective.indicatorLabelGapStyle, _kGapSm); // widget override
    });

    test('right-most non-null wins on each field', () {
      const a = CoreCheckboxStyle(
        boxBorderWidth: _kBoxBorderThin,
        boxSize: _kBoxSizeSm,
      );
      const b = CoreCheckboxStyle(boxSize: _kBoxSizeMd);
      const c = CoreCheckboxStyle(boxBorderWidth: _kBoxBorderThick);

      final result = a.merge(b).merge(c);

      expect(result.boxSize, _kBoxSizeMd);
      expect(result.boxBorderWidth, _kBoxBorderThick);
    });

    test('checkmarkIconStyle merges recursively', () {
      const base = CoreCheckboxStyle(
        checkmarkIconStyle: CoreIconStyle(
          size: _kIconMd,
          color: _kBgPrimaryClr,
        ),
      );
      const override = CoreCheckboxStyle(
        checkmarkIconStyle: CoreIconStyle(color: _kBorderErrorClr),
      );
      final merged = base.merge(override);
      expect(merged.checkmarkIconStyle?.size, _kIconMd);
      expect(merged.checkmarkIconStyle?.color, _kBorderErrorClr);
    });

    test('labelStyle merges recursively (subset override)', () {
      const base = CoreCheckboxStyle(
        labelStyle: CoreTextStyle(
          fontSize: _kFontBody,
          fontWeight: _kWeightRegular,
          color: _kBorderOutlineClr,
        ),
      );
      const override = CoreCheckboxStyle(
        labelStyle: CoreTextStyle(fontWeight: _kWeightSemiBold),
      );
      final merged = base.merge(override);
      expect(merged.labelStyle?.fontSize, _kFontBody);
      expect(merged.labelStyle?.fontWeight, _kWeightSemiBold);
      expect(merged.labelStyle?.color, _kBorderOutlineClr);
    });

    test('null nested style on base inherits from override', () {
      const base = CoreCheckboxStyle();
      const override = CoreCheckboxStyle(
        checkmarkIconStyle: CoreIconStyle(
          size: _kIconSm,
          color: _kActiveSuccessClr,
        ),
      );
      final merged = base.merge(override);
      expect(merged.checkmarkIconStyle?.size, _kIconSm);
      expect(merged.checkmarkIconStyle?.color, _kActiveSuccessClr);
    });
  });

  group('CoreCheckboxStyle equality', () {
    test('same fields → equal', () {
      const a = CoreCheckboxStyle(
        boxActiveColor: _kActivePrimary,
        boxSize: _kBoxSizeMd,
        indicatorLabelGapStyle: _kGapSm,
      );
      const b = CoreCheckboxStyle(
        boxActiveColor: _kActivePrimary,
        boxSize: _kBoxSizeMd,
        indicatorLabelGapStyle: _kGapSm,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different boxActiveColor → not equal', () {
      const a = CoreCheckboxStyle(boxActiveColor: _kActivePrimary);
      const b = CoreCheckboxStyle(boxActiveColor: _kActiveSuccess);
      expect(a, isNot(equals(b)));
    });

    test('different checkmarkIconStyle → not equal', () {
      const a = CoreCheckboxStyle(
        checkmarkIconStyle: CoreIconStyle(size: _kIconSm),
      );
      const b = CoreCheckboxStyle(
        checkmarkIconStyle: CoreIconStyle(size: _kIconMd),
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreCheckboxStyle.copyWith', () {
    test('only-supplied fields override', () {
      const base = CoreCheckboxStyle(
        boxBorderColor: _kBorderOutline,
        boxSize: _kBoxSizeMd,
        indicatorLabelGapStyle: _kGapLg,
      );
      final copy = base.copyWith(boxSize: _kBoxSizeSm);
      expect(copy.boxSize, _kBoxSizeSm);
      expect(copy.boxBorderColor, _kBorderOutline);
      expect(copy.indicatorLabelGapStyle, _kGapLg);
    });

    test('preserves nested styles when not specified', () {
      const base = CoreCheckboxStyle(
        checkmarkIconStyle: CoreIconStyle(size: _kIconMd),
        labelStyle: CoreTextStyle(fontSize: _kFontBody),
      );
      final copy = base.copyWith(boxActiveColor: _kActiveSuccess);
      expect(copy.boxActiveColor, _kActiveSuccess);
      expect(copy.labelStyle?.fontSize, _kFontBody);
      expect(copy.checkmarkIconStyle?.size, _kIconMd);
    });
  });

  group('CoreCheckboxTheme', () {
    test('style passes through', () {
      const style = CoreCheckboxStyle(indicatorLabelGapStyle: _kGapLg);
      const theme = CoreCheckboxTheme(style: style);
      expect(theme.style, style);
    });

    test('null fields', () {
      const theme = CoreCheckboxTheme();
      expect(theme.style, isNull);
    });

    test('equality', () {
      const a = CoreCheckboxTheme(
        style: CoreCheckboxStyle(indicatorLabelGapStyle: _kGapLg),
      );
      const b = CoreCheckboxTheme(
        style: CoreCheckboxStyle(indicatorLabelGapStyle: _kGapLg),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group("the redesign's defaults (2026-09 canvas)", () {
    test('stroke and corner are size-invariant — not on the size rows', () {
      // The two values a generator on the size axis kept moving back to
      // `stroke2` / `radius8` at `xl` / `xl2`. They live once, flat. The
      // stroke is the 1 px line RadioGroup also rests on.
      expect(
        CoreCheckboxStyle.defaultBoxBorderWidth,
        CoreStrokeWidth.stroke1,
      );
      expect(
        CoreCheckboxStyle.defaultBoxBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius4),
      );
      for (final size in CoreComponentSize.values) {
        final row = CoreCheckboxStyle.defaultsBySize[size]!;
        expect(
          row.boxBorderWidth,
          isNull,
          reason:
              '${size.name} row states a stroke — the size axis '
              'must not carry it',
        );
        expect(row.boxBorderRadius, isNull);
      }
    });

    test('the dash thickness is one constant; the dash length steps', () {
      // The dash takes the icon rule's floor, so the two cannot be edited
      // apart; the literal pins the value the canvas and both platforms read.
      expect(
        CoreCheckboxStyle.defaultMarkThickness,
        CoreIconStroke.minRenderedWidth,
      );
      expect(CoreCheckboxStyle.defaultMarkThickness, 1.25);
      final lengths = [
        for (final size in [
          CoreComponentSize.xs,
          CoreComponentSize.sm,
          CoreComponentSize.md,
          CoreComponentSize.lg,
          CoreComponentSize.xl,
          CoreComponentSize.xl2,
        ])
          CoreCheckboxStyle.defaultsBySize[size]!.indeterminateLength,
      ];
      expect(lengths, [
        CoreSize.size6,
        CoreSize.size6,
        CoreSize.size8,
        CoreSize.size8,
        CoreSize.size10,
        CoreSize.size12,
      ]);
    });

    test('the check follows the icon rule and lands on the dash thickness', () {
      // The check is an ordinary icon, so its stroke is the icon rule's at the
      // glyph's token size. Every size row must land on the dash thickness —
      // a floor or a default edited on its own breaks the match here.
      const rows = CoreCheckboxStyle.defaultsBySize;
      expect(
        [for (final row in rows.values) row.checkmarkSize],
        [
          CoreSize.size8,
          CoreSize.size10,
          CoreSize.size10,
          CoreSize.size12,
          CoreSize.size14,
          CoreSize.size16,
        ],
      );
      for (final entry in rows.entries) {
        final glyph = entry.value.checkmarkSize!;
        expect(
          CoreIconStroke.renderedWidth(glyph),
          CoreCheckboxStyle.defaultMarkThickness,
          reason:
              '${entry.key.name}: the check at token size $glyph strokes at '
              '${CoreIconStroke.renderedWidth(glyph)}, the dash at '
              '${CoreCheckboxStyle.defaultMarkThickness}',
        );
      }
    });

    test('the resting box has no fill and an outline stroke', () {
      expect(
        CoreCheckboxStyle.defaultBoxBackgroundColor,
        CoreColor.transparent,
      );
      expect(
        CoreCheckboxStyle.defaultBoxBorderColor,
        const CoreColor.token(CoreColors.outline),
      );
    });

    test('disabled draws with the disabled ramp, mark included', () {
      expect(
        CoreCheckboxStyle.defaultDisabledBackgroundColor,
        const CoreColor.token(CoreColors.disabledContainer),
      );
      expect(
        CoreCheckboxStyle.defaultDisabledBorderColor,
        const CoreColor.token(CoreColors.disabledOutline),
      );
      expect(
        CoreCheckboxStyle.defaultDisabledForegroundColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
      // The invisible-mark defect: `onPrimary` over the disabled
      // container. The mark has its own disabled ink now.
      expect(
        CoreCheckboxStyle.defaultDisabledCheckmarkColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
      expect(
        CoreCheckboxStyle.defaultDisabledCheckmarkColor,
        isNot(CoreCheckboxStyle.defaultCheckmarkIconStyle.color),
      );
    });

    test('the halo is the shared selection-control ramp, box + 8', () {
      expect(CoreCheckboxStyle.defaultStateLayer, CoreStateLayer.standard);
      expect(CoreCheckboxStyle.defaultStateLayer.hover, CoreOpacity.opacity8);
      expect(
        CoreCheckboxStyle.defaultStateLayer.pressed,
        CoreOpacity.opacity16,
      );
      expect(CoreCheckboxStyle.defaultStateLayerSpread, CoreSpace.space4);
      expect(
        CoreCheckboxStyle.defaultStateLayerBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius8),
      );
      expect(
        CoreCheckboxStyle.defaultStateLayerColor,
        const CoreColor.token(CoreColors.onSurface),
      );
    });

    test('the label is body copy — 400 / 150% — not a Button label', () {
      final label = CoreCheckboxStyle.defaultLabelStyle.token!.read(
        CoreTypography.coui,
      );
      expect(label.fontWeight, CoreFontWeight.regular);
      expect(label.lineHeight, CoreLineHeight.h150);
    });

    test('every new field round-trips through merge / copyWith / ==', () {
      const a = CoreCheckboxStyle(
        markThickness: 2,
        indeterminateBorderRadius: _kBoxRadiusSm,
        disabledCheckmarkColor: _kBorderErrorClr,
        stateLayer: CoreStateLayer.subtle,
        stateLayerColor: _kActivePrimary,
        stateLayerSpread: 6,
        stateLayerBorderRadius: _kBoxRadiusLg,
        focusOutlineStyle: CoreFocusOutlineStyle(align: 6),
      );
      final merged = const CoreCheckboxStyle().merge(a);
      expect(merged, equals(a));
      expect(merged.hashCode, a.hashCode);
      final copy = a.copyWith(markThickness: 3);
      expect(copy.markThickness, 3);
      expect(copy.stateLayer, CoreStateLayer.subtle);
      expect(copy.stateLayerSpread, 6);
      expect(copy.indeterminateBorderRadius, _kBoxRadiusSm);
      expect(copy.focusOutlineStyle?.align, 6);
      expect(copy, isNot(equals(a)));
    });

    test('the ring default is the system focus recipe, corner-less', () {
      const ring = CoreCheckboxStyle.defaultFocusOutlineStyle;
      expect(ring.align, CoreFocusOutlineStyle.defaultAlign);
      expect(ring.borderWidth, CoreFocusOutlineStyle.defaultBorderWidth);
      expect(ring.borderColor, CoreFocusOutlineStyle.defaultBorderColor);
      expect(ring.offsetColor, CoreFocusOutlineStyle.defaultOffsetColor);
      expect(
        ring.offsetColor,
        CoreColor.transparent,
        reason: 'the box sits on a known background — the gap shows it',
      );
      expect(ring.ringOpacity, CoreFocusOutlineStyle.defaultRingOpacity);
      expect(
        ring.borderRadius,
        isNull,
        reason: 'the corner derives from the box, never from this default',
      );
      // A partial override keeps the rest of the recipe.
      final tuned = ring.merge(const CoreFocusOutlineStyle(borderWidth: 3));
      expect(tuned.borderWidth, 3);
      expect(tuned.align, CoreFocusOutlineStyle.defaultAlign);
    });
  });

  // #3773 — `defaultsBySize[size]!` is a Map lookup, not a `switch`, so
  // Dart's exhaustiveness checker never sees it. This group is the net
  // — it fails the moment a member is added without a matching entry,
  // before any `!` ever gets a chance to throw at runtime.
  group('CoreCheckboxStyle.defaultsBySize (#3773)', () {
    test('covers every CoreComponentSize member', () {
      for (final size in CoreComponentSize.values) {
        expect(
          CoreCheckboxStyle.defaultsBySize[size],
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
        CoreCheckboxStyle.defaultsBySize.length,
        CoreComponentSize.values.length,
      );
    });
  });
}
