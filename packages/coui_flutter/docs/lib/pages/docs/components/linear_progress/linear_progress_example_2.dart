import 'package:coui_flutter/coui_flutter.dart';

class LinearProgressExample2 extends StatefulWidget {
  const LinearProgressExample2({super.key});

  @override
  State<LinearProgressExample2> createState() => _LinearProgressExample2State();
}

class _LinearProgressExample2State extends State<LinearProgressExample2> {
  double value = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 200, child: LinearProgressIndicator(value: value)),
        const Gap(24),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              child: const Text('Reset'),
              onPressed: () {
                setState(() {
                  value = 0;
                });
              },
            ),
            const Gap(24),
            PrimaryButton(
              child: const Text('Increase'),
              onPressed: () {
                if (value + 0.1 >= 1) {
                  return;
                }
                setState(() {
                  value += 0.1;
                });
              },
            ),
            const Gap(24),
            PrimaryButton(
              child: const Text('Decrease'),
              onPressed: () {
                if (value - 0.1 <= 0) {
                  return;
                }
                setState(() {
                  value -= 0.1;
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}
