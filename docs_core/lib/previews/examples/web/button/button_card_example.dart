import 'package:coui_web/coui_web.dart';

class ButtonCardExample extends StatefulComponent {
  const ButtonCardExample({super.key});

  @override
  State<ButtonCardExample> createState() => _ButtonCardExampleState();
}

class _ButtonCardExampleState extends State<ButtonCardExample> {
  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {},
      child: Text('카드').lineLimit(1).ellipsis,
    ).withStyle(
      const CoreButtonStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
      ),
    );
  }
}
