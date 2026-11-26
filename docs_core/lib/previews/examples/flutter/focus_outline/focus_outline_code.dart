String focusOutlineCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class FocusOutlineChainExample extends StatelessWidget {
  const FocusOutlineChainExample({super.key});

  @override
  Widget build(BuildContext context) {
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
class FocusOutlineDefaultExample extends StatelessWidget {
  const FocusOutlineDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FocusOutline(
      focused: true,
      child: Card(child: Text('포커스된 요소').bodyMedium),
    );
  }
}''',
  };
}
