import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreColorPickerStyle] slot without constructing the
/// widget from scratch.
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
}
