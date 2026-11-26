import 'package:coui_flutter/coui_flutter.dart';

class ColorPickerDefaultExample extends StatefulWidget {
  const ColorPickerDefaultExample({super.key});

  @override
  State<ColorPickerDefaultExample> createState() => _ColorPickerDefaultExampleState();
}

class _ColorPickerDefaultExampleState extends State<ColorPickerDefaultExample> {
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
}
