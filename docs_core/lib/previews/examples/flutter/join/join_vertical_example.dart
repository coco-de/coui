import 'package:coui_flutter/coui_flutter.dart';

class JoinVerticalExample extends StatelessWidget {
  const JoinVerticalExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Join(
      vertical: true,
      children: [
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: const Text('A'),
        ),
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: const Text('B'),
        ),
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: const Text('C'),
        ),
      ],
    );
  }
}
