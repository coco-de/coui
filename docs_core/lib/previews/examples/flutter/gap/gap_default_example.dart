import 'package:coui_flutter/coui_flutter.dart';

class GapDefaultExample extends StatelessWidget {
  const GapDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: const Text('A'),
        ),
        const Gap.space16(),
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: const Text('B'),
        ),
      ],
    );
  }
}
