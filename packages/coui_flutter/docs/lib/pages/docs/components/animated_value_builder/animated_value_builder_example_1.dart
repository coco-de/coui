import 'package:coui_flutter/coui_flutter.dart';

class AnimatedValueBuilderExample1 extends StatefulWidget {
  const AnimatedValueBuilderExample1({super.key});

  @override
  State<AnimatedValueBuilderExample1> createState() =>
      _AnimatedValueBuilderExample1State();
}

class _AnimatedValueBuilderExample1State
    extends State<AnimatedValueBuilderExample1> {
  List<Color> colors = [Colors.red, Colors.green, Colors.blue];
  int index = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedValueBuilder(
          value: colors[index],
          duration: const Duration(seconds: 1),
          builder: (context, value, child) {
            return Container(color: value, width: 100, height: 100);
          },
          lerp: Color.lerp,
        ),
        const Gap(32),
        PrimaryButton(
          child: const Text('Change Color'),
          onPressed: () {
            setState(() {
              index = (index + 1) % colors.length;
            });
          },
        ),
      ],
    );
  }
}
