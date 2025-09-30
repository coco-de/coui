import 'package:coui_flutter/coui_flutter.dart';

class ButtonExample9 extends StatelessWidget {
  const ButtonExample9({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          trailing: const Icon(Icons.add),
          child: const Text('Add'),
        ),
        SecondaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          trailing: const Icon(Icons.add),
          child: const Text('Add'),
        ),
        OutlineButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          trailing: const Icon(Icons.add),
          child: const Text('Add'),
        ),
        GhostButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          trailing: const Icon(Icons.add),
          child: const Text('Add'),
        ),
        TextButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          trailing: const Icon(Icons.add),
          child: const Text('Add'),
        ),
        DestructiveButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          trailing: const Icon(Icons.add),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
