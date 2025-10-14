import 'package:coui_flutter/coui_flutter.dart';

class CircularProgressExample2 extends StatefulWidget {
  const CircularProgressExample2({super.key});

  @override
  State<CircularProgressExample2> createState() =>
      _CircularProgressExample2State();
}

class _CircularProgressExample2State extends State<CircularProgressExample2> {
  double _progress = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          size: 48,
          value: _progress.clamp(0, 100) / 100,
        ),
        const Gap(48),
        Row(
          children: [
            DestructiveButton(
              child: const Text('Reset'),
              onPressed: () {
                setState(() {
                  _progress = 0;
                });
              },
            ),
            const Gap(16),
            PrimaryButton(
              child: const Text('Decrease by 10'),
              onPressed: () {
                setState(() {
                  _progress -= 10;
                });
              },
            ),
            const Gap(16),
            PrimaryButton(
              child: const Text('Increase by 10'),
              onPressed: () {
                setState(() {
                  _progress += 10;
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}
