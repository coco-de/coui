import 'package:coui_flutter/coui_flutter.dart';

class DisclosureBadgeDefaultExample extends StatelessWidget {
  const DisclosureBadgeDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const DisclosureBadge(
      kind: CoreDisclosureKind.open,
      label: '근거 공개',
    );
  }
}
