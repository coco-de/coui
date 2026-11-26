import 'package:coui_web/coui_web.dart';

class TooltipDefaultExample extends StatefulComponent {
  const TooltipDefaultExample({super.key});

  @override
  State<TooltipDefaultExample> createState() => _TooltipDefaultExampleState();
}

class _TooltipDefaultExampleState extends State<TooltipDefaultExample> {
  @override
  Component build(BuildContext context) {
    return Tooltip(
      message: '링크 복사',
      position: CoreTooltipPosition.bottom,
      child: Button(
        variant: CoreButtonVariant.outline,
        onPressed: () {},
        child: Text('공유'),
      ),
    );
  }
}
