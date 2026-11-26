String subfocusCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class SubfocusChainExample extends StatelessWidget {
  const SubfocusChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SubfocusScope(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: Theme.of(context).geometry.space(CoreSpace.space8),
        children: [
          Subfocus(
            focusId: 'a',
            child: Card(child: Text('항목 A (↑↓ 키로 이동)').bodyMedium),
          ).withStyle(
            const CoreSubfocusStyle(
              focusRingRadius: CoreBorderRadius.all(CoreRadius.radius16),
            ),
          ),
          Subfocus(
            focusId: 'b',
            child: Card(child: Text('항목 B').bodyMedium),
          ),
          Subfocus(
            focusId: 'c',
            child: Card(child: Text('항목 C').bodyMedium),
          ),
        ],
      ),
    );
  }
}''',
    _ =>
      '''
class SubfocusScopeDefaultExample extends StatelessWidget {
  const SubfocusScopeDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SubfocusScope(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: Theme.of(context).geometry.space(CoreSpace.space8),
        children: [
          Subfocus(
            focusId: 'a',
            child: Card(child: Text('항목 A (↑↓ 키로 이동)').bodyMedium),
          ),
          Subfocus(
            focusId: 'b',
            child: Card(child: Text('항목 B').bodyMedium),
          ),
          Subfocus(
            focusId: 'c',
            child: Card(child: Text('항목 C').bodyMedium),
          ),
        ],
      ),
    );
  }
}''',
  };
}
