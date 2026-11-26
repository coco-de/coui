/// Returns a Web code snippet string for the FormattedInput component.
String formattedInputCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class FormattedInputChainExample extends StatelessComponent {
  const FormattedInputChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        FormattedInput.phone(
          onChanged: (value) => print('Phone: \$value'),
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        FormattedInput.phone(
          onChanged: (value) => print('Phone: \$value'),
        ).withStyle(
          const CoreFormattedInputStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}''',
    'credit-card' =>
      '''
class FormattedInputCreditCardExample extends StatelessComponent {
  const FormattedInputCreditCardExample({super.key});

  @override
  Component build(BuildContext context) {
    return FormattedInput.creditCard(
      onChanged: (value) => print('Card: \$value'),
    );
  }
}''',
    'date' =>
      '''
class FormattedInputDateExample extends StatelessComponent {
  const FormattedInputDateExample({super.key});

  @override
  Component build(BuildContext context) {
    return FormattedInput.date(
      onChanged: (value) => print('Date: \$value'),
    );
  }
}''',
    'korean-phone' =>
      '''
class FormattedInputKoreanPhoneExample extends StatelessComponent {
  const FormattedInputKoreanPhoneExample({super.key});

  @override
  Component build(BuildContext context) {
    return FormattedInput.koreanPhone(
      onChanged: (value) => print('Phone: \$value'),
    );
  }
}''',
    'verify' =>
      '''
class FormattedInputVerifyExample extends StatelessComponent {
  const FormattedInputVerifyExample({super.key});

  @override
  Component build(BuildContext context) {
    return FormattedInput.koreanPhone(
      onChanged: (value) => print('Phone: \$value'),
      trailing: Button(
        onPressed: () => print('Send verification code'),
        variant: .plain,
        size: .sm,
        child: Text('인증번호 보내기').labelMedium,
      ),
    );
  }
}''',
    _ =>
      '''
class FormattedInputDefaultExample extends StatelessComponent {
  const FormattedInputDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return FormattedInput.phone(
      onChanged: (value) => print('Phone: \$value'),
    );
  }
}''',
  };
}
