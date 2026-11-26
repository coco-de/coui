import 'package:coui_web/coui_web.dart';

class DisclosureBadgeCommitmentExample extends StatelessComponent {
  const DisclosureBadgeCommitmentExample({super.key});

  @override
  Component build(BuildContext context) {
    return const DisclosureBadge(
      kind: CoreDisclosureKind.commitment,
      label: '계약 시 제공',
    );
  }
}
