import 'package:coui_flutter/coui_flutter.dart';

class AnimatedValueBuilderExample2 extends StatefulWidget {
  const AnimatedValueBuilderExample2({super.key});

  @override
  State<AnimatedValueBuilderExample2> createState() =>
      _AnimatedValueBuilderExample2State();
}

class _AnimatedValueBuilderExample2State
    extends State<AnimatedValueBuilderExample2> {
  List<Color> colors = [Colors.red, Colors.green, Colors.blue];
  int index = 0;
  int rebuildCount = 0;
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
          key: ValueKey(rebuildCount),
          initialValue: colors[index].withValues(alpha: 0),
          lerp: Color.lerp,
        ),
        const Gap(32),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              child: const Text('Change Color'),
              onPressed: () {
                setState(() {
                  index = (index + 1) % colors.length;
                });
              },
            ),
            const Gap(24),
            PrimaryButton(
              child: const Text('Rebuild'),
              onPressed: () {
                setState(() {
                  rebuildCount++;
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}
