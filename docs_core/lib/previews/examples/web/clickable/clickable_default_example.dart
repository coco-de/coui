import 'package:coui_web/coui_web.dart';

class ClickableDefaultExample extends StatelessComponent {
  const ClickableDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Clickable(
      onPressed: () {},
      child: Card(child: Text('클릭 가능한 영역').bodyMedium),
    );
  }
}
