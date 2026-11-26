String formLabelCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class FormLabelChainExample extends StatelessWidget {
  const FormLabelChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FormLabel(
      label: const Text('이메일'),
      isRequired: true,
    ).withStyle(
      const CoreFormLabelStyle(
        labelStyle: CoreTextStyle.token(
          CoreTextStyles.titleMedium,
          color: CoreColor.token(CoreColors.primary),
        ),
        requiredColor: CoreColor.token(CoreColors.tertiary),
        requiredIndicatorGapStyle: CoreGapStyle(size: CoreSpace.space12),
      ),
    );
  }
}
''',
    _ =>
      '''
class FormLabelDefaultExample extends StatelessWidget {
  const FormLabelDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FormLabel(label: const Text('이메일'), isRequired: true);
  }
}''',
  };
}
