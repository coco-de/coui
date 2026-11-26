import 'package:coui_flutter/coui_flutter.dart';

class ButtonDestructiveExample extends StatefulWidget {
  const ButtonDestructiveExample({super.key});

  @override
  State<ButtonDestructiveExample> createState() => _ButtonDestructiveExampleState();
}

class _ButtonDestructiveExampleState extends State<ButtonDestructiveExample> {
  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.destructive,
      onPressed: () {},
      child: Text('삭제').lineLimit(1).ellipsis,
    );
  }
}
