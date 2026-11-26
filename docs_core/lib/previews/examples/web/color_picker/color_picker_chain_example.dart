import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreColorPickerStyle] slot without constructing the
/// component from scratch.
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
}
