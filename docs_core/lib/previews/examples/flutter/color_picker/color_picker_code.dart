/// Returns a Flutter code snippet string for the ColorPicker component.
String colorPickerCode(String? variant) {
  return switch (variant) {
    'chain' =>
      r'''
class ColorPickerChainExample extends StatefulWidget {
  const ColorPickerChainExample({super.key});

  @override
  State<ColorPickerChainExample> createState() => _ColorPickerChainExampleState();
}

class _ColorPickerChainExampleState extends State<ColorPickerChainExample> {
  Color _color = const Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    return ColorPicker(
      color: _color,
      showHexInput: true,
      onChanged: (value) {
        setState(() => _color = value);
      },
    ).withStyle(
      const CoreColorPickerStyle(
        swatchSize: CoreSpace.space48,
        hexInputWidth: CoreSpace.space112,
        swatchGapStyle: CoreGapStyle(size: CoreSpace.space12),
        swatchBorderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        borderColor: CoreColor.token(CoreColors.primary),
        borderWidth: CoreStrokeWidth.stroke2,
      ),
    );
  }
}''',
    'inline' =>
      r'''
class ColorPickerInlineExample extends StatefulWidget {
  const ColorPickerInlineExample({super.key});

  @override
  State<ColorPickerInlineExample> createState() =>
      _ColorPickerInlineExampleState();
}

class _ColorPickerInlineExampleState extends State<ColorPickerInlineExample> {
  Color _color = const Color(0xFF6750A4);

  @override
  Widget build(BuildContext context) {
    return ColorPicker(
      color: _color,
      promptMode: CoreColorPickerPromptMode.inline,
      onChanged: (value) {
        setState(() => _color = value);
      },
    );
  }
}''',
    _ =>
      r'''
class ColorPickerDefaultExample extends StatefulWidget {
  const ColorPickerDefaultExample({super.key});

  @override
  State<ColorPickerDefaultExample> createState() =>
      _ColorPickerDefaultExampleState();
}

class _ColorPickerDefaultExampleState
    extends State<ColorPickerDefaultExample> {
  Color _color = const Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    return ColorPicker(
      color: _color,
      showHexInput: true,
      onChanged: (value) {
        setState(() => _color = value);
      },
    );
  }
}''',
  };
}
