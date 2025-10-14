import 'package:coui_flutter/coui_flutter.dart';

class ChipExample1 extends StatelessWidget {
  const ChipExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          trailing: ChipButton(
            child: const Icon(Icons.close),
            onPressed: () {
              // TODOS: will be implemented later.
            },
          ),
          child: const Text('Apple'),
        ),
        Chip(
          style: const ButtonStyle.primary(),
          trailing: ChipButton(
            child: const Icon(Icons.close),
            onPressed: () {
              // TODOS: will be implemented later.
            },
          ),
          child: const Text('Banana'),
        ),
        Chip(
          style: const ButtonStyle.outline(),
          trailing: ChipButton(
            child: const Icon(Icons.close),
            onPressed: () {
              // TODOS: will be implemented later.
            },
          ),
          child: const Text('Cherry'),
        ),
        Chip(
          style: const ButtonStyle.ghost(),
          trailing: ChipButton(
            child: const Icon(Icons.close),
            onPressed: () {
              // TODOS: will be implemented later.
            },
          ),
          child: const Text('Durian'),
        ),
        Chip(
          style: const ButtonStyle.destructive(),
          trailing: ChipButton(
            child: const Icon(Icons.close),
            onPressed: () {
              // TODOS: will be implemented later.
            },
          ),
          child: const Text('Elderberry'),
        ),
      ],
    );
  }
}
