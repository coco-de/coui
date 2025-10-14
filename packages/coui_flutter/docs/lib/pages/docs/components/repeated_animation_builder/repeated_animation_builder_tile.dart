import 'dart:math';
import 'package:flutter/material.dart' as material;
import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs/pages/docs/components_page.dart';

class RepeatedAnimationBuilderTile extends StatelessWidget
    implements IComponentPage {
  const RepeatedAnimationBuilderTile({super.key});

  @override
  String get title => 'Repeated Animation Builder';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'repeated_animation_builder',
      title: 'Repeated Animation Builder',
      example: RepeatedAnimationBuilder(
        start: 0.0,
        end: 90.0,
        duration: const Duration(seconds: 1),
        builder: (context, value, child) {
          return Transform.rotate(
            angle: pi / 180 * value,
            child: Container(
              color: material.Colors.red,
              width: 100,
              height: 100,
            ),
          );
        },
      ),
      horizontalOffset: 80,
      scale: 2,
    );
  }
}
