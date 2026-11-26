import 'package:coui_flutter/coui_flutter.dart';

class ButtonSecondaryExample extends StatefulWidget {
  const ButtonSecondaryExample({super.key});

  @override
  State<ButtonSecondaryExample> createState() => _ButtonSecondaryExampleState();
}

class _ButtonSecondaryExampleState extends State<ButtonSecondaryExample> {
  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.secondary,
      onPressed: () {},
      child: Text('보조').lineLimit(1).ellipsis,
    );
  }
}
