import 'package:coui_flutter/coui_flutter.dart';

class ClickableDefaultExample extends StatelessWidget {
  const ClickableDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Clickable(
      onPressed: () {},
      child: Card(child: Text('클릭 가능한 영역').bodyMedium),
    );
  }
}
