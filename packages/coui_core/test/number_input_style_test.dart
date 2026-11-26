import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreNumberInputStyle caret', () {
    // #5762 — the designer's NumberInput caret: 2 wide, corner 2, no gap
    // after the value, the value's line box tall, in `primary`. NumberInput
    // composes a TextField and forwards `fieldStyle` raw, so the caret's one
    // source is the TextField defaults; NumberInput states none of it.
    test('the composed field states no caret of its own', () {
      const field = CoreNumberInputStyle.defaultFieldStyle;
      expect(field.cursorWidth, isNull);
      expect(field.cursorRadius, isNull);
      expect(field.cursorColor, isNull);
      // Null height is the host's line box — the value role's.
      expect(field.cursorHeight, isNull);
    });

    test('the TextField defaults it inherits are the designer values', () {
      expect(CoreTextFieldStyle.defaultCursorWidth, 2);
      expect(
        CoreTextFieldStyle.defaultCursorRadius,
        const CoreBorderRadius.all(2),
      );
      expect(
        CoreTextFieldStyle.defaultCursorColor,
        const CoreColor.token(CoreColors.primary),
      );
    });

    test("the caret's line box is the value role's", () {
      // The value is `bodyMedium` at the role's own 150% — 14 × 1.5 = 21.
      expect(
        CoreNumberInputStyle.defaultFieldStyle.valueStyle,
        const CoreTextStyle.token(CoreTextStyles.bodyMedium),
      );
      final role = CoreTypography.coui.bodyMedium;
      expect(role.lineHeight, CoreLineHeight.h150);
      expect(role.fontSize! * role.lineHeight!, closeTo(21, 1e-9));
    });

    test('no field row lays a line height over the value role', () {
      // Every TextField row reads its role as it is, so the value merged
      // over the row keeps the role's own line box.
      for (final size in CoreNumberInputSize.values) {
        final value = CoreTextFieldStyle
            .defaultsBySize[size.toComponentSize()]!
            .baseTextStyle!
            .merge(CoreNumberInputStyle.defaultFieldStyle.valueStyle);
        expect(value.token, CoreTextStyles.bodyMedium, reason: '$size');
        expect(value.lineHeight, isNull, reason: '$size');
        expect(value.lineHeightPx, isNull, reason: '$size');
      }
    });

    test('the box widths are 90 · 114 · 138', () {
      expect(CoreNumberInputStyle.widthAt(CoreNumberInputSize.sm), 90);
      expect(CoreNumberInputStyle.widthAt(CoreNumberInputSize.md), 114);
      expect(CoreNumberInputStyle.widthAt(CoreNumberInputSize.lg), 138);
      for (final size in CoreNumberInputSize.values) {
        expect(
          CoreNumberInputStyle.defaultsBySize[size]!.width,
          CoreNumberInputStyle.widthAt(size),
        );
      }
    });
  });
}
