import 'package:coui_flutter/coui_flutter.dart';

/// Default HoverCard example for docs_site Flutter preview.
class HoverCardDefaultExample extends StatefulWidget {
  const HoverCardDefaultExample({super.key});

  @override
  State<HoverCardDefaultExample> createState() => _HoverCardDefaultExampleState();
}

class _HoverCardDefaultExampleState extends State<HoverCardDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return HoverCard(
      trigger: const Text('@coui').bodyMedium.onPrimaryContainer.underline,
      content: const Text('크로스 플랫폼 UI 디자인 시스템.').bodySmall.onSurface,
      placement: CorePopoverPlacement.bottom,
    );
  }
}
