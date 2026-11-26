/// Returns a Flutter code snippet string for the ValidationBadge component.
String validationBadgeCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''class ValidationBadgeChainExample extends StatelessWidget {
  const ValidationBadgeChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const ValidationBadge(
      label: '8자 이상',
      state: CoreValidationState.valid,
    ).withStyle(
      const CoreValidationBadgeStyle(
        validBackgroundColor: CoreColor.token(
          CoreColors.primary,
          opacity: CoreOpacity.opacity10,
        ),
        validBorderColor: CoreColor.token(CoreColors.primary),
        validLabelTextStyle: CoreTextStyle.token(
          CoreTextStyles.labelMedium,
          color: CoreColor.token(CoreColors.primary),
        ),
        borderWidth: CoreStrokeWidth.stroke2,
        iconStyle: CoreIconStyle(
          size: CoreIconSize.size16,
          color: CoreColor.token(CoreColors.primary),
        ),
        iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
      ),
    );
  }
}''',
    'pending' =>
      '''
class ValidationBadgePendingExample extends StatelessWidget {
  const ValidationBadgePendingExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const ValidationBadge(
      label: '입력 대기 중',
      state: CoreValidationState.pending,
    );
  }
}''',
    'invalid' =>
      '''
class ValidationBadgeInvalidExample extends StatelessWidget {
  const ValidationBadgeInvalidExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const ValidationBadge(
      label: '숫자 포함',
      state: CoreValidationState.invalid,
    );
  }
}''',
    'medium' =>
      '''
class ValidationBadgeMediumExample extends StatelessWidget {
  const ValidationBadgeMediumExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const ValidationBadge(
      label: '대문자 1개 이상',
      state: CoreValidationState.valid,
      size: CoreValidationBadgeSize.medium,
    );
  }
}''',
    _ =>
      '''
class ValidationBadgeDefaultExample extends StatelessWidget {
  const ValidationBadgeDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const ValidationBadge(
      label: '8자 이상',
      state: CoreValidationState.valid,
    );
  }
}''',
  };
}
