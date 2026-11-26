import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'theme_controller.stories.g.dart';

const _kOceanTheme = CoreThemeOption(
  name: 'Ocean',
  primaryColor: CoreColor.fromRGB(14, 165, 233),
  secondaryColor: CoreColor.fromRGB(99, 102, 241),
);
const _kForestTheme = CoreThemeOption(
  name: 'Forest',
  primaryColor: CoreColor.fromRGB(34, 197, 94),
  secondaryColor: CoreColor.fromRGB(132, 204, 22),
);
const _kSunsetTheme = CoreThemeOption(
  name: 'Sunset',
  primaryColor: CoreColor.fromRGB(249, 115, 22),
  secondaryColor: CoreColor.fromRGB(239, 68, 68),
);
const _kOceanFullTheme = CoreThemeOption(
  name: 'Ocean',
  primaryColor: CoreColor.fromRGB(14, 165, 233),
  secondaryColor: CoreColor.fromRGB(99, 102, 241),
  accentColor: CoreColor.fromRGB(236, 72, 153),
  neutralColor: CoreColor.fromRGB(148, 163, 184),
);
const _kForestFullTheme = CoreThemeOption(
  name: 'Forest',
  primaryColor: CoreColor.fromRGB(34, 197, 94),
  secondaryColor: CoreColor.fromRGB(132, 204, 22),
  accentColor: CoreColor.fromRGB(250, 204, 21),
  neutralColor: CoreColor.fromRGB(120, 113, 108),
);

/// Interactive demo host for [ThemeController] stories.
///
/// Owns the selected theme name; tapping a swatch updates the
/// selection readout below the controller.
class ThemeControllerDemo extends StatefulWidget {
  /// Creates a [ThemeControllerDemo].
  const ThemeControllerDemo({super.key, this.showFullPalette = false});

  /// Whether theme options carry accent / neutral swatches as well.
  final bool showFullPalette;

  @override
  State<ThemeControllerDemo> createState() => _ThemeControllerDemoState();
}

class _ThemeControllerDemoState extends State<ThemeControllerDemo> {
  String _selected = 'Ocean';

  void handleThemeChanged(String name) {
    setState(() => _selected = name);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      spacing: CoreSpace.space12,
      children: [
        ThemeController(
          themes: widget.showFullPalette
              ? const [_kOceanFullTheme, _kForestFullTheme]
              : const [_kOceanTheme, _kForestTheme, _kSunsetTheme],
          onThemeChanged: handleThemeChanged,
          selectedTheme: _selected,
        ),
        Text('Selected theme: $_selected').medium(),
      ],
    );
  }
}

/// Navigation metadata for the ThemeController component.
const kComponentMeta = ComponentMeta(name: 'ThemeController', path: 'control');

/// Story metadata for [ThemeControllerDemo].
const kMeta = Meta(ThemeControllerDemo.new);

/// Interactive theme selection with primary / secondary swatches.
final $Default = _Story();

/// Theme options carrying the full four-color palette.
final $FullPalette = _Story(
  name: 'Full Palette',
  args: _Args(showFullPalette: BoolArg(true)),
);
