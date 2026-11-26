import 'package:coui_web/coui_web.dart';

class ButtonSecondaryExample extends StatefulComponent {
  const ButtonSecondaryExample({super.key});

  @override
  State<ButtonSecondaryExample> createState() => _ButtonSecondaryExampleState();
}

class _ButtonSecondaryExampleState extends State<ButtonSecondaryExample> {
  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.secondary,
      onPressed: () {},
      child: Text('보조').lineLimit(1).ellipsis,
    );
  }
}
