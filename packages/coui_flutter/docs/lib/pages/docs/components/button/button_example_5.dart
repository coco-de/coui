import 'package:coui_flutter/coui_flutter.dart';

class ButtonExample5 extends StatelessWidget {
  const ButtonExample5({super.key});

  @override
  Widget build(BuildContext context) {
    return DestructiveButton(
      onPressed: () {},
      child: const Text('Destructive'),
    );
  }
}
