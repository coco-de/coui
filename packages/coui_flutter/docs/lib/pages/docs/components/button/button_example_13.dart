import 'package:coui_flutter/coui_flutter.dart';

class ButtonExample13 extends StatelessWidget {
  const ButtonExample13({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runAlignment: WrapAlignment.center,
      runSpacing: 8,
      children: [
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          shape: ButtonShape.circle,
          child: const Icon(Icons.add),
        ),
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          shape: ButtonShape.rectangle,
          child: const Text('Rectangle'),
        ),
      ],
    );
  }
}
