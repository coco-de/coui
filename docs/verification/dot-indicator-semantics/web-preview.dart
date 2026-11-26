import 'package:coui_web/coui_web.dart';
import 'package:jaspr/client.dart' as client;

void main() {
  client.Jaspr.initializeApp();
  client.runApp(Theme.defaults(child: const Demo()));
}

class Demo extends StatefulComponent {
  const Demo({super.key});
  @override
  State<Demo> createState() => _DemoState();
}

class _DemoState extends State<Demo> {
  int selected = 0;
  @override
  Component build(BuildContext context) => div([
    p([text('Interactive: ${selected + 1}')]),
    DotIndicator(
      index: selected,
      length: 3,
      onChanged: (index) => setState(() => selected = index),
    ),
    p([text('Passive')]),
    DotIndicator(index: 1, length: 3),
    p([text('Empty')]),
    DotIndicator(index: 0, length: 0, onChanged: (_) {}),
  ]);
}
