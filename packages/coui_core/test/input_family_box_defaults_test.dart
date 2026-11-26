// FormattedInput and ObjectInput sit on the text field's lg row (#5831): one
// outer box owns the border / fill / focus, and the composed `TextField` is
// the `plain` variant on the `lg` row with no border or fill of its own.
// These pin the defaults both platforms read, and that every field this
// redesign added takes part in `merge` / `copyWith` / `==` / `hashCode`.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const CoreColor _custom = CoreColor.token(CoreColors.error);

void main() {
  group('FormattedInput defaults', () {
    test('the box is the lg row: 48 high, 12 corner, 14 inset, 8 gap', () {
      expect(CoreFormattedInputStyle.defaultHeight, CoreControlSize.heightLg);
      expect(
        CoreFormattedInputStyle.defaultBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius12),
      );
      expect(
        CoreFormattedInputStyle.defaultPadding,
        const CoreEdgeInsets.symmetric(horizontal: CoreSpace.space14),
      );
      expect(CoreFormattedInputStyle.defaultContentSpacing, CoreSpace.space8);
    });

    test('rests on outline-variant and hovers on outline', () {
      expect(
        CoreFormattedInputStyle.defaultBorderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(
        CoreFormattedInputStyle.defaultHoverBorderColor,
        const CoreColor.token(CoreColors.outline),
      );
    });

    test('disabled takes the three disabled tokens', () {
      expect(
        CoreFormattedInputStyle.defaultDisabledBackgroundColor,
        const CoreColor.token(CoreColors.disabledContainer),
      );
      expect(
        CoreFormattedInputStyle.defaultDisabledBorderColor,
        const CoreColor.token(CoreColors.disabledOutline),
      );
      expect(
        CoreFormattedInputStyle.defaultDisabledForegroundColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
    });

    test(
      'the composed field is plain on the lg row with no box of its own',
      () {
        expect(
          CoreFormattedInputStyle.defaultSegmentInputVariant,
          CoreTextFieldVariant.plain,
        );
        expect(
          CoreFormattedInputStyle.defaultSegmentInputSize,
          CoreComponentSize.lg,
        );
        const field = CoreFormattedInputStyle.defaultSegmentInputStyle;
        expect(field.backgroundColor, CoreColor.transparent);
        expect(field.borderWidth, 0);
        expect(field.padding, CoreEdgeInsets.zero);
        expect(field.minHeight, 0);
      },
    );

    test('the placeholder is the body face and states no colour', () {
      const field = CoreFormattedInputStyle.defaultSegmentInputStyle;
      expect(field.placeholderStyle!.token, CoreTextStyles.bodySmall);
      // A stated colour wins in every state, which would pin the placeholder
      // to one tone while disabled.
      expect(field.placeholderStyle!.color, isNull);
      expect(field.valueStyle!.token, CoreTextStyles.codeMd);
    });

    test('every new field takes part in merge / copyWith / == / hashCode', () {
      const base = CoreFormattedInputStyle();
      final filled = base.copyWith(
        hoverBorderColor: _custom,
        disabledForegroundColor: _custom,
        height: 40,
        contentSpacing: 4,
      );
      expect(filled, isNot(base));
      expect(filled.hashCode, isNot(base.hashCode));
      final merged = base.merge(filled);
      expect(merged, filled);
      expect(merged.hoverBorderColor, _custom);
      expect(merged.disabledForegroundColor, _custom);
      expect(merged.height, 40);
      expect(merged.contentSpacing, 4);
    });
  });

  group('ObjectInput defaults', () {
    test('the box is the lg row: 48 high, 12 corner, 14 inset, 4 gap', () {
      expect(CoreObjectInputStyle.defaultHeight, CoreControlSize.heightLg);
      expect(
        CoreObjectInputStyle.defaultBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius12),
      );
      expect(
        CoreObjectInputStyle.defaultPadding,
        const CoreEdgeInsets.symmetric(horizontal: CoreSpace.space14),
      );
      expect(CoreObjectInputStyle.defaultFieldSpacing, CoreSpace.space4);
    });

    test('rests on outline-variant and hovers on outline', () {
      expect(
        CoreObjectInputStyle.defaultBorderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(
        CoreObjectInputStyle.defaultHoverBorderColor,
        const CoreColor.token(CoreColors.outline),
      );
    });

    test('disabled takes the disabled tokens on fill, edge and separator', () {
      expect(
        CoreObjectInputStyle.defaultDisabledBackgroundColor,
        const CoreColor.token(CoreColors.disabledContainer),
      );
      expect(
        CoreObjectInputStyle.defaultDisabledBorderColor,
        const CoreColor.token(CoreColors.disabledOutline),
      );
      expect(
        CoreObjectInputStyle.defaultDisabledSeparatorColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
    });

    test('the separator is quiet and tight', () {
      expect(
        CoreObjectInputStyle.defaultSeparatorColor,
        const CoreColor.token(CoreColors.onSurfaceSubtle),
      );
      expect(
        CoreObjectInputStyle.defaultSeparatorPadding,
        const CoreEdgeInsets.symmetric(horizontal: CoreSpace.space2),
      );
    });

    test('the field width buckets are 28 / 28 / 48', () {
      expect(CoreObjectInputStyle.defaultShortFieldMaxWidth, CoreSpace.space28);
      expect(
        CoreObjectInputStyle.defaultMediumFieldMaxWidth,
        CoreSpace.space28,
      );
      expect(CoreObjectInputStyle.defaultLongFieldMaxWidth, CoreSpace.space48);
    });

    test(
      'the composed field is plain on the lg row with no box of its own',
      () {
        expect(
          CoreObjectInputStyle.defaultFieldInputVariant,
          CoreTextFieldVariant.plain,
        );
        expect(
          CoreObjectInputStyle.defaultFieldInputSize,
          CoreComponentSize.lg,
        );
        const field = CoreObjectInputStyle.defaultFieldInputStyle;
        expect(field.backgroundColor, CoreColor.transparent);
        expect(field.borderWidth, 0);
        expect(field.placeholderStyle!.token, CoreTextStyles.bodyLarge);
        expect(field.placeholderStyle!.color, isNull);
      },
    );

    test('every new field takes part in merge / copyWith / == / hashCode', () {
      const base = CoreObjectInputStyle();
      final filled = base.copyWith(
        disabledBackgroundColor: _custom,
        disabledBorderColor: _custom,
        disabledSeparatorColor: _custom,
        height: 40,
        fieldSpacing: 8,
      );
      expect(filled, isNot(base));
      expect(filled.hashCode, isNot(base.hashCode));
      final merged = base.merge(filled);
      expect(merged, filled);
      expect(merged.disabledBackgroundColor, _custom);
      expect(merged.disabledBorderColor, _custom);
      expect(merged.disabledSeparatorColor, _custom);
      expect(merged.height, 40);
      expect(merged.fieldSpacing, 8);
    });
  });
}
