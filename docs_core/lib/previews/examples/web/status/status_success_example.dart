import 'package:coui_web/coui_web.dart';

class StatusSuccessExample extends StatefulComponent {
  const StatusSuccessExample({super.key});

  @override
  State<StatusSuccessExample> createState() => _StatusSuccessExampleState();
}

class _StatusSuccessExampleState extends State<StatusSuccessExample> {
  @override
  Component build(BuildContext context) {
    return Status(
      color: CoreStatusColor.success,
      size: CoreStatusSize.lg,
    );
  }
}
