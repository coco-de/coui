import 'package:flutter/material.dart' as material;
import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs/pages/docs/components_page.dart';

class AnimatedValueBuilderTile extends StatelessWidget
    implements IComponentPage {
  const AnimatedValueBuilderTile({super.key});

  @override
  String get title => 'Animated Value Builder';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'animated_value_builder',
      title: 'Animated Value Builder',
      example: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: RepeatedAnimationBuilder(
                start: material.Colors.red,
                end: material.Colors.blue,
                duration: const Duration(seconds: 1),
                builder: (context, value, child) {
                  return Container(color: value);
                },
                mode: RepeatMode.pingPong,
                lerp: material.Color.lerp,
              ),
            ),
            Positioned(
              left: 16,
              top: 8,
              child: RepeatedAnimationBuilder(
                start: 0.0,
                end: 1.0,
                duration: const Duration(seconds: 1),
                builder: (context, value, child) {
                  // 0.0 - 0.5 = 0
                  // 0.5 - 1.0 = 1
                  return Text(value.round().toString()).x3Large().bold();
                },
                mode: RepeatMode.pingPong,
              ),
            ),
          ],
        ),
      ),
      scale: 2,
    );
  }
}
