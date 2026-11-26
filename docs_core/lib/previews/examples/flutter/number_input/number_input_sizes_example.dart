import 'package:coui_flutter/coui_flutter.dart';

class NumberInputSizesExample extends StatelessWidget {
  const NumberInputSizesExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const NumberInput(size: CoreNumberInputSize.sm, initialValue: 1, min: 0),
        const Gap.space12(),
        const NumberInput(size: CoreNumberInputSize.md, initialValue: 1, min: 0),
        const Gap.space12(),
        const NumberInput(size: CoreNumberInputSize.lg, initialValue: 1, min: 0),
      ],
    );
  }
}
