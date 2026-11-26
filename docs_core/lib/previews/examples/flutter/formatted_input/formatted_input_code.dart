/// Returns a Flutter code snippet string for the FormattedInput component.
String formattedInputCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class FormattedInputChainExample extends StatelessWidget {
  const FormattedInputChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        FormattedInput.phone(
          onChanged: (value) => debugPrint('Phone: \$value'),
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        FormattedInput.phone(
          onChanged: (value) => debugPrint('Phone: \$value'),
        ).withStyle(
          const CoreFormattedInputStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
          ),
        ),
      ],
    );
  }
}''',
    'credit-card' =>
      '''
class FormattedInputCreditCardExample extends StatelessWidget {
  const FormattedInputCreditCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FormattedInput.creditCard(
      onChanged: (value) => debugPrint('Card: \$value'),
    );
  }
}''',
    'date' =>
      '''
class FormattedInputDateExample extends StatelessWidget {
  const FormattedInputDateExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FormattedInput.date(
      onChanged: (value) => debugPrint('Date: \$value'),
    );
  }
}''',
    'korean-phone' =>
      '''
class FormattedInputKoreanPhoneExample extends StatelessWidget {
  const FormattedInputKoreanPhoneExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FormattedInput.koreanPhone(
      onChanged: (value) => debugPrint('Phone: \$value'),
    );
  }
}''',
    'verify' =>
      '''
class FormattedInputVerifyExample extends StatelessWidget {
  const FormattedInputVerifyExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FormattedInput.koreanPhone(
      onChanged: (value) => debugPrint('Phone: \$value'),
      trailing: Button(
        onPressed: () => debugPrint('Send verification code'),
        variant: .plain,
        size: .sm,
        child: Text('인증번호 보내기').labelMedium,
      ),
    );
  }
}''',
    _ =>
      '''
class FormattedInputDefaultExample extends StatelessWidget {
  const FormattedInputDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FormattedInput.phone(
      onChanged: (value) => debugPrint('Phone: \$value'),
    );
  }
}''',
  };
}
