import 'package:coui_flutter/coui_flutter.dart';

class ButtonGhostExample extends StatefulWidget {
  const ButtonGhostExample({super.key});

  @override
  State<ButtonGhostExample> createState() => _ButtonGhostExampleState();
}

class _ButtonGhostExampleState extends State<ButtonGhostExample> {
  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.ghost,
      onPressed: () {},
      child: Text('고스트').lineLimit(1).ellipsis,
    );
  }
}
