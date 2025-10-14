import 'package:flutter/material.dart' as material;
import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs/pages/docs/components_page.dart';

class ColorPickerTile extends StatelessWidget implements IComponentPage {
  const ColorPickerTile({super.key});

  @override
  String get title => 'Color Picker';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'color_picker',
      title: 'Color Picker',
      example: Card(
        child: ColorPickerSet(
          color: ColorDerivative.fromColor(material.Colors.blue),
        ),
      ),
      reverse: true,
      reverseVertical: true,
    );
  }
}
