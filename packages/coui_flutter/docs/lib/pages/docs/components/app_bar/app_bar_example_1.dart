import 'package:coui_flutter/coui_flutter.dart';

class AppBarExample1 extends StatelessWidget {
  const AppBarExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedContainer(
      clipBehavior: Clip.antiAlias,
      child: AppBar(
        header: const Text('This is Header'),
        leading: [
          OutlineButton(
            onPressed: () {
              // TODOS: will be implemented later.
            },
            density: ButtonDensity.icon,
            child: const Icon(Icons.arrow_back),
          ),
        ],
        subtitle: const Text('This is Subtitle'),
        title: const Text('This is Title'),
        trailing: [
          OutlineButton(
            onPressed: () {
              // TODOS: will be implemented later.
            },
            density: ButtonDensity.icon,
            child: const Icon(Icons.search),
          ),
          OutlineButton(
            onPressed: () {
              // TODOS: will be implemented later.
            },
            density: ButtonDensity.icon,
            child: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }
}
