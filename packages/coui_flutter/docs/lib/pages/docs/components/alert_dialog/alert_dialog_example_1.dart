import 'package:coui_flutter/coui_flutter.dart';

class AlertDialogExample1 extends StatelessWidget {
  const AlertDialogExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      child: const Text('Click Here'),
      onPressed: () {
        showDialog(
          builder: (context) {
            return AlertDialog(
              actions: [
                OutlineButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                PrimaryButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
              content: const Text(
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
              ),
              title: const Text('Alert title'),
            );
          },
          context: context,
        );
      },
    );
  }
}
