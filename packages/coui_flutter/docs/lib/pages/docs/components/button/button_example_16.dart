import 'package:coui_flutter/coui_flutter.dart';

class ButtonExample16 extends StatelessWidget {
  const ButtonExample16({super.key});

  @override
  Widget build(BuildContext context) {
    return CardButton(
      onPressed: () {
        // TODOS: will be implemented later.
      },
      child: const Basic(
        title: Text('Project #1'),
        subtitle: Text('Project description'),
        content: Text(
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
        ),
      ),
    );
  }
}
