import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreThemeControllerStyle] slot without constructing the
/// component from scratch. The patch enlarges the swatch buttons, squares
/// their corners and thickens the selected outline.
class ThemeControllerChainExample extends StatefulComponent {
  const ThemeControllerChainExample({super.key});

  @override
  State<ThemeControllerChainExample> createState() => _ThemeControllerChainExampleState();
}

class _ThemeControllerChainExampleState extends State<ThemeControllerChainExample> {
  String _selected = '오션';

  @override
  Component build(BuildContext context) {
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
}
