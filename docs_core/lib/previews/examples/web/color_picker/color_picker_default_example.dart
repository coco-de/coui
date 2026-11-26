import 'package:coui_web/coui_web.dart';

class ColorPickerDefaultExample extends StatefulComponent {
  const ColorPickerDefaultExample({super.key});

  @override
  State<ColorPickerDefaultExample> createState() => _ColorPickerDefaultExampleState();
}

class _ColorPickerDefaultExampleState extends State<ColorPickerDefaultExample> {
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
}
