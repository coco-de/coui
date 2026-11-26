import 'package:coui_web/coui_web.dart';

class DisclosureBadgePrivateExample extends StatelessComponent {
  const DisclosureBadgePrivateExample({super.key});

  @override
  Component build(BuildContext context) {
    return const DisclosureBadge(
      kind: CoreDisclosureKind.private,
      label: '비공개 · NDA',
    );
  }
}
