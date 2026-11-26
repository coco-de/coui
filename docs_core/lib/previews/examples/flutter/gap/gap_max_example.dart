import 'package:coui_flutter/coui_flutter.dart';

class GapMaxExample extends StatelessWidget {
  const GapMaxExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: const Text('A'),
        ),
        const MaxGap.space64(),
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: const Text('B'),
        ),
      ],
    );
  }
}
