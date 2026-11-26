import 'package:coui_web/coui_web.dart';

class StatusErrorExample extends StatefulComponent {
  const StatusErrorExample({super.key});

  @override
  State<StatusErrorExample> createState() => _StatusErrorExampleState();
}

class _StatusErrorExampleState extends State<StatusErrorExample> {
  @override
  Component build(BuildContext context) {
    return Status(
      color: CoreStatusColor.error,
      size: CoreStatusSize.lg,
    );
  }
}
