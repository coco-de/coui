/// Returns a Web code snippet string for the Label component.
String labelCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class LabelChainExample extends StatelessComponent {
  const LabelChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Label(text: '이메일', isRequired: true).withStyle(
      const CoreLabelStyle(
        textStyle: CoreTextStyle.token(
          CoreTextStyles.titleMedium,
          color: CoreColor.token(CoreColors.primary),
        ),
        requiredColor: CoreColor.token(CoreColors.tertiary),
        labelRequiredGapStyle: CoreGapStyle(size: CoreSpace.space12),
        disabledOpacity: CoreOpacity.opacity50,
      ),
    );
  }
}
''',
    'required' =>
      '''
class LabelRequiredExample extends StatelessComponent {
  const LabelRequiredExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Label(text: '이메일', isRequired: true);
  }
}''',
    'with-icon' =>
      '''
class LabelWithIconExample extends StatelessComponent {
  const LabelWithIconExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Label(
      text: '이메일',
      icon: Icon(LucideIcons.mail),
    );
  }
}''',
    'disabled' =>
      '''
class LabelDisabledExample extends StatelessComponent {
  const LabelDisabledExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Label(text: '이메일', disabled: true);
  }
}''',
    _ =>
      '''
class LabelDefaultExample extends StatelessComponent {
  const LabelDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Label(text: '이메일');
  }
}''',
  };
}
