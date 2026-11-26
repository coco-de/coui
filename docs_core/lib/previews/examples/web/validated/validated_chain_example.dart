import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreValidatedStyle] slot without constructing the
/// widget from scratch.
class ValidatedChainExample extends StatelessComponent {
  const ValidatedChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(raw: {'width': '320px'}),
      [
        Validated(
          state: CoreValidationState.invalid,
          message: Text('필수 항목입니다.'),
          child: TextField(placeholder: Text('이름')),
        ).withStyle(
          const CoreValidatedStyle(
            fieldMessageGapStyle: CoreGapStyle(size: CoreSpace.space16),
            validatorHintStyle: CoreValidatorHintStyle(
              accentColor: CoreColor.token(CoreColors.warning),
              iconStyle: CoreIconStyle(size: CoreIconSize.size16),
              iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
            ),
          ),
        ),
      ],
    );
  }
}
