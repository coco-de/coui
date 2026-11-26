String formFieldCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class FormFieldChainExample extends StatelessWidget {
  const FormFieldChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child:
          FormField(
            label: '이메일',
            description: '회사 이메일을 입력하세요.',
            required: true,
            child: TextField(
              autofillHints: const [AutofillHints.email],
              placeholder: const Text('you@company.com'),
            ),
          ).withStyle(
            const CoreFormFieldStyle(
              labelInputGapStyle: CoreGapStyle(size: CoreSpace.space24),
              formLabelStyle: CoreFormLabelStyle(
                labelStyle: CoreTextStyle.token(
                  CoreTextStyles.titleSmall,
                  color: CoreColor.token(CoreColors.primary),
                ),
                requiredColor: CoreColor.token(CoreColors.tertiary),
                requiredIndicatorGapStyle: CoreGapStyle(
                  size: CoreSpace.space8,
                ),
              ),
              descriptionTextStyle: CoreTextStyle.token(
                CoreTextStyles.labelSmall,
                color: CoreColor.token(CoreColors.onSurfaceVariant),
              ),
            ),
          ),
    );
  }
}
''',
    _ =>
      '''
class FormFieldDefaultExample extends StatelessWidget {
  const FormFieldDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: FormField(
        label: '이메일',
        description: '회사 이메일을 입력하세요.',
        required: true,
        child: TextField(
            autofillHints: const [AutofillHints.email],
            placeholder: const Text('you@company.com'),
          ),
      ),
    );
  }
}''',
  };
}
