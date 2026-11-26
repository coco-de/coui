import 'package:coui_flutter/coui_flutter.dart';

class StatusWarningExample extends StatefulWidget {
  const StatusWarningExample({super.key});

  @override
  State<StatusWarningExample> createState() => _StatusWarningExampleState();
}

class _StatusWarningExampleState extends State<StatusWarningExample> {
  @override
  Widget build(BuildContext context) {
    return const Status(
      color: CoreStatusColor.warning,
      size: CoreStatusSize.lg,
    );
  }
}
