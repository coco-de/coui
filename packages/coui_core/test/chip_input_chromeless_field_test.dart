// The ChipInput frame owns the boundary — border, fill and the focus ring —
// so the `TextField` composed inside it is chromeless. A chromeless field
// that leaves its focus border on draws a second, primary, box around the
// line being typed on, inside the frame's own ring.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreChipInputStyle.chromelessFieldStyle', () {
    const field = CoreChipInputStyle.chromelessFieldStyle;

    test('draws no focus border of its own', () {
      expect(field.focusBorderColor, CoreColor.transparent);
    });

    test('draws no inner focus ring either', () {
      expect(field.focusOutlineStyle?.borderColor, CoreColor.transparent);
      expect(field.focusOutlineStyle?.borderWidth, 0);
    });

    test('is the same recipe the other chromeless compositions state', () {
      // Command and PhoneInput compose a `plain` field the same way.
      expect(
        CorePhoneInputStyle.chromelessFieldStyle.focusBorderColor,
        field.focusBorderColor,
      );
    });
  });
}
