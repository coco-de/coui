String clickableCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class ClickableChainExample extends StatelessWidget {
  const ClickableChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Clickable(
          onPressed: () {},
          child: Card(child: Text('클릭 가능한 영역').bodyMedium),
        )
        .withStyle(
          const CoreClickableStyle(
            disabledOpacity: CoreOpacity.opacity30,
            duration: Duration(milliseconds: CoreDuration.fast),
            pressDuration: Duration(milliseconds: CoreDuration.instant),
          ),
        )
        .radius16;
  }
}''',
    _ =>
      '''
class ClickableDefaultExample extends StatelessWidget {
  const ClickableDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Clickable(
      onPressed: () {},
      child: Card(child: Text('클릭 가능한 영역').bodyMedium),
    );
  }
}''',
  };
}
