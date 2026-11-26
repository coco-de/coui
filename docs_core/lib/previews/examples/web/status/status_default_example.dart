import 'package:coui_web/coui_web.dart';

class StatusDefaultExample extends StatefulComponent {
  const StatusDefaultExample({super.key});

  @override
  State<StatusDefaultExample> createState() => _StatusDefaultExampleState();
}

class _StatusDefaultExampleState extends State<StatusDefaultExample> {
  @override
  Component build(BuildContext context) {
    return Status(
      color: CoreStatusColor.primary,
      size: CoreStatusSize.lg,
    );
  }
}
