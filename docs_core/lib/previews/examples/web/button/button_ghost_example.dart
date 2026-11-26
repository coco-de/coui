import 'package:coui_web/coui_web.dart';

class ButtonGhostExample extends StatefulComponent {
  const ButtonGhostExample({super.key});

  @override
  State<ButtonGhostExample> createState() => _ButtonGhostExampleState();
}

class _ButtonGhostExampleState extends State<ButtonGhostExample> {
  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.ghost,
      onPressed: () {},
      child: Text('고스트').lineLimit(1).ellipsis,
    );
  }
}
