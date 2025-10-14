import 'package:coui_flutter/coui_flutter.dart';

class InputExample3 extends StatelessWidget {
  const InputExample3({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          features: [
            const InputFeature.clear(),
            InputFeature.hint(
              popupBuilder: (context) {
                return const TooltipContainer(
                  child: Text('This is for your username'),
                );
              },
            ),
            const InputFeature.copy(),
            const InputFeature.paste(),
          ],
          placeholder: const Text('Enter your name'),
        ),
        const Gap(24),
        const TextField(
          features: [
            InputFeature.clear(visibility: InputFeatureVisibility.textNotEmpty),
            InputFeature.passwordToggle(mode: PasswordPeekMode.hold),
          ],
          placeholder: Text('Enter your password'),
        ),
      ],
    );
  }
}
