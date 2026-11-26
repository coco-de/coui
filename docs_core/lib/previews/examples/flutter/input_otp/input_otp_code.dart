/// Returns a Flutter code snippet string for the InputOtp component.
String inputOtpCode(String? variant) {
  return switch (variant) {
    'editable' =>
      '''
class InputOtpEditableExample extends StatelessWidget {
  const InputOtpEditableExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const InputOtp(
      length: 6,
      initialValue: [49, 50, 51],
      allowCellEditing: true,
    );
  }
}''',
    'chain' =>
      '''
class InputOtpChainExample extends StatelessWidget {
  const InputOtpChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        InputOtp(length: 6, onCompleted: (_) {}).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        InputOtp(length: 6, onCompleted: (_) {}).withStyle(
          const CoreInputOtpStyle(
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
    'lg' =>
      '''
class InputOtpLgExample extends StatelessWidget {
  const InputOtpLgExample({super.key});

  @override
  Widget build(BuildContext context) {
    return InputOtp(
      length: 6,
      size: CoreInputOtpSize.lg,
      onCompleted: (_) {},
    );
  }
}''',
    _ =>
      '''
class InputOtpDefaultExample extends StatelessWidget {
  const InputOtpDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return InputOtp(
      length: 6,
      onCompleted: (_) {},
    );
  }
}''',
  };
}
