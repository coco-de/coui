import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreValidatedStyle] slot without constructing the
/// widget from scratch.
class ValidatedChainExample extends StatelessWidget {
  const ValidatedChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child:
          Validated(
            state: CoreValidationState.invalid,
            message: const Text('필수 항목입니다.'),
            child: TextField(placeholder: const Text('이름')),
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
    );
  }
}
