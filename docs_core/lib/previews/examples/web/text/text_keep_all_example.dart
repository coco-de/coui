import 'package:coui_web/coui_web.dart';

/// Word-level line breaking — the same Korean title in the same narrow
/// column, without and with `.keepAll`.
class TextKeepAllExample extends StatelessComponent {
  const TextKeepAllExample({super.key});

  static const _title = '리포머 심화 플로우와 회복 스트레칭';

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'flex flex-col gap-${CoreSpace.scale.space24} p-${CoreSpace.scale.space16}',
      [
        _section('기본 줄바꿈 — 음절 사이', const Text(_title).bodyMedium),
        _section('.keepAll — 어절 사이', const Text(_title).bodyMedium.keepAll),
      ],
    );
  }

  Component _section(String title, Component text) {
    return div(
      classes: 'flex flex-col gap-${CoreSpace.scale.space8}',
      [
        Text(title).labelMedium.onSurfaceVariant,
        div(
          styles: Styles(raw: {'width': '${CoreSpace.space200}px'}),
          [text],
        ),
      ],
    );
  }
}
