import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'number field merges nested typography and placeholder independently',
    () {
      const base = CorePhoneInputStyle(
        numberFieldStyle: CoreTextFieldStyle(
          valueStyle: CoreTextStyle(fontSize: 17, fontWeight: 600),
        ),
        searchFieldStyle: CoreTextFieldStyle(minHeight: 40),
      );
      const override = CorePhoneInputStyle(
        numberFieldStyle: CoreTextFieldStyle(
          valueStyle: CoreTextStyle(lineHeight: 1.4),
          placeholderStyle: CoreTextStyle(color: CoreColor(0xFF123456)),
        ),
      );
      final merged = base.merge(override);
      expect(merged.numberFieldStyle?.valueStyle?.fontSize, 17);
      expect(merged.numberFieldStyle?.valueStyle?.fontWeight, 600);
      expect(merged.numberFieldStyle?.valueStyle?.lineHeight, 1.4);
      expect(merged.searchFieldStyle, base.searchFieldStyle);
      expect(merged.copyWith(), merged);
      expect(merged.copyWith().hashCode, merged.hashCode);
      expect(
        base,
        isNot(base.copyWith(numberFieldStyle: const CoreTextFieldStyle())),
      );
      expect(const CorePhoneInputStyle().numberFieldStyle, isNull);
      // The chromeless field, reading at the dial code's size.
      expect(
        CorePhoneInputStyle.defaultNumberFieldStyle,
        CorePhoneInputStyle.chromelessFieldStyle.merge(
          const CoreTextFieldStyle(
            baseTextStyle: CoreTextStyle.token(CoreTextStyles.bodyLarge),
          ),
        ),
      );
    },
  );
}
