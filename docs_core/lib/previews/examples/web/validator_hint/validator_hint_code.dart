String validatorHintCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''class ValidatorHintChainExample extends StatelessComponent {
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
}''',
    _ =>
      '''
class ValidatorHintDefaultExample extends StatelessComponent {
  const ValidatorHintDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return ValidatorHint(
      message: Text('비밀번호는 8자 이상이어야 합니다.'),
      type: CoreValidatorHintType.error,
    );
  }
}''',
  };
}
