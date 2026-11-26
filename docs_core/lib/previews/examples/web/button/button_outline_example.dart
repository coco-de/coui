import 'package:coui_web/coui_web.dart';

class ButtonOutlineExample extends StatefulComponent {
  const ButtonOutlineExample({super.key});

  @override
  State<ButtonOutlineExample> createState() => _ButtonOutlineExampleState();
}

class _ButtonOutlineExampleState extends State<ButtonOutlineExample> {
  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {},
      child: Text('외곽선').lineLimit(1).ellipsis,
    );
  }
}
