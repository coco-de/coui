import 'package:coui_web/coui_web.dart';

class DisclosureBadgeDefaultExample extends StatelessComponent {
  const DisclosureBadgeDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return const DisclosureBadge(
      kind: CoreDisclosureKind.open,
      label: '근거 공개',
    );
  }
}
