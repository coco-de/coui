/// Returns a Flutter code snippet string for the Hidden component.
String hiddenCode(String? variant) {
  return '''
class HiddenDefaultExample extends StatefulWidget {
  const HiddenDefaultExample({super.key});

  @override
  State<HiddenDefaultExample> createState() => _HiddenDefaultExampleState();
}

class _HiddenDefaultExampleState extends State<HiddenDefaultExample> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () => setState(() => _hidden = !_hidden),
          child: Text(_hidden ? '보기' : '숨기기'),
        ),
        Gap.space12(),
        Hidden(
          hidden: _hidden,
          child: Container(
            padding: const CoreEdgeInsets.all(CoreSpace.space16).toValue(geometry: Theme.of(context).geometry),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer.toValue(),
              borderRadius: BorderRadius.circular(CoreRadius.radius16),
            ),
            child: Text(
              '켜고 끌 수 있는 내용',
              style: theme.typography.bodyMedium.toValue(theme: theme).copyWith(
                color: theme.colorScheme.onSurface.toValue(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}''';
}
