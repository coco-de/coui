// Tests for CoreTimePickerStyle (Epic #1302 — Story #1313).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const double _kFontLabel = 14;
const double _kFontTitle = 18;
const int _kWeightSemiBold = CoreFontWeight.semiBold;
const int _kWeightRegular = CoreFontWeight.regular;
const _kColorOnSurface = CoreColor.token(CoreColors.onSurface);
const _kColorError = CoreColor.token(CoreColors.error);
const _kColorPrimary = CoreColor.token(CoreColors.primary);

void main() {
  group('CoreTimePickerStyle.merge', () {
    test('null other returns this', () {
      const a = CoreTimePickerStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      expect(identical(a.merge(null), a), isTrue);
    });

    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreTimePickerStyle(
        labelStyle: CoreTextStyle(
          fontSize: _kFontLabel,
          fontWeight: _kWeightRegular,
          color: _kColorOnSurface,
        ),
      );
      const themeStyle = CoreTimePickerStyle(
        labelStyle: CoreTextStyle(fontWeight: _kWeightSemiBold),
      );
      const widgetStyle = CoreTimePickerStyle(
        errorStyle: CoreTextStyle(color: _kColorError),
      );

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.labelStyle?.fontSize, _kFontLabel);
      expect(effective.labelStyle?.fontWeight, _kWeightSemiBold);
      expect(effective.labelStyle?.color, _kColorOnSurface);
      expect(effective.errorStyle?.color, _kColorError);
    });

    test('right-most non-null wins on each field', () {
      const a = CoreTimePickerStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
        descriptionStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      const b = CoreTimePickerStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontTitle),
      );
      const c = CoreTimePickerStyle(
        descriptionStyle: CoreTextStyle(fontSize: _kFontTitle),
      );

      final result = a.merge(b).merge(c);

      expect(result.labelStyle?.fontSize, _kFontTitle);
      expect(result.descriptionStyle?.fontSize, _kFontTitle);
    });

    test('popoverStyle / dialogStyle / segmentInputStyle / amPmButtonStyle '
        'merge recursively', () {
      const base = CoreTimePickerStyle(
        popoverStyle: CorePopoverStyle(
          panelStyle: CorePopupStyle(borderRadius: CoreBorderRadius.all(8)),
          placementOffset: 8,
        ),
        dialogStyle: CoreDialogStyle(
          panelBorderRadius: CoreBorderRadius.all(12),
        ),
        segmentInputStyle: CoreTextFieldStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 8),
        ),
        amPmButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 12),
        ),
      );
      const override = CoreTimePickerStyle(
        popoverStyle: CorePopoverStyle(placementOffset: 12),
        amPmButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 16),
        ),
      );
      final merged = base.merge(override);
      expect(
        merged.popoverStyle?.panelStyle?.borderRadius,
        const CoreBorderRadius.all(8),
      );
      expect(merged.popoverStyle?.placementOffset, 12);
      expect(
        merged.dialogStyle?.panelBorderRadius,
        const CoreBorderRadius.all(12),
      );
      expect(
        merged.segmentInputStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 8),
      );
      expect(
        merged.amPmButtonStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 16),
      );
    });

    test('null nested style on base inherits from override', () {
      const base = CoreTimePickerStyle();
      const override = CoreTimePickerStyle(
        amPmButtonStyle: CoreButtonStyle(
          backgroundColor: _kColorPrimary,
          padding: CoreEdgeInsets.symmetric(horizontal: 16),
        ),
      );
      final merged = base.merge(override);
      expect(
        merged.amPmButtonStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 16),
      );
      expect(merged.amPmButtonStyle?.backgroundColor, _kColorPrimary);
    });
  });

  group('CoreTimePickerStyle equality', () {
    test('same fields → equal', () {
      const a = CoreTimePickerStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      const b = CoreTimePickerStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different segmentInputStyle → not equal', () {
      const a = CoreTimePickerStyle(
        segmentInputStyle: CoreTextFieldStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 8),
        ),
      );
      const b = CoreTimePickerStyle(
        segmentInputStyle: CoreTextFieldStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 12),
        ),
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreTimePickerStyle.copyWith', () {
    test('only-supplied fields override', () {
      const base = CoreTimePickerStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      final copy = base.copyWith(
        errorStyle: const CoreTextStyle(color: _kColorError),
      );
      expect(copy.labelStyle?.fontSize, _kFontLabel);
      expect(copy.errorStyle?.color, _kColorError);
    });

    test('preserves nested popoverStyle when not specified', () {
      const base = CoreTimePickerStyle(
        popoverStyle: CorePopoverStyle(placementOffset: 12),
      );
      final copy = base.copyWith(
        labelStyle: const CoreTextStyle(fontSize: _kFontLabel),
      );
      expect(copy.labelStyle?.fontSize, _kFontLabel);
      expect(copy.popoverStyle?.placementOffset, 12);
    });
  });

  group('CoreTimePickerTheme', () {
    test('style passes through', () {
      const style = CoreTimePickerStyle(
        amPmButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 16),
        ),
      );
      const theme = CoreTimePickerTheme(style: style);
      expect(theme.style, style);
    });

    test('null style', () {
      const theme = CoreTimePickerTheme();
      expect(theme.style, isNull);
    });

    test('equality', () {
      const a = CoreTimePickerTheme(
        style: CoreTimePickerStyle(
          popoverStyle: CorePopoverStyle(placementOffset: 12),
        ),
      );
      const b = CoreTimePickerTheme(
        style: CoreTimePickerStyle(
          popoverStyle: CorePopoverStyle(placementOffset: 12),
        ),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CoreTimePickerStyle dimensional fields', () {
    test('merge propagates non-null dimensional fields', () {
      const base = CoreTimePickerStyle(
        triggerHeight: 40,
        triggerContentGapStyle: CoreGapStyle(size: 8),
        segmentSize: 64,
        separatorPadding: CoreEdgeInsets.all(16),
        actionRowGapStyle: CoreGapStyle(size: 16),
      );
      const override = CoreTimePickerStyle(
        triggerHeight: 48,
        separatorPadding: CoreEdgeInsets.all(24),
      );
      final merged = base.merge(override);
      expect(merged.triggerHeight, 48);
      expect(merged.triggerContentGapStyle?.size, 8);
      expect(merged.segmentSize, 64);
      expect(merged.separatorPadding, const CoreEdgeInsets.all(24));
      expect(merged.actionRowGapStyle?.size, 16);
    });

    test('copyWith replaces dimensional fields', () {
      const base = CoreTimePickerStyle(
        triggerHeight: 40,
        segmentBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
        triggerBorderWidth: 1,
        dialogLabelSpacing: 4,
        dialogOuterGapStyle: CoreGapStyle(size: 16),
        separatorPadding: CoreEdgeInsets.all(8),
      );
      final next = base.copyWith(
        triggerHeight: 48,
        segmentBorderRadius: const CoreBorderRadius.all(CoreRadius.radius12),
        separatorPadding: const CoreEdgeInsets.all(4),
      );
      expect(next.triggerHeight, 48);
      expect(
        next.segmentBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius12),
      );
      expect(next.triggerBorderWidth, 1);
      expect(next.dialogLabelSpacing, 4);
      expect(next.dialogOuterGapStyle?.size, 16);
      expect(next.separatorPadding, const CoreEdgeInsets.all(4));
    });

    test('equality and hashCode cover dimensional fields', () {
      const a = CoreTimePickerStyle(
        triggerHeight: 40,
        separatorPadding: CoreEdgeInsets.all(16),
      );
      const b = CoreTimePickerStyle(
        triggerHeight: 40,
        separatorPadding: CoreEdgeInsets.all(16),
      );
      const c = CoreTimePickerStyle(
        triggerHeight: 48,
        separatorPadding: CoreEdgeInsets.all(16),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });
  });

  // The segment focus ring is what both platform resolvers read to size
  // and colour the ring. Nothing above covered it, so a `merge` that
  // dropped it — or an `==` that ignored it, which is how a theme swap
  // stops repainting — would have gone unnoticed here and shown up only
  // as a ring that quietly stays at the default.
  group('CoreTimePickerStyle segment hover state layer', () {
    const layerRaw = CoreColor(0xFF00FF00);
    const ramp = CoreStateLayer(
      hover: CoreOpacity.opacity16,
      focus: CoreOpacity.opacity16,
      pressed: CoreOpacity.opacity16,
    );

    test('the resting segment border is transparent and the hover layer is '
        'onSurface at the shared ramp’s hover weight', () {
      expect(
        CoreTimePickerStyle.defaultSegmentBorderColor,
        CoreColor.transparent,
      );
      expect(
        CoreTimePickerStyle.defaultSegmentStateLayerColor,
        const CoreColor.token(CoreColors.onSurface),
      );
      expect(
        CoreTimePickerStyle.defaultSegmentStateLayer,
        CoreStateLayer.subtle,
      );
    });

    test('the layer fields are their own, apart from the border', () {
      const style = CoreTimePickerStyle(
        segmentStateLayerColor: layerRaw,
        segmentStateLayer: ramp,
      );
      expect(style.segmentStateLayerColor, layerRaw);
      expect(style.segmentStateLayer, ramp);
      expect(style.segmentBorderColor, isNull);
    });

    test('merge — the right-most value wins, null keeps the base', () {
      const base = CoreTimePickerStyle(
        segmentStateLayerColor: CoreColor.token(CoreColors.primary),
        segmentStateLayer: ramp,
      );
      final merged = base.merge(
        const CoreTimePickerStyle(segmentStateLayerColor: layerRaw),
      );
      expect(merged.segmentStateLayerColor, layerRaw);
      expect(merged.segmentStateLayer, ramp);
      expect(
        base
            .merge(const CoreTimePickerStyle(segmentSize: 48))
            .segmentStateLayerColor,
        const CoreColor.token(CoreColors.primary),
      );
    });

    test('copyWith replaces the fields and leaves them alone otherwise', () {
      const base = CoreTimePickerStyle(
        segmentStateLayerColor: layerRaw,
        segmentStateLayer: ramp,
      );
      final replaced = base.copyWith(
        segmentStateLayerColor: const CoreColor.token(CoreColors.primary),
        segmentStateLayer: CoreStateLayer.subtle,
      );
      expect(
        replaced.segmentStateLayerColor,
        const CoreColor.token(CoreColors.primary),
      );
      expect(replaced.segmentStateLayer, CoreStateLayer.subtle);
      final kept = base.copyWith(segmentSize: 48);
      expect(kept.segmentStateLayerColor, layerRaw);
      expect(kept.segmentStateLayer, ramp);
    });

    test('equality and hashCode cover both layer fields', () {
      const a = CoreTimePickerStyle(
        segmentStateLayerColor: layerRaw,
        segmentStateLayer: ramp,
      );
      const b = CoreTimePickerStyle(
        segmentStateLayerColor: layerRaw,
        segmentStateLayer: ramp,
      );
      const colourDiffers = CoreTimePickerStyle(
        segmentStateLayerColor: CoreColor.token(CoreColors.primary),
        segmentStateLayer: ramp,
      );
      const rampDiffers = CoreTimePickerStyle(
        segmentStateLayerColor: layerRaw,
        segmentStateLayer: CoreStateLayer.subtle,
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(colourDiffers)));
      expect(a, isNot(equals(rampDiffers)));
      expect(a.hashCode, isNot(colourDiffers.hashCode));
    });

    // The popover panel is the popup's own surface: corner 12 (the panel
    // role) and the quieter `outlineVariant` edge come from `Popup`, so the
    // picker's default states neither — only its 16 padding.
    test('the popover panel takes its corner and edge from Popup', () {
      final panel = CoreTimePickerStyle.defaultPopoverStyle.panelStyle!;
      expect(panel.borderRadius, isNull);
      expect(panel.borderColor, isNull);
      expect(panel.padding, const CoreEdgeInsets.all(CoreSpace.space16));
      expect(
        CorePopupStyle.defaultBorderRadius,
        const CoreBorderRadius.all(CoreRadiusRole.panel),
      );
      expect(
        CorePopupStyle.defaultBorderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
    });

    test('the segment tile is 64x60, corner 10, a filled face', () {
      expect(CoreTimePickerStyle.defaultSegmentSize, 64);
      expect(CoreTimePickerStyle.defaultSegmentHeight, 60);
      expect(
        CoreTimePickerStyle.defaultSegmentBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius10),
      );
      expect(
        CoreTimePickerStyle.defaultSegmentSurfaceColor,
        const CoreColor.token(CoreColors.surfaceContainerHigh),
      );
      expect(
        CoreTimePickerStyle.defaultSegmentBorderColor,
        CoreColor.transparent,
      );
    });

    test(
      'the edited segment wears a primaryContainer face and a 2px '
      'primaryText inside border',
      () {
        expect(
          CoreTimePickerStyle.defaultSegmentFocusedSurfaceColor,
          const CoreColor.token(CoreColors.primaryContainer),
        );
        expect(
          CoreTimePickerStyle.defaultSegmentFocusedContentColor,
          const CoreColor.token(CoreColors.onPrimaryContainer),
        );
        expect(
          CoreTimePickerStyle.defaultSegmentFocusedBorderColor,
          const CoreColor.token(CoreColors.primaryText),
        );
        expect(
          CoreTimePickerStyle.defaultSegmentFocusedBorderWidth,
          CoreStrokeWidth.stroke2,
        );
      },
    );

    test('the focused border merges, copies and compares', () {
      const base = CoreTimePickerStyle(
        segmentFocusedBorderColor: _kColorPrimary,
        segmentFocusedBorderWidth: 3,
      );
      final merged = base.merge(
        const CoreTimePickerStyle(segmentFocusedBorderWidth: 4),
      );
      expect(merged.segmentFocusedBorderColor, _kColorPrimary);
      expect(merged.segmentFocusedBorderWidth, 4);
      final copy = base.copyWith(segmentFocusedBorderColor: _kColorError);
      expect(copy.segmentFocusedBorderColor, _kColorError);
      expect(copy.segmentFocusedBorderWidth, 3);
      expect(base, equals(base.copyWith()));
      expect(base.hashCode, base.copyWith().hashCode);
      expect(
        base,
        isNot(equals(base.copyWith(segmentFocusedBorderColor: _kColorError))),
      );
      expect(
        base,
        isNot(equals(base.copyWith(segmentFocusedBorderWidth: 1))),
      );
    });

    test('segmentHeight and the focused face merge, copy and compare', () {
      const base = CoreTimePickerStyle(
        segmentHeight: 56,
        segmentFocusedSurfaceColor: _kColorPrimary,
        segmentFocusedContentColor: _kColorError,
      );
      final merged = base.merge(const CoreTimePickerStyle(segmentSize: 60));
      expect(merged.segmentHeight, 56);
      expect(merged.segmentSize, 60);
      expect(merged.segmentFocusedSurfaceColor, _kColorPrimary);
      expect(merged.segmentFocusedContentColor, _kColorError);
      final copy = base.copyWith(segmentHeight: 64);
      expect(copy.segmentHeight, 64);
      expect(copy.segmentFocusedSurfaceColor, _kColorPrimary);
      expect(base, equals(base.copyWith()));
      expect(base.hashCode, base.copyWith().hashCode);
      expect(base, isNot(equals(base.copyWith(segmentHeight: 64))));
      expect(
        base,
        isNot(equals(base.copyWith(segmentFocusedSurfaceColor: _kColorError))),
      );
      expect(
        base,
        isNot(
          equals(base.copyWith(segmentFocusedContentColor: _kColorPrimary)),
        ),
      );
    });
  });

  group('CoreTimePickerStyle segmentFocusOutlineStyle', () {
    const base = CoreTimePickerStyle(
      segmentFocusOutlineStyle: CoreFocusOutlineStyle(
        align: 4,
        borderColor: CoreColor.token(CoreColors.primary),
        borderWidth: 2,
      ),
    );

    // Every field is overridden at once: an assertion that only ever
    // reads the base value cannot tell a working `merge` from one that
    // ignores `other` entirely.
    test('merge — every ring field takes the override value', () {
      const override = CoreTimePickerStyle(
        segmentFocusOutlineStyle: CoreFocusOutlineStyle(
          align: 10,
          borderColor: CoreColor.token(CoreColors.error),
          borderWidth: 4,
        ),
      );
      final merged = base.merge(override).segmentFocusOutlineStyle;
      expect(merged?.borderColor, const CoreColor.token(CoreColors.error));
      expect(merged?.borderWidth, 4);
      expect(merged?.align, 10);
    });

    // The nested slot must merge *into* the base, not replace it. A
    // `merge` written as `other.slot ?? slot` passes every other test in
    // this group and fails only this one — and the failure is invisible
    // in the type system: overriding just the width would silently drop
    // the caller's own ring colour back to the default.
    test('merge — an override recurses into the slot, it does not replace '
        'it', () {
      const override = CoreTimePickerStyle(
        segmentFocusOutlineStyle: CoreFocusOutlineStyle(borderWidth: 4),
      );
      final merged = base.merge(override).segmentFocusOutlineStyle;
      expect(merged?.borderWidth, 4);
      expect(merged?.align, 4, reason: 'untouched field survives the merge');
      expect(merged?.borderColor, const CoreColor.token(CoreColors.primary));
    });

    test('merge — a null override keeps the base slot', () {
      const override = CoreTimePickerStyle();
      final merged = base.merge(override).segmentFocusOutlineStyle;
      expect(merged?.borderWidth, 2);
      expect(merged?.borderColor, const CoreColor.token(CoreColors.primary));
    });

    // `copyWith` swaps the slot wholesale — the documented difference
    // from `merge`, asserted so the two cannot quietly converge.
    test('copyWith replaces the slot wholesale', () {
      final next = base.copyWith(
        segmentFocusOutlineStyle: const CoreFocusOutlineStyle(borderWidth: 4),
      );
      expect(next.segmentFocusOutlineStyle?.borderWidth, 4);
      expect(next.segmentFocusOutlineStyle?.borderColor, isNull);
      expect(next.segmentFocusOutlineStyle?.align, isNull);
    });

    test('copyWith leaves the slot alone when unsupplied', () {
      final next = base.copyWith(triggerHeight: 48);
      expect(next.segmentFocusOutlineStyle, base.segmentFocusOutlineStyle);
    });

    test('equality and hashCode cover the slot', () {
      const a = CoreTimePickerStyle(
        segmentFocusOutlineStyle: CoreFocusOutlineStyle(
          align: 6,
          borderWidth: 4,
        ),
      );
      const b = CoreTimePickerStyle(
        segmentFocusOutlineStyle: CoreFocusOutlineStyle(
          align: 6,
          borderWidth: 4,
        ),
      );
      const differentWidth = CoreTimePickerStyle(
        segmentFocusOutlineStyle: CoreFocusOutlineStyle(
          align: 6,
          borderWidth: 2,
        ),
      );
      const differentAlign = CoreTimePickerStyle(
        segmentFocusOutlineStyle: CoreFocusOutlineStyle(
          align: 2,
          borderWidth: 4,
        ),
      );
      const differentColor = CoreTimePickerStyle(
        segmentFocusOutlineStyle: CoreFocusOutlineStyle(
          align: 6,
          borderColor: CoreColor.token(CoreColors.error),
          borderWidth: 4,
        ),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(differentWidth)));
      expect(a, isNot(equals(differentAlign)));
      expect(a, isNot(equals(differentColor)));
      // `hashCode` is asserted per field too: a field that reaches `==`
      // but not `hashCode` still breaks the value-identity a theme swap
      // relies on to decide whether to repaint.
      expect(a.hashCode, isNot(differentWidth.hashCode));
      expect(a.hashCode, isNot(differentAlign.hashCode));
      expect(a.hashCode, isNot(differentColor.hashCode));
    });

    // The default states the colour and nothing else — every other field
    // must stay null so `FocusOutline`'s own resolver (Flutter) or the
    // shared `CoreFocusOutlineStyle` defaults (Web) fill it. A default
    // that started stating `align` or `borderWidth` would be this
    // component re-deriving a value it does not own, which is the drift
    // this migration removed.
    test('the component default states only the colour', () {
      const fallback = CoreTimePickerStyle.defaultSegmentFocusOutlineStyle;
      expect(fallback.borderColor, const CoreColor.token(CoreColors.primary));
      expect(fallback.align, isNull);
      expect(fallback.borderWidth, isNull);
      expect(fallback.borderRadius, isNull);
      expect(fallback.offsetColor, isNull);
      expect(fallback.duration, isNull);
    });
  });

  // The trigger is a read-only TextField and the am/pm choice a ToggleGroup:
  // the new slots take part in merge, copyWith and equality like every field.
  group('CoreTimePickerStyle trigger field and am/pm toggle', () {
    test('triggerStyle merges field by field', () {
      const base = CoreTimePickerStyle(
        triggerStyle: CoreTextFieldStyle(height: 40, borderWidth: 1),
      );
      const override = CoreTimePickerStyle(
        triggerStyle: CoreTextFieldStyle(height: 48),
      );
      final merged = base.merge(override);
      expect(merged.triggerStyle?.height, 48);
      expect(merged.triggerStyle?.borderWidth, 1);
    });

    test('amPmToggleStyle merges and copies', () {
      const base = CoreTimePickerStyle(
        amPmToggleStyle: CoreToggleGroupStyle(itemHeight: 32),
      );
      final merged = base.merge(
        const CoreTimePickerStyle(
          amPmToggleStyle: CoreToggleGroupStyle(itemSpacing: 4),
        ),
      );
      expect(merged.amPmToggleStyle?.itemHeight, 32);
      expect(merged.amPmToggleStyle?.itemSpacing, 4);

      final copy = base.copyWith(triggerHeight: 48);
      expect(copy.triggerHeight, 48);
      expect(copy.amPmToggleStyle?.itemHeight, 32);
    });

    test('equality and hashCode cover the new fields', () {
      const a = CoreTimePickerStyle(
        triggerStyle: CoreTextFieldStyle(height: 40),
        amPmToggleStyle: CoreToggleGroupStyle(itemHeight: 32),
      );
      const b = CoreTimePickerStyle(
        triggerStyle: CoreTextFieldStyle(height: 40),
        amPmToggleStyle: CoreToggleGroupStyle(itemHeight: 32),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(a.copyWith(triggerHeight: 44))));
      expect(
        a,
        isNot(
          equals(
            a.copyWith(triggerStyle: const CoreTextFieldStyle(height: 48)),
          ),
        ),
      );
      expect(
        a,
        isNot(
          equals(
            a.copyWith(
              amPmToggleStyle: const CoreToggleGroupStyle(itemHeight: 36),
            ),
          ),
        ),
      );
    });

    test('the trigger default: pressed-only state layer', () {
      final layer = CoreTimePickerStyle.defaultTriggerStyle.stateLayer!;
      expect(layer.hover, CoreOpacity.opacity0);
      expect(layer.focus, CoreOpacity.opacity0);
      expect(layer.pressed, CoreOpacity.pressed);
    });

    test(
      'effectiveTriggerStyle folds the picker decisions under triggerStyle',
      () {
        const style = CoreTimePickerStyle(
          triggerHeight: 48,
          contentColor: _kColorPrimary,
          triggerStyle: CoreTextFieldStyle(borderWidth: 2),
        );
        final field = style.effectiveTriggerStyle;
        expect(field.height, 48);
        expect(field.valueStyle?.color, _kColorPrimary);
        expect(
          field.placeholderStyle?.color,
          CoreTimePickerStyle.defaultPlaceholderColor,
        );
        expect(field.borderWidth, 2);
        expect(
          field.stateLayer,
          CoreTimePickerStyle.defaultTriggerStyle.stateLayer,
        );
        expect(
          field.errorBorderColor,
          CoreTimePickerStyle.defaultErrorTriggerStyle.borderColor,
        );
      },
    );

    test('a disabled picker leaves the text colours to the field', () {
      final field = const CoreTimePickerStyle(
        contentColor: _kColorPrimary,
      ).effectiveDisabledTriggerStyle;
      expect(field.valueStyle, isNull);
      expect(field.placeholderStyle, isNull);
    });

    test('the deprecated errorTriggerStyle edge is the error edge, and '
        'triggerStyle outranks it', () {
      const edge = CoreColor.token(CoreColors.tertiary);
      const legacy = CoreTimePickerStyle(
        errorTriggerStyle: CoreButtonStyle(borderColor: edge),
      );
      expect(legacy.effectiveTriggerStyle.errorBorderColor, edge);
      final both = legacy.copyWith(
        triggerStyle: const CoreTextFieldStyle(errorBorderColor: _kColorError),
      );
      expect(both.effectiveTriggerStyle.errorBorderColor, _kColorError);
    });

    test('the trigger wrapper fills the axis, like every field trigger', () {
      expect(
        CoreTimePickerStyle.defaultPopoverStyle.triggerSizing,
        CorePopoverTriggerSizing.expand,
      );
    });
  });
}
