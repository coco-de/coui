import 'package:coui_flutter/coui_flutter.dart';

class DisclosureBadgeCommitmentExample extends StatelessWidget {
  const DisclosureBadgeCommitmentExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const DisclosureBadge(
      kind: CoreDisclosureKind.commitment,
      label: '계약 시 제공',
    );
  }
}
