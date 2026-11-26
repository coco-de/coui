import 'package:coui_flutter/coui_flutter.dart';

class TooltipDefaultExample extends StatefulWidget {
  const TooltipDefaultExample({super.key});

  @override
  State<TooltipDefaultExample> createState() => _TooltipDefaultExampleState();
}

class _TooltipDefaultExampleState extends State<TooltipDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '링크 복사',
      position: CoreTooltipPosition.bottom,
      child: Button(
        variant: CoreButtonVariant.outline,
        onPressed: () {},
        child: const Text('공유'),
      ),
    );
  }
}
