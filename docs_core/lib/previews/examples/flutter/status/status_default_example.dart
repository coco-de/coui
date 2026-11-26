import 'package:coui_flutter/coui_flutter.dart';

class StatusDefaultExample extends StatefulWidget {
  const StatusDefaultExample({super.key});

  @override
  State<StatusDefaultExample> createState() => _StatusDefaultExampleState();
}

class _StatusDefaultExampleState extends State<StatusDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return const Status(
      color: CoreStatusColor.primary,
      size: CoreStatusSize.lg,
    );
  }
}
