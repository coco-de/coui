import 'package:coui_web/coui_web.dart';

class ButtonPlainExample extends StatefulComponent {
  const ButtonPlainExample({super.key});

  @override
  State<ButtonPlainExample> createState() => _ButtonPlainExampleState();
}

class _ButtonPlainExampleState extends State<ButtonPlainExample> {
  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.plain,
      onPressed: () {},
      child: Text('플레인').lineLimit(1).ellipsis,
    );
  }
}
