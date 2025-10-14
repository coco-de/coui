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
      example: AlertDialog(
        actions: [
          SecondaryButton(
            child: const Text('Cancel'),
            onPressed: () {
              // TODOS: will be implemented later.
            },
          ),
          PrimaryButton(
            child: const Text('OK'),
            onPressed: () {
              // TODOS: will be implemented later.
            },
          ),
        ],
        content: const Text('This is an alert dialog.'),
        title: const Text('Alert Dialog'),
      ),
      center: true,
    );
  }
}
