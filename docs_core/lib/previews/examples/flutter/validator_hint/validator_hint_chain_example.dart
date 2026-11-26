import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreValidatorHintStyle] slot without constructing the
/// widget from scratch.
class ValidatorHintChainExample extends StatelessWidget {
  const ValidatorHintChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ValidatorHint(
      message: const Text('비밀번호는 8자 이상이어야 합니다.'),
      type: CoreValidatorHintType.error,
    ).withStyle(
      const CoreValidatorHintStyle(
        accentColor: CoreColor.token(CoreColors.warning),
        messageTextStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
        iconStyle: CoreIconStyle(size: CoreIconSize.size16),
        iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space12),
      ),
    );
  }
}
