import 'package:coui_web/coui_web.dart';

class ButtonPrimaryExample extends StatefulComponent {
  const ButtonPrimaryExample({super.key});

  @override
  State<ButtonPrimaryExample> createState() => _ButtonPrimaryExampleState();
}

class _ButtonPrimaryExampleState extends State<ButtonPrimaryExample> {
  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.primary,
      onPressed: () {},
      child: Text('기본').lineLimit(1).ellipsis,
    );
  }
}
