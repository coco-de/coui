import 'package:coui_flutter/coui_flutter.dart';

class AlertExample1 extends StatelessWidget {
  const AlertExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return const Alert(
      content: Text('This is alert content.'),
      leading: Icon(Icons.info_outline),
      title: Text('Alert title'),
    );
  }
}
