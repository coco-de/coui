import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The error line under a DatePicker: 12 px (the helper-text role) and, once
/// the picker is disabled, `disabledContent` instead of `error`.
void main() {
  group('CoreDatePickerStyle error text', () {
    test('the error line is the bodyXs role, not bodySmall', () {
      expect(
        CoreDatePickerStyle.defaultErrorStyle.token,
        CoreTextStyles.bodyXs,
      );
      expect(CoreTypography.coui.bodyXs.fontSize, 12);
      // The role carries its own tracking; no fontSize overlay rides on it.
      expect(CoreDatePickerStyle.defaultErrorStyle.fontSize, isNull);
    });

    test('the description line is the same bodyXs role as the error line', () {
      expect(
        CoreDatePickerStyle.defaultDescriptionStyle.token,
        CoreTextStyles.bodyXs,
      );
      expect(
        CoreDatePickerStyle.defaultDescriptionStyle,
        CoreDatePickerStyle.defaultErrorStyle,
      );
      expect(CoreDatePickerStyle.defaultDescriptionStyle.fontSize, isNull);
      // Same role as TextField's description line.
      expect(
        CoreTextFieldStyle.defaultDescriptionStyle.token,
        CoreDatePickerStyle.defaultDescriptionStyle.token,
      );
      // Only the colour tells the two lines apart.
      expect(
        CoreDatePickerStyle.defaultDescriptionColor,
        isNot(CoreDatePickerStyle.defaultErrorColor),
      );
    });

    test('a disabled picker takes disabledContent, an enabled one error', () {
      expect(
        CoreDatePickerStyle.defaultErrorColor,
        const CoreColor.token(CoreColors.error),
      );
      expect(
        CoreDatePickerStyle.defaultDisabledErrorColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
    });

    test('disabledErrorColor round-trips merge, copyWith, ==, hashCode', () {
      const tertiary = CoreColor.token(CoreColors.tertiary);
      const a = CoreDatePickerStyle(disabledErrorColor: tertiary);
      expect(const CoreDatePickerStyle().merge(a).disabledErrorColor, tertiary);
      expect(a.merge(const CoreDatePickerStyle()).disabledErrorColor, tertiary);
      expect(
        const CoreDatePickerStyle().copyWith(disabledErrorColor: tertiary),
        a,
      );
      expect(a.hashCode, isNot(const CoreDatePickerStyle().hashCode));
      expect(a, isNot(const CoreDatePickerStyle()));
    });

    test('the description line is onSurfaceSubtle, as TextField states it', () {
      expect(
        CoreDatePickerStyle.defaultDescriptionColor,
        const CoreColor.token(CoreColors.onSurfaceSubtle),
      );
      expect(
        CoreDatePickerStyle.defaultDescriptionColor,
        CoreTextFieldStyle.defaultDescriptionColor,
      );
    });

    test('a disabled description takes disabledContent, like the error', () {
      expect(
        CoreDatePickerStyle.defaultDisabledDescriptionColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
      expect(
        CoreDatePickerStyle.defaultDisabledDescriptionColor,
        CoreDatePickerStyle.defaultDisabledErrorColor,
      );
    });

    test(
      'disabledDescriptionColor round-trips merge, copyWith, ==, hashCode',
      () {
        const tertiary = CoreColor.token(CoreColors.tertiary);
        const a = CoreDatePickerStyle(disabledDescriptionColor: tertiary);
        expect(
          const CoreDatePickerStyle().merge(a).disabledDescriptionColor,
          tertiary,
        );
        expect(
          a.merge(const CoreDatePickerStyle()).disabledDescriptionColor,
          tertiary,
        );
        expect(
          const CoreDatePickerStyle().copyWith(
            disabledDescriptionColor: tertiary,
          ),
          a,
        );
        expect(a.hashCode, isNot(const CoreDatePickerStyle().hashCode));
        expect(a, isNot(const CoreDatePickerStyle()));
      },
    );
  });
}
