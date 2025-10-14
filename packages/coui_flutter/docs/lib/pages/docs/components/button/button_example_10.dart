import 'package:coui_flutter/coui_flutter.dart';

class ButtonExample10 extends StatelessWidget {
  const ButtonExample10({super.key});

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
          size: ButtonSize.xSmall,
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
          onPressed: () {
            // TODOS: will be implemented later.
          },
          size: ButtonSize.normal,
          child: const Text('Normal'),
        ),
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          size: ButtonSize.large,
          child: const Text('Large'),
        ),
        PrimaryButton(
          onPressed: () {
            // TODOS: will be implemented later.
          },
          size: ButtonSize.xLarge,
          child: const Text('Extra Large'),
        ),
      ],
    );
  }
}
