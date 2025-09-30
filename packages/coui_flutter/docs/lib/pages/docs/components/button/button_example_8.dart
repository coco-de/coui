import 'package:coui_flutter/coui_flutter.dart';

class ButtonExample8 extends StatelessWidget {
  const ButtonExample8({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 8,
      spacing: 8,
      children: [
        IconButton.primary(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.icon,
          icon: const Icon(Icons.add),
        ),
        IconButton.secondary(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.icon,
          icon: const Icon(Icons.add),
        ),
        IconButton.outline(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.icon,
          icon: const Icon(Icons.add),
        ),
        IconButton.ghost(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.icon,
          icon: const Icon(Icons.add),
        ),
        IconButton.text(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.icon,
          icon: const Icon(Icons.add),
        ),
        IconButton.destructive(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          density: ButtonDensity.icon,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
