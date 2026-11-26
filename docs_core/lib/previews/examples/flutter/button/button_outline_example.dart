import 'package:coui_flutter/coui_flutter.dart';

class ButtonOutlineExample extends StatefulWidget {
  const ButtonOutlineExample({super.key});

  @override
  State<ButtonOutlineExample> createState() => _ButtonOutlineExampleState();
}

class _ButtonOutlineExampleState extends State<ButtonOutlineExample> {
  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {},
      child: Text('외곽선').lineLimit(1).ellipsis,
    );
  }
}
