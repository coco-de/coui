import 'package:coui_flutter/coui_flutter.dart';

class JoinDefaultExample extends StatelessWidget {
  const JoinDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Join(
      children: [
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: const Text('1'),
        ),
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: const Text('2'),
        ),
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: const Text('3'),
        ),
      ],
    );
  }
}
