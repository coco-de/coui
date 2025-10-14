import 'package:coui_flutter/coui_flutter.dart';

class ButtonExample11 extends StatelessWidget {
  const ButtonExample11({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runAlignment: WrapAlignment.center,
      runSpacing: 8,
      children: [
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.compact,
          child: const Text('Compact'),
        ),
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.dense,
          child: const Text('Dense'),
        ),
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.normal,
          child: const Text('Normal'),
        ),
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.comfortable,
          child: const Text('Comfortable'),
        ),
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.icon,
          child: const Text('Icon'),
        ),
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.iconComfortable,
          child: const Text('Icon Comfortable'),
        ),
      ],
    );
  }
}
