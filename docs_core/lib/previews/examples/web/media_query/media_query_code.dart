/// Code snippet for [MediaQueryVisibility] Web examples.
String mediaQueryCode(String? variant) => _defaultCode;

const _defaultCode = '''
class MediaQueryDefaultExample extends StatelessComponent {
  const MediaQueryDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return MediaQueryVisibility(
      minBreakpoint: .md,
      alternateChild: div(
        classes: 'w-full p-\${CoreSpace.scale.space12} '
            'bg-\${cs.surfaceContainer} text-\${cs.onSurface}',
        [Text('md 미만에서 보여요')],
      ),
      child: div(
        classes: 'w-full p-\${CoreSpace.scale.space12} '
            'bg-\${cs.primaryContainer} text-\${cs.onPrimaryContainer}',
        [Text('md 이상에서 보여요')],
      ),
    );
  }
}
''';
