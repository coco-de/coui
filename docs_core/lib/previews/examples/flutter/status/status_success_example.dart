import 'package:coui_flutter/coui_flutter.dart';

class StatusSuccessExample extends StatefulWidget {
  const StatusSuccessExample({super.key});

  @override
  State<StatusSuccessExample> createState() => _StatusSuccessExampleState();
}

class _StatusSuccessExampleState extends State<StatusSuccessExample> {
  @override
  Widget build(BuildContext context) {
    return const Status(
      color: CoreStatusColor.success,
      size: CoreStatusSize.lg,
    );
  }
}
