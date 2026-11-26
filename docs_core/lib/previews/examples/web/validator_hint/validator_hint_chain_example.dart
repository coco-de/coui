import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreValidatorHintStyle] slot without constructing the
/// widget from scratch.
class ValidatorHintChainExample extends StatelessComponent {
  const ValidatorHintChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return ValidatorHint(
      message: Text('비밀번호는 8자 이상이어야 합니다.'),
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
