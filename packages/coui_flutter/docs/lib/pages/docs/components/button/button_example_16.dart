import 'package:coui_flutter/coui_flutter.dart';

class ButtonExample16 extends StatelessWidget {
  const ButtonExample16({super.key});

  @override
  Widget build(BuildContext context) {
    return CardButton(
      child: const Basic(
        content: Text(
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
        ),
        subtitle: Text('Project description'),
        title: Text('Project #1'),
      ),
      onPressed: () {
        // TODOS: will be implemented later.
      },
    );
  }
}
