import 'package:coui_flutter/coui_flutter.dart';

class LayoutPageExample7 extends StatelessWidget {
  const LayoutPageExample7({super.key});

  @override
  Widget build(BuildContext context) {
    return const Basic(
      content: Text('Lorem ipsum dolor sit amet'),
      leading: Icon(Icons.star),
      subtitle: Text('Subtitle'),
      title: Text('Title'),
      trailing: Icon(Icons.arrow_forward),
    );
  }
}
