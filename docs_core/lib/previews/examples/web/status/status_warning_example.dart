import 'package:coui_web/coui_web.dart';

class StatusWarningExample extends StatefulComponent {
  const StatusWarningExample({super.key});

  @override
  State<StatusWarningExample> createState() => _StatusWarningExampleState();
}

class _StatusWarningExampleState extends State<StatusWarningExample> {
  @override
  Component build(BuildContext context) {
    return Status(
      color: CoreStatusColor.warning,
      size: CoreStatusSize.lg,
    );
  }
}
