import 'package:coui_flutter/coui_flutter.dart';

class ColorPickerInlineExample extends StatefulWidget {
  const ColorPickerInlineExample({super.key});

  @override
  State<ColorPickerInlineExample> createState() => _ColorPickerInlineExampleState();
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
}
