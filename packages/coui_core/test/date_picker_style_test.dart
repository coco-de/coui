// Tests for CoreDatePickerStyle (Epic #1302 — Story #1312).
// ignore_for_file: avoid_redundant_argument_values

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kSelectedPrimary = CoreColor.token(CoreColors.primary);
const _kSelectedSuccess = CoreColor.token(CoreColors.success);
const _kBgSurface = CoreColor.token(CoreColors.surface);
const _kBgError = CoreColor.token(CoreColors.error);

const double _kFontLabel = 14;
const double _kFontTitle = 18;
const int _kWeightSemiBold = CoreFontWeight.semiBold;
const int _kWeightRegular = CoreFontWeight.regular;
const _kColorOnSurface = CoreColor.token(CoreColors.onSurface);
const _kColorError = CoreColor.token(CoreColors.error);

void main() {
  group('CoreDatePickerStyle.merge', () {
    test('null other returns this', () {
      const a = CoreDatePickerStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      expect(identical(a.merge(null), a), isTrue);
    });

    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreDatePickerStyle(
        labelStyle: CoreTextStyle(
          fontSize: _kFontLabel,
          fontWeight: _kWeightRegular,
          color: _kColorOnSurface,
        ),
        descriptionStyle: CoreTextStyle(color: _kColorOnSurface),
      );
      const themeStyle = CoreDatePickerStyle(
        labelStyle: CoreTextStyle(fontWeight: _kWeightSemiBold),
      );
      const widgetStyle = CoreDatePickerStyle(
        errorStyle: CoreTextStyle(color: _kColorError),
      );

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.labelStyle?.fontSize, _kFontLabel);
      expect(effective.labelStyle?.fontWeight, _kWeightSemiBold); // theme
      expect(effective.labelStyle?.color, _kColorOnSurface);
      expect(effective.descriptionStyle?.color, _kColorOnSurface);
      expect(effective.errorStyle?.color, _kColorError); // widget
    });

    test('right-most non-null wins on each field', () {
      const a = CoreDatePickerStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
        descriptionStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      const b = CoreDatePickerStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontTitle),
      );
      const c = CoreDatePickerStyle(
        descriptionStyle: CoreTextStyle(fontSize: _kFontTitle),
      );

      final result = a.merge(b).merge(c);

      expect(result.labelStyle?.fontSize, _kFontTitle);
      expect(result.descriptionStyle?.fontSize, _kFontTitle);
    });

    test('popoverStyle / dialogStyle / calendarStyle merge recursively', () {
      const base = CoreDatePickerStyle(
        popoverStyle: CorePopoverStyle(
          panelStyle: CorePopupStyle(borderRadius: CoreBorderRadius.all(8)),
          placementOffset: 8,
        ),
        dialogStyle: CoreDialogStyle(
          panelBorderRadius: CoreBorderRadius.all(12),
        ),
        calendarStyle: CoreCalendarStyle(
          selectedColor: _kSelectedPrimary,
        ),
      );
      const override = CoreDatePickerStyle(
        popoverStyle: CorePopoverStyle(placementOffset: 12),
        calendarStyle: CoreCalendarStyle(
          selectedColor: _kSelectedSuccess,
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
      expect(merged.calendarStyle?.selectedColor, _kSelectedSuccess);
    });

    test('null nested style on base inherits from override', () {
      const base = CoreDatePickerStyle();
      const override = CoreDatePickerStyle(
        calendarStyle: CoreCalendarStyle(
          selectedColor: _kSelectedPrimary,
        ),
      );
      final merged = base.merge(override);
      expect(merged.calendarStyle?.selectedColor, _kSelectedPrimary);
    });
  });

  group('CoreDatePickerStyle equality', () {
    test('same fields → equal', () {
      const a = CoreDatePickerStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      const b = CoreDatePickerStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different calendarStyle → not equal', () {
      const a = CoreDatePickerStyle(
        calendarStyle: CoreCalendarStyle(selectedColor: _kBgSurface),
      );
      const b = CoreDatePickerStyle(
        calendarStyle: CoreCalendarStyle(selectedColor: _kBgError),
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreDatePickerStyle.copyWith', () {
    test('only-supplied fields override', () {
      const base = CoreDatePickerStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
        descriptionStyle: CoreTextStyle(color: _kColorOnSurface),
      );
      final copy = base.copyWith(
        errorStyle: const CoreTextStyle(color: _kColorError),
      );
      expect(copy.labelStyle?.fontSize, _kFontLabel);
      expect(copy.descriptionStyle?.color, _kColorOnSurface);
      expect(copy.errorStyle?.color, _kColorError);
    });

    test('preserves nested calendarStyle when not specified', () {
      const base = CoreDatePickerStyle(
        calendarStyle: CoreCalendarStyle(
          selectedColor: _kSelectedPrimary,
        ),
      );
      final copy = base.copyWith(
        labelStyle: const CoreTextStyle(fontSize: _kFontLabel),
      );
      expect(copy.labelStyle?.fontSize, _kFontLabel);
      expect(copy.calendarStyle?.selectedColor, _kSelectedPrimary);
    });
  });

  group('CoreDatePickerTheme', () {
    test('style passes through', () {
      const style = CoreDatePickerStyle(
        calendarStyle: CoreCalendarStyle(selectedColor: _kBgSurface),
      );
      const theme = CoreDatePickerTheme(style: style);
      expect(theme.style, style);
    });

    test('null style', () {
      const theme = CoreDatePickerTheme();
      expect(theme.style, isNull);
    });

    test('equality', () {
      const a = CoreDatePickerTheme(
        style: CoreDatePickerStyle(
          calendarStyle: CoreCalendarStyle(selectedColor: _kSelectedPrimary),
        ),
      );
      const b = CoreDatePickerTheme(
        style: CoreDatePickerStyle(
          calendarStyle: CoreCalendarStyle(selectedColor: _kSelectedPrimary),
        ),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
  group('CoreDatePickerStyle trigger look', () {
    test('the trigger default: pressed-only state layer', () {
      expect(
        CoreDatePickerStyle.defaultTriggerStyle.stateLayer,
        const CoreStateLayer(
          hover: CoreOpacity.opacity0,
          focus: CoreOpacity.opacity0,
          pressed: CoreOpacity.pressed,
        ),
      );
    });

    test('the trigger wrapper fills the axis, like every field trigger', () {
      expect(
        CoreDatePickerStyle.defaultPopoverStyle.triggerSizing,
        CorePopoverTriggerSizing.expand,
      );
      // The Button chrome is no longer the popover's trigger default.
      expect(CoreDatePickerStyle.defaultPopoverStyle.triggerStyle, isNull);
    });

    test('the error look still takes the focus edge from error', () {
      expect(
        CoreDatePickerStyle
            .defaultErrorTriggerStyle
            .focusOutlineStyle
            ?.borderColor,
        _kColorError,
      );
    });

    test('triggerStyle merges, copies and compares', () {
      const a = CoreDatePickerStyle(
        triggerStyle: CoreTextFieldStyle(borderWidth: 2),
      );
      const b = CoreDatePickerStyle(
        triggerStyle: CoreTextFieldStyle(height: 48),
      );
      final merged = a.merge(b);
      expect(merged.triggerStyle?.borderWidth, 2);
      expect(merged.triggerStyle?.height, 48);
      expect(
        a.copyWith(triggerStyle: b.triggerStyle).triggerStyle,
        b.triggerStyle,
      );
      expect(a, isNot(equals(b)));
      expect(
        a,
        equals(
          const CoreDatePickerStyle(
            triggerStyle: CoreTextFieldStyle(borderWidth: 2),
          ),
        ),
      );
    });

    test(
      'effectiveTriggerStyle folds the picker decisions under triggerStyle',
      () {
        const style = CoreDatePickerStyle(
          contentColor: _kSelectedPrimary,
          triggerStyle: CoreTextFieldStyle(borderWidth: 2),
        );
        final field = style.effectiveTriggerStyle;
        expect(field.valueStyle?.color, _kSelectedPrimary);
        expect(
          field.placeholderStyle?.color,
          CoreDatePickerStyle.defaultPlaceholderColor,
        );
        expect(field.borderWidth, 2);
        expect(
          field.stateLayer,
          CoreDatePickerStyle.defaultTriggerStyle.stateLayer,
        );
        expect(
          field.errorBorderColor,
          CoreDatePickerStyle.defaultErrorTriggerStyle.borderColor,
        );
        // No role of its own: the value is the field's Regular 14.
        expect(field.valueStyle?.token, isNull);
      },
    );

    test('an explicit valueTypography reaches value and placeholder', () {
      const role = CoreTextStyle.token(CoreTextStyles.labelLarge);
      final field = const CoreDatePickerStyle(
        valueTypography: role,
      ).effectiveTriggerStyle;
      expect(field.valueStyle?.token, role.token);
      expect(field.placeholderStyle?.token, role.token);
    });

    test('a disabled picker leaves the text colours to the field', () {
      final field = const CoreDatePickerStyle(
        contentColor: _kSelectedPrimary,
      ).effectiveDisabledTriggerStyle;
      expect(field.valueStyle, isNull);
      expect(field.placeholderStyle, isNull);
    });

    test('the deprecated errorTriggerStyle edge is the error edge, and '
        'triggerStyle outranks it', () {
      const edge = CoreColor.token(CoreColors.tertiary);
      const legacy = CoreDatePickerStyle(
        errorTriggerStyle: CoreButtonStyle(borderColor: edge),
      );
      expect(legacy.effectiveTriggerStyle.errorBorderColor, edge);
      final both = legacy.copyWith(
        triggerStyle: const CoreTextFieldStyle(errorBorderColor: _kColorError),
      );
      expect(both.effectiveTriggerStyle.errorBorderColor, _kColorError);
    });
  });
}
