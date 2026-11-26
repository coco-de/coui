/// Returns a Flutter code snippet string for the PhoneInput component.
String phoneInputCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class PhoneInputChainExample extends StatelessWidget {
  const PhoneInputChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        const PhoneInput(placeholder: '전화번호를 입력해 주세요').radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        const PhoneInput(placeholder: '직접 지정').withStyle(
          const CorePhoneInputStyle(
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
    _ =>
      '''
class PhoneInputDefaultExample extends StatelessWidget {
  const PhoneInputDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const PhoneInput(placeholder: '전화번호를 입력해 주세요');
  }
}''',
  };
}
