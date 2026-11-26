/// Returns a Flutter code snippet string for the Scaffold component.
String scaffoldCode(String? variant) => switch (variant) {
  'chain' => _chainCode,
  _ => _defaultCode,
};

const String _chainCode = '''
class ScaffoldChainExample extends StatelessWidget {
  const ScaffoldChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          headers: [
            AppBar(
              title: const Text('대시보드').titleMedium,
              trailing: const [Icon(LucideIcons.settings)],
            ),
          ],
          footers: [
            AppBar(
              title: const Text('준비됨').bodySmall.onSurfaceVariant,
            ),
          ],
          child: const Center(child: Text('본문 영역')),
        )
        .withStyle(
          const CoreScaffoldStyle(
            headerBorderColor: CoreColor.token(CoreColors.outline),
            headerBorderWidth: CoreStrokeWidth.stroke2,
          ),
        )
        .surfaceContainer;
  }
}
''';

const String _defaultCode = '''
class ScaffoldDefaultExample extends StatelessWidget {
  const ScaffoldDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Fixed-height frame, like the Web twin's: a `Scaffold` lays its body
    // out with `Expanded`, so it needs a height to fill. 384 is the 400px
    // docs stage less its 8px inset on each side — anything taller overflows.
    return SizedBox(
      height: 384,
      child: Scaffold(
        headers: [
          AppBar(
            title: const Text('대시보드').titleMedium,
            trailing: const [Icon(LucideIcons.settings)],
          ),
        ],
        footers: [
          AppBar(
            title: const Text('준비됨').bodySmall.onSurfaceVariant,
          ),
        ],
        child: const Center(child: Text('본문 영역')),
      ),
    );
  }
}
''';
