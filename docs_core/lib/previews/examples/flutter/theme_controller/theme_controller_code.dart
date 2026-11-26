/// Returns a Flutter code snippet string for the ThemeController
/// component.
String themeControllerCode(String? variant) => switch (variant) {
  'chain' => _chainCode,
  _ => _defaultCode,
};

const String _chainCode = '''
class ThemeControllerChainExample extends StatefulWidget {
  const ThemeControllerChainExample({super.key});

  @override
  State<ThemeControllerChainExample> createState() => _ThemeControllerChainExampleState();
}

class _ThemeControllerChainExampleState extends State<ThemeControllerChainExample> {
  String _selected = '오션';

  @override
  Widget build(BuildContext context) {
    return ThemeController(
      selectedTheme: _selected,
      onThemeChanged: (name) => setState(() => _selected = name),
      themes: const [
        CoreThemeOption(
          name: '오션',
          primaryColor: CoreColor.fromRGB(14, 165, 233),
          secondaryColor: CoreColor.fromRGB(99, 102, 241),
        ),
        CoreThemeOption(
          name: '포레스트',
          primaryColor: CoreColor.fromRGB(34, 197, 94),
          secondaryColor: CoreColor.fromRGB(132, 204, 22),
        ),
        CoreThemeOption(
          name: '선셋',
          primaryColor: CoreColor.fromRGB(249, 115, 22),
          secondaryColor: CoreColor.fromRGB(239, 68, 68),
        ),
      ],
    ).withStyle(
      const CoreThemeControllerStyle(
        buttonSize: CoreSize.size64,
        buttonRadius: CoreBorderRadius.all(CoreRadius.radius4),
        selectedBorderColor: CoreColor.token(CoreColors.primary),
        selectedBorderWidth: CoreStrokeWidth.stroke3,
      ),
    );
  }
}''';

const String _defaultCode = '''
class ThemeControllerDefaultExample extends StatefulWidget {
  const ThemeControllerDefaultExample({super.key});

  @override
  State<ThemeControllerDefaultExample> createState() =>
      _ThemeControllerDefaultExampleState();
}

class _ThemeControllerDefaultExampleState
    extends State<ThemeControllerDefaultExample> {
  String _selected = '모노';

  @override
  Widget build(BuildContext context) {
    return ThemeController(
      selectedTheme: _selected,
      onThemeChanged: (name) => setState(() => _selected = name),
      themes: const [
        CoreThemeOption(
          name: '모노',
          primaryColor: CoreColor.token(CoreColors.onSurface),
          secondaryColor: CoreColor.token(CoreColors.outlineVariant),
        ),
        CoreThemeOption(
          name: '오션',
          primaryColor: CoreColor.fromRGB(14, 165, 233),
          secondaryColor: CoreColor.fromRGB(99, 102, 241),
        ),
        CoreThemeOption(
          name: '포레스트',
          primaryColor: CoreColor.fromRGB(34, 197, 94),
          secondaryColor: CoreColor.fromRGB(132, 204, 22),
        ),
        CoreThemeOption(
          name: '선셋',
          primaryColor: CoreColor.fromRGB(249, 115, 22),
          secondaryColor: CoreColor.fromRGB(239, 68, 68),
        ),
      ],
    );
  }
}
''';
