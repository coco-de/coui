import 'package:coui_web/coui_web.dart';

class ChipGroupScrollExample extends StatefulComponent {
  const ChipGroupScrollExample({super.key});

  @override
  State<ChipGroupScrollExample> createState() => _ChipGroupScrollExampleState();
}

class _ChipGroupScrollExampleState extends State<ChipGroupScrollExample> {
  Set<String> _selected = const {};

  @override
  Component build(BuildContext context) {
    return ChipGroup<String>(
      items: const [
        '전체',
        '프런트엔드',
        '백엔드',
        '모바일',
        '디자인',
        'DevOps',
        '데이터',
        'AI/ML',
      ],
      layout: CoreChipGroupLayout.scroll,
      selectionMode: CoreChipGroupSelectionMode.single,
      initialValue: _selected,
      onChanged: (next) => setState(() => _selected = next),
      chipBuilder: (item, {required selected, required enabled, required onTap}) => Chip(
        label: item,
        selected: selected,
        enabled: enabled,
        chipColor: CoreChipColor.neutral,
        onTap: onTap,
      ),
    );
  }
}
