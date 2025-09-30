import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs/pages/docs/components_page.dart';

class AlertDialogTile extends StatelessWidget implements IComponentPage {
  const AlertDialogTile({super.key});

  @override
  String get title => 'Alert Dialog';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'alert_dialog',
      title: 'Alert Dialog',
      center: true,
      example: AlertDialog(
        title: const Text('Alert Dialog'),
        content: const Text('This is an alert dialog.'),
        actions: [
          SecondaryButton(
              onPressed: () {
                // TODOS: will be implemented later.
              },
              child: const Text('Cancel')),
          PrimaryButton(
              onPressed: () {
                // TODOS: will be implemented later.
              },
              child: const Text('OK')),
        ],
      ),
    );
  }
}
