/// Code snippet for [Divider] Web examples.
String dividerCode(String? variant) {
  return switch (variant) {
    'chain' => _chainCode,
    'vertical' => _verticalCode,
    'with-child' => _withChildCode,
    _ => _defaultCode,
  };
}

const _chainCode = '''
class DividerChainExample extends StatelessComponent {
  const DividerChainExample({super.key});

  @override
  Component build(BuildContext context) {
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
class DividerDefaultExample extends StatelessComponent {
  const DividerDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Divider();
  }
}
''';

const _verticalCode = '''
class DividerVerticalExample extends StatelessComponent {
  const DividerVerticalExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [const Divider(orientation: .vertical)],
      styles: Styles(raw: {'height': '\${CoreSpace.space32}px'}),
    );
  }
}
''';

const _withChildCode = '''
class DividerWithChildExample extends StatelessComponent {
  const DividerWithChildExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Divider(
      child: div(
        [Text('또는')],
        classes: 'text-\${CoreTextStyles.labelMedium.name} text-\${cs.onSurfaceVariant}',
      ),
    );
  }
}
''';
