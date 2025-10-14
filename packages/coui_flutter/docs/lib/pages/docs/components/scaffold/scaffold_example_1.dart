import 'package:coui_flutter/coui_flutter.dart';

class ScaffoldExample1 extends StatefulWidget {
  const ScaffoldExample1({super.key});

  @override
  State<ScaffoldExample1> createState() => _ScaffoldExample1State();
}

class _ScaffoldExample1State extends State<ScaffoldExample1> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(
          leading: [
            OutlineButton(
              onPressed: () {
                // TODOS: will be implemented later.
              },
              density: ButtonDensity.icon,
              child: const Icon(Icons.menu),
            ),
          ],
          subtitle: const Text('A simple counter app'),
          title: const Text('Counter App'),
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
              child: const Icon(Icons.add),
            ),
          ],
        ),
        const Divider(),
      ],
      loadingProgressIndeterminate: true,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:').p(),
            Text('$_counter').h1(),
            PrimaryButton(
              onPressed: _incrementCounter,
              density: ButtonDensity.icon,
              child: const Icon(Icons.add),
            ).p(),
          ],
        ),
      ),
    );
  }
}
