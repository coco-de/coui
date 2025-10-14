import 'package:coui_flutter/coui_flutter.dart';

class TooltipExample1 extends StatelessWidget {
  const TooltipExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      tooltip: const TooltipContainer(child: Text('This is a tooltip.')),
      child: PrimaryButton(
        child: const Text('Hover over me'),
        onPressed: () {
          // TODOS: will be implemented later.
        },
      ),
    );
  }
}
