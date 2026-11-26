import 'package:coui_flutter/coui_flutter.dart';

class ButtonPrimaryExample extends StatefulWidget {
  const ButtonPrimaryExample({super.key});

  @override
  State<ButtonPrimaryExample> createState() => _ButtonPrimaryExampleState();
}

class _ButtonPrimaryExampleState extends State<ButtonPrimaryExample> {
  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.primary,
      onPressed: () {},
      child: Text('기본').lineLimit(1).ellipsis,
    );
  }
}
