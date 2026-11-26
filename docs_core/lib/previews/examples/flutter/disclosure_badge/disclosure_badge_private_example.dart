import 'package:coui_flutter/coui_flutter.dart';

class DisclosureBadgePrivateExample extends StatelessWidget {
  const DisclosureBadgePrivateExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const DisclosureBadge(
      kind: CoreDisclosureKind.private,
      label: '비공개 · NDA',
    );
  }
}
