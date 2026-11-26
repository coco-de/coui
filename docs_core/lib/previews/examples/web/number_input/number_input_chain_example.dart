import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreNumberInputStyle] slot without constructing the
/// component from scratch.
class NumberInputChainExample extends StatelessComponent {
  const NumberInputChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return NumberInput(
      label: '인원',
      initialValue: 2,
      min: 1,
      max: 8,
      onChanged: (value) => print('Guests: $value'),
    ).withStyle(
      const CoreNumberInputStyle(
        buttonStyle: CoreButtonStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
        ),
      ),
    );
  }
}
