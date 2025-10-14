import 'package:coui_flutter/coui_flutter.dart';

class ButtonExample8 extends StatelessWidget {
  const ButtonExample8({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        IconButton.primary(
          icon: const Icon(Icons.add),
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.icon,
        ),
        IconButton.secondary(
          icon: const Icon(Icons.add),
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.icon,
        ),
        IconButton.outline(
          icon: const Icon(Icons.add),
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.icon,
        ),
        IconButton.ghost(
          icon: const Icon(Icons.add),
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.icon,
        ),
        IconButton.text(
          icon: const Icon(Icons.add),
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.icon,
        ),
        IconButton.destructive(
          icon: const Icon(Icons.add),
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.icon,
        ),
      ],
    );
  }
}
