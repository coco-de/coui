import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreNumberInputStyle] slot without constructing the
/// widget from scratch.
class NumberInputChainExample extends StatelessWidget {
  const NumberInputChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return NumberInput(
      label: '인원',
      initialValue: 2,
      min: 1,
      max: 8,
      onChanged: (value) => debugPrint('Guests: $value'),
    ).withStyle(
      const CoreNumberInputStyle(
        buttonStyle: CoreButtonStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
        ),
      ),
    );
  }
}
