import 'package:docs/pages/docs_page.dart';
// ignore_for_file: library_private_types_in_public_api
import 'package:coui_flutter/coui_flutter.dart';

class ColorsPage extends StatefulWidget {
  const ColorsPage({super.key});

  @override
  _ColorsPageState createState() => _ColorsPageState();
}

class _ColorsPageState extends State<ColorsPage> {
  Map<String, ColorShades> shadeMap = {
    'Slate': Colors.slate,
    'Gray': Colors.gray,
    'Zinc': Colors.zinc,
    'Neutral': Colors.neutral,
    'Stone': Colors.stone,
    'Red': Colors.red,
    'Orange': Colors.orange,
    'Amber': Colors.amber,
    'Yellow': Colors.yellow,
    'Lime': Colors.lime,
    'Green': Colors.green,
    'Emerald': Colors.emerald,
    'Teal': Colors.teal,
    'Cyan': Colors.cyan,
    'Sky': Colors.sky,
    'Blue': Colors.blue,
    'Indigo': Colors.indigo,
    'Violet': Colors.violet,
    'Purple': Colors.purple,
    'Fuchsia': Colors.fuchsia,
    'Pink': Colors.pink,
    'Rose': Colors.rose,
  };

  final OnThisPage _predefinedColorsKey = OnThisPage();
  final OnThisPage _customColorKey = OnThisPage();

  HSLColor _customColor = Colors.red.toHSL();
  static const _defaultHueShift = 0;
  static const _defaultSaturationStepUp = 0;
  static const _defaultSaturationStepDown = 0;
  static const _defaultLightnessStepUp = 8;
  static const _defaultLightnessStepDown = 9;

  int _hueShift = 0;
  int _saturationStepUp = 0;
  int _saturationStepDown = 0;
  int _lightnessStepUp = 8;
  int _lightnessStepDown = 9;
  int _tabIndex = 0;

  int? _hoverIndex;

  void _onTap(String name, ColorShades swatch, int shade) {
    showDialog(
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          actions: [
            PrimaryButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          content: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Use this code to display this color:'),
                const Gap(8),
                CodeSnippet(
                  code: shade == 500
                      ? 'Colors.${name.toLowerCase()}'
                      : 'Colors.${name.toLowerCase()}[$shade]',
                  mode: 'dart',
                ),
              ],
            ),
          ),
          leading: Container(
            decoration: BoxDecoration(
              color: swatch[shade],
              borderRadius: theme.borderRadiusMd,
            ),
            width: 96,
            height: 112,
          ),
          title: Text(name),
        );
      },
      context: context,
    );
  }

  Widget buildColorRow(
    BuildContext context,
    String name,
    ColorShades swatch, [
    bool clickable = true,
  ]) {
    final theme = Theme.of(context);
    List<Widget> children = [];
    for (int shade in ColorShades.shadeValues) {
      children.add(
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 16 / 19,
                child: Clickable(
                  enabled: clickable,
                  mouseCursor: const WidgetStatePropertyAll(
                    SystemMouseCursors.click,
                  ),
                  onPressed: () {
                    _onTap(name, swatch, shade);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: swatch[shade],
                      border: shade == 500
                          ? Border.all(
                              color: theme.colorScheme.foreground,
                              width: 3,
                              strokeAlign: BorderSide.strokeAlignOutside,
                            )
                          : null,
                      borderRadius: theme.borderRadiusMd,
                    ),
                  ),
                ),
              ),
              const Gap(8),
              Text(
                '${shade == 500 ? '500 (Base)' : shade}',
                textAlign: TextAlign.center,
              ).xSmall().mono().muted(),
            ],
          ),
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ).gap(8);
  }

  Widget buildEditableColorRow(
    BuildContext context,
    String name,
    ColorShades swatch,
  ) {
    final theme = Theme.of(context);
    List<Widget> children = [];
    var shadeValues = ColorShades.shadeValues;
    for (int i = 0; i < shadeValues.length; i++) {
      final shade = shadeValues[i];
      children.add(
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 16 / 19,
                child: Builder(
                  builder: (context) {
                    return Clickable(
                      mouseCursor: const WidgetStatePropertyAll(
                        SystemMouseCursors.click,
                      ),
                      onHover: (value) {
                        if (value) {
                          setState(() {
                            _hoverIndex = shade;
                          });
                        } else if (_hoverIndex == shade) {
                          setState(() {
                            _hoverIndex = null;
                          });
                        }
                      },
                      onPressed: () {
                        showColorPicker(
                          color: ColorDerivative.fromColor(swatch[shade]),
                          context: context,
                          offset: const Offset(0, 8),
                          onColorChanged: (value) {
                            setState(() {
                              _customColor = ColorShades.shiftHSL(
                                value.toHSLColor(),
                                500,
                                base: shade,
                              );
                            });
                          },
                          showAlpha: false,
                        );
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: swatch[shade],
                          border: shade == 500
                              ? Border.all(
                                  color: theme.colorScheme.foreground,
                                  width: 3,
                                  strokeAlign: BorderSide.strokeAlignOutside,
                                )
                              : null,
                          borderRadius: theme.borderRadiusMd,
                        ),
                        child: Visibility(
                          visible: _hoverIndex == shade,
                          child: Icon(
                            Icons.edit,
                            size: 24,
                            color: swatch[shade].getContrastColor(0.8),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Gap(8),
              Text(
                '${shade == 500 ? '500 (Base)' : shade}',
                textAlign: TextAlign.center,
              ).xSmall().mono().muted(),
            ],
          ),
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ).gap(8);
  }

  Widget buildCode() {
    return CodeSnippet(
      code: generateCode(
        ColorShades.fromAccentHSL(
          _customColor,
          hueShift: _hueShift,
          lightnessStepDown: _lightnessStepDown,
          lightnessStepUp: _lightnessStepUp,
          saturationStepDown: _saturationStepDown,
          saturationStepUp: _saturationStepUp,
        ),
      ),
      mode: 'dart',
    );
  }

  String generateCode(ColorShades swatch) {
    Map<String, String> named = {};
    if (_hueShift != _defaultHueShift) {
      named['hueShift'] = 'hueShift: $_hueShift';
    }
    if (_saturationStepUp != _defaultSaturationStepUp) {
      named['saturationStepUp'] = 'saturationStepUp: $_saturationStepUp';
    }
    if (_saturationStepDown != _defaultSaturationStepDown) {
      named['saturationStepDown'] = 'saturationStepDown: $_saturationStepDown';
    }
    if (_lightnessStepUp != _defaultLightnessStepUp) {
      named['lightnessStepUp'] = 'lightnessStepUp: $_lightnessStepUp';
    }
    if (_lightnessStepDown != _defaultLightnessStepDown) {
      named['lightnessStepDown'] = 'lightnessStepDown: $_lightnessStepDown';
    }
    String baseColorHex = swatch[500].toHex();
    String code = 'ColorShades.fromAccent(\n'
        '  Color(0x$baseColorHex),\n';
    if (named.isNotEmpty) {
      code += '  ${named.values.join(',\n  ')}\n';
    }
    code += ')';
    return code;
  }

  @override
  Widget build(BuildContext context) {
    return DocsPage(
      name: 'colors',
      onThisPage: {
        'Predefined Colors': _predefinedColorsKey,
        'Generate Color': _customColorKey,
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Colors').h1(),
          const Text('Color and ColorShades/ColorSwatch constants').lead(),
          const Text('Predefined Colors').h2().anchored(_predefinedColorsKey),
          for (final color in shadeMap.entries)
            Card(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(color.key).medium().small()),
                      OutlineButton(
                        onPressed: () {
                          setState(() {
                            _customColor = color.value[500].toHSL();
                            Scrollable.ensureVisible(
                              _customColorKey.currentContext!,
                              duration: kDefaultDuration,
                              alignmentPolicy:
                                  ScrollPositionAlignmentPolicy.explicit,
                            );
                          });
                        },
                        size: ButtonSize.xSmall,
                        density: ButtonDensity.icon,
                        child: const Icon(Icons.edit),
                      ),
                    ],
                  ),
                  const Gap(8),
                  buildColorRow(context, color.key, color.value),
                ],
              ),
            ).withMargin(top: 32),
          const Text('Generate Color').h2().anchored(_customColorKey),
          const Gap(32),
          TabList(
            index: _tabIndex,
            onChanged: (value) {
              setState(() {
                _tabIndex = value;
              });
            },
            children: const [
              TabItem(child: Text('Color')),
              TabItem(child: Text('Code')),
            ],
          ),
          const Gap(12),
          Offstage(
            offstage: _tabIndex != 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildColorTab(context),
                const Gap(8),
                _buildColorOptions(context),
              ],
            ),
          ),
          Offstage(offstage: _tabIndex != 1, child: buildCode()),
        ],
      ),
    );
  }

  Widget _buildColorTab(BuildContext context) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildEditableColorRow(
            context,
            'custom',
            ColorShades.fromAccentHSL(
              _customColor,
              hueShift: _hueShift,
              lightnessStepDown: _lightnessStepUp,
              lightnessStepUp: _lightnessStepDown,
              saturationStepDown: _saturationStepDown,
              saturationStepUp: _saturationStepUp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOptions(BuildContext context) {
    return Card(
      child: Form(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormField<SliderValue>(
              key: const FormKey(#hueShift),
              label: const Text('Hue Shift'),
              child: Slider(
                divisions: 100,
                max: 360,
                min: -360,
                onChanged: (value) {
                  setState(() {
                    _hueShift = value.value.toInt();
                  });
                },
                value: SliderValue.single(_hueShift.toDouble()),
              ),
            ),
            FormField<SliderValue>(
              key: const FormKey(#saturationStepUp),
              label: const Text('Saturation Step Up'),
              child: Slider(
                divisions: 20,
                max: 20,
                min: 0,
                onChanged: (value) {
                  setState(() {
                    _saturationStepUp = value.value.toInt();
                  });
                },
                value: SliderValue.single(_saturationStepUp.toDouble()),
              ),
            ),
            FormField<SliderValue>(
              key: const FormKey(#saturationStepDown),
              label: const Text('Saturation Step Down'),
              child: Slider(
                divisions: 20,
                max: 20,
                min: 0,
                onChanged: (value) {
                  setState(() {
                    _saturationStepDown = value.value.toInt();
                  });
                },
                value: SliderValue.single(_saturationStepDown.toDouble()),
              ),
            ),
            FormField<SliderValue>(
              key: const FormKey(#lightnessStepUp),
              label: const Text('Lightness Step Up'),
              child: Slider(
                divisions: 20,
                max: 20,
                min: 0,
                onChanged: (value) {
                  setState(() {
                    _lightnessStepUp = value.value.toInt();
                  });
                },
                value: SliderValue.single(_lightnessStepUp.toDouble()),
              ),
            ),
            FormField<SliderValue>(
              key: const FormKey(#lightnessStepDown),
              label: const Text('Lightness Step Down'),
              child: Slider(
                divisions: 20,
                max: 20,
                min: 0,
                onChanged: (value) {
                  setState(() {
                    _lightnessStepDown = value.value.toInt();
                  });
                },
                value: SliderValue.single(_lightnessStepDown.toDouble()),
              ),
            ),
            const Gap(16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DestructiveButton(
                  onPressed: () {
                    showDialog(
                      builder: (context) {
                        return AlertDialog(
                          actions: [
                            PrimaryButton(
                              child: const Text('Reset'),
                              onPressed: () {
                                setState(() {
                                  _hueShift = _defaultHueShift;
                                  _saturationStepUp = _defaultSaturationStepUp;
                                  _saturationStepDown =
                                      _defaultSaturationStepDown;
                                  _lightnessStepUp = _defaultLightnessStepUp;
                                  _lightnessStepDown =
                                      _defaultLightnessStepDown;
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                            SecondaryButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                          content: const Text(
                            'Are you sure you want to reset the options?',
                          ),
                          title: const Text('Reset Options'),
                        );
                      },
                      context: context,
                    );
                  },
                  leading: const Icon(Icons.restore),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ).gap(8),
      ),
    );
  }
}
