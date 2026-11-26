import 'package:coui_flutter/coui_flutter.dart';

/// Word-level line breaking — the same Korean title in the same narrow
/// column, without and with `.keepAll`.
class TextKeepAllExample extends StatelessWidget {
  const TextKeepAllExample({super.key});

  static const _title = '리포머 심화 플로우와 회복 스트레칭';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(CoreSpace.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: CoreSpace.space24,
        children: [
          _section('기본 줄바꿈 — 음절 사이', const Text(_title).bodyMedium),
          _section(
            '.keepAll — 어절 사이',
            const Text(_title).bodyMedium.keepAll,
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Widget text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: CoreSpace.space8,
      children: [
        Text(title).labelMedium.onSurfaceVariant,
        SizedBox(width: CoreSpace.space200, child: text),
      ],
    );
  }
}
