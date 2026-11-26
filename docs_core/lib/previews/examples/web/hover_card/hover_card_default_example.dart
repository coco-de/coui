import 'package:coui_web/coui_web.dart';

/// Default HoverCard example for docs_site Web preview.
class HoverCardDefaultExample extends StatelessComponent {
  const HoverCardDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return HoverCard(
      trigger: const Text('@coui').bodyMedium.onPrimaryContainer.underline,
      content: const Text('크로스 플랫폼 UI 디자인 시스템.').bodySmall.onSurface,
      placement: CorePopoverPlacement.bottom,
    );
  }
}
