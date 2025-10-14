import 'package:coui_flutter/coui_flutter.dart';

class ColorPickerExample3 extends StatelessWidget {
  const ColorPickerExample3({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(
          child: const Text('Open Color Picker Popover'),
          onPressed: () {
            showColorPicker(
              color: ColorDerivative.fromColor(Colors.blue),
              context: context,
              offset: const Offset(0, 8),
              onColorChanged: (value) {
                // Handle color change
              },
            );
          },
        ),
        const Gap(16),
        PrimaryButton(
          child: const Text('Open Color Picker Dialog'),
          onPressed: () {
            showColorPickerDialog(
              color: ColorDerivative.fromColor(Colors.blue),
              context: context,
              onColorChanged: (value) {
                // Handle color change
              },
              title: const Text('Select Color'),
            );
          },
        ),
      ],
    );
  }
}
