String validatedCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''class ValidatedChainExample extends StatelessComponent {
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
}''',
    _ =>
      '''
class ValidatedDefaultExample extends StatelessComponent {
  const ValidatedDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(raw: {'width': '320px'}),
      [
        Validated(
          state: CoreValidationState.invalid,
          message: Text('필수 항목입니다.'),
          child: TextField(placeholder: Text('이름')),
        ),
      ],
    );
  }
}''',
  };
}
