import 'package:flutter/material.dart' as material;
import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs/pages/docs/components_page.dart';

class InputTile extends StatelessWidget implements IComponentPage {
  const InputTile({super.key});

  @override
  String get title => 'Text Input';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'input',
      title: 'Text Input',
      example: Card(
        child: const TextField(
          features: [
            InputFeature.leading(material.Icon(material.Icons.edit)),
          ],
          initialValue: 'Hello World',
        ).sized(height: 32, width: 250),
      ).sized(height: 400),
      scale: 2,
    );
  }
}
