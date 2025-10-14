import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs/pages/docs/components_page.dart';

class AlertTile extends StatelessWidget implements IComponentPage {
  const AlertTile({super.key});

  @override
  String get title => 'Alert';

  @override
  Widget build(BuildContext context) {
    return const ComponentCard(
      name: 'alert',
      title: 'Alert',
      example: Alert(
        content: Text('This is an alert.'),
        leading: Icon(Icons.info_outline),
        title: Text('Alert'),
      ),
      center: true,
    );
  }
}
