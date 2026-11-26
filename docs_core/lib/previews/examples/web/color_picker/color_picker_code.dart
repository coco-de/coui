/// Returns a Web code snippet string for the ColorPicker component.
String colorPickerCode(String? variant) {
  return switch (variant) {
    'chain' =>
      r'''
class ColorPickerChainExample extends StatefulComponent {
  const ColorPickerChainExample({super.key});

  @override
  State<ColorPickerChainExample> createState() => _ColorPickerChainExampleState();
}

class _ColorPickerChainExampleState extends State<ColorPickerChainExample> {
  String _color = '#3B82F6';

  @override
  Component build(BuildContext context) {
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
class ColorPickerInlineExample extends StatefulComponent {
  const ColorPickerInlineExample({super.key});

  @override
  State<ColorPickerInlineExample> createState() =>
      _ColorPickerInlineExampleState();
}

class _ColorPickerInlineExampleState extends State<ColorPickerInlineExample> {
  String _color = '#6750A4';

  @override
  Component build(BuildContext context) {
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
class ColorPickerDefaultExample extends StatefulComponent {
  const ColorPickerDefaultExample({super.key});

  @override
  State<ColorPickerDefaultExample> createState() =>
      _ColorPickerDefaultExampleState();
}

class _ColorPickerDefaultExampleState
    extends State<ColorPickerDefaultExample> {
  String _color = '#3B82F6';

  @override
  Component build(BuildContext context) {
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
