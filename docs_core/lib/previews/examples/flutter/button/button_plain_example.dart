import 'package:coui_flutter/coui_flutter.dart';

class ButtonPlainExample extends StatefulWidget {
  const ButtonPlainExample({super.key});

  @override
  State<ButtonPlainExample> createState() => _ButtonPlainExampleState();
}

class _ButtonPlainExampleState extends State<ButtonPlainExample> {
  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.plain,
      onPressed: () {},
      child: Text('플레인').lineLimit(1).ellipsis,
    );
  }
}
