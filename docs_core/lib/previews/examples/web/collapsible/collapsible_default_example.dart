import 'package:coui_web/coui_web.dart';

class CollapsibleDefaultExample extends StatelessComponent {
  const CollapsibleDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Collapsible(
      trigger: Text('고급 설정'),
      content: Text(
        '고급 사용자를 위한 옵션이에요.',
      ),
      expanded: true,
    );
  }
}
