import 'package:coui_flutter/coui_flutter.dart';

class ButtonTonalExample extends StatefulWidget {
  const ButtonTonalExample({super.key});

  @override
  State<ButtonTonalExample> createState() => _ButtonTonalExampleState();
}

class _ButtonTonalExampleState extends State<ButtonTonalExample> {
  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.tonal,
      onPressed: () {},
      child: Text('톤').lineLimit(1).ellipsis,
    );
  }
}
