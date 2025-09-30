import 'package:coui_flutter/coui_flutter.dart';

class ButtonExample10 extends StatelessWidget {
  const ButtonExample10({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      children: [
        PrimaryButton(
          size: ButtonSize.xSmall,
          onPressed: () {
            // TODOS: will be implemented later.
          },
          child: const Text('Extra Small'),
        ),
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          size: ButtonSize.small,
          child: const Text('Small'),
        ),
        PrimaryButton(
          size: ButtonSize.normal,
          onPressed: () {
            // TODOS: will be implemented later.
          },
          child: const Text('Normal'),
        ),
        PrimaryButton(
          size: ButtonSize.large,
          onPressed: () {
            // TODOS: will be implemented later.
          },
          child: const Text('Large'),
        ),
        PrimaryButton(
          size: ButtonSize.xLarge,
          onPressed: () {
            // TODOS: will be implemented later.
          },
          child: const Text('Extra Large'),
        ),
      ],
    );
  }
}
