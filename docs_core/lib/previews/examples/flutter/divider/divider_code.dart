/// Code snippet for [Divider] Flutter examples.
String dividerCode(String? variant) {
  return switch (variant) {
    'chain' => _chainCode,
    'vertical' => _verticalCode,
    'with-child' => _withChildCode,
    _ => _defaultCode,
  };
}

const _chainCode = '''
class DividerChainExample extends StatelessWidget {
  const DividerChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider().withStyle(
      const CoreDividerStyle(
        color: CoreColor.token(CoreColors.primary),
        thickness: CoreStrokeWidth.stroke4,
        indent: CoreSpace.space24,
        endIndent: CoreSpace.space24,
      ),
    );
  }
}
''';

const _defaultCode = '''
class DividerDefaultExample extends StatelessWidget {
  const DividerDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider();
  }
}
''';

const _verticalCode = '''
class DividerVerticalExample extends StatelessWidget {
  const DividerVerticalExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CoreSpace.space32,
      child: const Divider(orientation: .vertical),
    );
  }
}
''';

const _withChildCode = '''
class DividerWithChildExample extends StatelessWidget {
  const DividerWithChildExample({super.key});

  @override
  Widget build(BuildContext context) {
    final ts = Theme.of(context).typography;
    final cs = Theme.of(context).colorScheme;
    return Divider(
      child: DefaultTextStyle.merge(
        style: ts.labelMedium.toValue(theme: Theme.of(context)).copyWith(color: cs.onSurfaceVariant.toValue()),
        child: const Text('또는'),
      ),
    );
  }
}
''';
