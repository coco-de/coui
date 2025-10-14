import 'package:coui_flutter/coui_flutter.dart';

class ButtonExample1 extends StatelessWidget {
  const ButtonExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      child: const Text('Primary'),
      onPressed: () {
        // TODOS: will be implemented later.
      },
    );
  }
}
