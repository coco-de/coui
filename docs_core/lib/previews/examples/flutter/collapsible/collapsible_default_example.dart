import 'package:coui_flutter/coui_flutter.dart';

class CollapsibleDefaultExample extends StatelessWidget {
  const CollapsibleDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Collapsible(
      trigger: Text('고급 설정'),
      content: Text(
        '고급 사용자를 위한 옵션이에요.',
      ),
      expanded: true,
    );
  }
}
