import 'package:coui_flutter/coui_flutter.dart';

class StatusErrorExample extends StatefulWidget {
  const StatusErrorExample({super.key});

  @override
  State<StatusErrorExample> createState() => _StatusErrorExampleState();
}

class _StatusErrorExampleState extends State<StatusErrorExample> {
  @override
  Widget build(BuildContext context) {
    return const Status(
      color: CoreStatusColor.error,
      size: CoreStatusSize.lg,
    );
  }
}
