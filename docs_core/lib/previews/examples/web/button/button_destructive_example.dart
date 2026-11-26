import 'package:coui_web/coui_web.dart';

class ButtonDestructiveExample extends StatefulComponent {
  const ButtonDestructiveExample({super.key});

  @override
  State<ButtonDestructiveExample> createState() => _ButtonDestructiveExampleState();
}

class _ButtonDestructiveExampleState extends State<ButtonDestructiveExample> {
  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.destructive,
      onPressed: () {},
      child: Text('삭제').lineLimit(1).ellipsis,
    );
  }
}
