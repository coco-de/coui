String focusOutlineCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class FocusOutlineChainExample extends StatelessComponent {
  const FocusOutlineChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return FocusOutline(
          focused: true,
          child: Card(child: Text('포커스된 요소').bodyMedium),
        )
        .withStyle(
          const CoreFocusOutlineStyle(
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderWidth: CoreStrokeWidth.stroke3,
            duration: Duration(milliseconds: CoreDuration.fast),
          ),
        )
        .radius16;
  }
}''',
    _ =>
      '''
class FocusOutlineDefaultExample extends StatelessComponent {
  const FocusOutlineDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return FocusOutline(
      focused: true,
      child: Card(child: Text('포커스된 요소').bodyMedium),
    );
  }
}''',
  };
}
