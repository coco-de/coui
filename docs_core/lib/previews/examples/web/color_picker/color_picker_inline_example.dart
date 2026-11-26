import 'package:coui_web/coui_web.dart';

class ColorPickerInlineExample extends StatefulComponent {
  const ColorPickerInlineExample({super.key});

  @override
  State<ColorPickerInlineExample> createState() => _ColorPickerInlineExampleState();
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
}
