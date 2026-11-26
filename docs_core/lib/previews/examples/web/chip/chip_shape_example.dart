import 'package:coui_web/coui_web.dart';

class ChipShapeExample extends StatefulComponent {
  const ChipShapeExample({super.key});

  @override
  State<ChipShapeExample> createState() => _ChipShapeExampleState();
}

class _ChipShapeExampleState extends State<ChipShapeExample> {
  static const _labels = ['전체', 'USD', 'JPY', 'EUR'];

  String _picked = '전체';

  @override
  Component build(BuildContext context) {
    // 알약 칩 — 양 끝이 반원. 필터 · 정렬 · 통화 줄에 쓰고, 하나만 켜진다.
    return div(
      [
        for (final label in _labels)
          Chip(
            label: label,
            shape: CoreChipShape.pill,
            selected: _picked == label,
            onTap: () => setState(() => _picked = label),
          ),
      ],
      classes: 'flex flex-row items-center gap-${CoreSpace.scale.space8}',
    );
  }
}
