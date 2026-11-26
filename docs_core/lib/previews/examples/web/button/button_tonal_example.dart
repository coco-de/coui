import 'package:coui_web/coui_web.dart';

class ButtonTonalExample extends StatefulComponent {
  const ButtonTonalExample({super.key});

  @override
  State<ButtonTonalExample> createState() => _ButtonTonalExampleState();
}

class _ButtonTonalExampleState extends State<ButtonTonalExample> {
  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.tonal,
      onPressed: () {},
      child: Text('톤').lineLimit(1).ellipsis,
    );
  }
}
