/// Returns a Web code snippet string for the InputOtp component.
String inputOtpCode(String? variant) {
  return switch (variant) {
    'editable' =>
      '''
class InputOtpEditableExample extends StatelessComponent {
  const InputOtpEditableExample({super.key});

  @override
  Component build(BuildContext context) {
    return const InputOtp(
      length: 6,
      initialValue: '123',
      allowCellEditing: true,
    );
  }
}''',
    'chain' =>
      '''
class InputOtpChainExample extends StatelessComponent {
  const InputOtpChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        InputOtp(length: 6).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        InputOtp(length: 6).withStyle(
          const CoreInputOtpStyle(
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
    'lg' =>
      '''
class InputOtpLgExample extends StatelessComponent {
  const InputOtpLgExample({super.key});

  @override
  Component build(BuildContext context) {
    return InputOtp(length: 6, size: CoreInputOtpSize.lg);
  }
}''',
    _ =>
      '''
class InputOtpDefaultExample extends StatelessComponent {
  const InputOtpDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return InputOtp(length: 6);
  }
}''',
  };
}
