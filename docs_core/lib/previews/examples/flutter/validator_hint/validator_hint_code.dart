String validatorHintCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''class ValidatorHintChainExample extends StatelessWidget {
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
}''',
    _ =>
      '''
class ValidatorHintDefaultExample extends StatelessWidget {
  const ValidatorHintDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ValidatorHint(
      message: const Text('비밀번호는 8자 이상이어야 합니다.'),
      type: CoreValidatorHintType.error,
    );
  }
}''',
  };
}
