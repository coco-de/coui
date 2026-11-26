/// Returns a Flutter code snippet string for the Fieldset component.
String fieldsetCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class FieldsetChainExample extends StatelessWidget {
  const FieldsetChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Fixed-width wrappers so the preview matches Web's
    // `w-\${CoreSpace.scale.space256}` wrapper — the docs preview
    // pane is already centred, we just need a known cross-axis
    // size to keep both platforms visually identical.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        SizedBox(
          width: CoreSpace.space256,
          child: Fieldset(
            legend: const Text('계정'),
            children: [
              TextField(
                autofillHints: const [AutofillHints.name],
                placeholder: const Text('이름'),
              ),
              TextField(
                autofillHints: const [AutofillHints.email],
                placeholder: const Text('이메일'),
              ),
            ],
          ).radius16.primary,
        ),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        SizedBox(
          width: CoreSpace.space256,
          child:
              Fieldset(
                legend: const Text('계정'),
                children: [
                  TextField(
                    autofillHints: const [AutofillHints.name],
                    placeholder: const Text('이름'),
                  ),
                  TextField(
                    autofillHints: const [AutofillHints.email],
                    placeholder: const Text('이메일'),
                  ),
                ],
              ).withStyle(
                const CoreFieldsetStyle(
                  backgroundColor: CoreColor.token(CoreColors.tertiary),
                  borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
                  fieldSpacing: CoreSpace.space12,
                  padding: CoreEdgeInsets.symmetric(
                    horizontal: CoreSpace.space24,
                    vertical: CoreSpace.space8,
                  ),
                ),
              ),
        ),
      ],
    );
  }
}''',
    'outlined' =>
      '''
class FieldsetOutlinedExample extends StatelessWidget {
  const FieldsetOutlinedExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space256,
      child: Fieldset(
        variant: CoreFieldsetVariant.outlined,
        legend: const Text('계정'),
        description: const Text('로그인에 쓰는 정보예요.'),
        children: [
          TextField(
            autofillHints: const [AutofillHints.name],
            placeholder: const Text('이름'),
          ),
          TextField(
            autofillHints: const [AutofillHints.email],
            placeholder: const Text('이메일'),
          ),
        ],
      ),
    );
  }
}''',
    'plain' =>
      '''
class FieldsetPlainExample extends StatelessWidget {
  const FieldsetPlainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space256,
      child: Fieldset(
        variant: CoreFieldsetVariant.plain,
        legend: const Text('계정'),
        description: const Text('로그인에 쓰는 정보예요.'),
        children: [
          TextField(
            autofillHints: const [AutofillHints.name],
            placeholder: const Text('이름'),
          ),
          TextField(
            autofillHints: const [AutofillHints.email],
            placeholder: const Text('이메일'),
          ),
        ],
      ),
    );
  }
}''',
    _ =>
      '''
class FieldsetDefaultExample extends StatelessWidget {
  const FieldsetDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space256,
      child: Fieldset(
        legend: const Text('계정'),
        description: const Text('로그인에 쓰는 정보예요.'),
        children: [
          TextField(
            autofillHints: const [AutofillHints.name],
            placeholder: const Text('이름'),
          ),
          TextField(
            autofillHints: const [AutofillHints.email],
            placeholder: const Text('이메일'),
          ),
        ],
      ),
    );
  }
}''',
  };
}
