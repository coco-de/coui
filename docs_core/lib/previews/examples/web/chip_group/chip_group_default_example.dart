import 'package:coui_web/coui_web.dart';

class ChipGroupDefaultExample extends StatefulComponent {
  const ChipGroupDefaultExample({super.key});

  @override
  State<ChipGroupDefaultExample> createState() => _ChipGroupDefaultExampleState();
}

class _ChipGroupDefaultExampleState extends State<ChipGroupDefaultExample> {
  Set<String> _selected = const {'Flutter'};

  @override
  Component build(BuildContext context) {
    return ChipGroup<String>(
      items: const ['Flutter', 'React', 'Swift', 'Kotlin'],
      initialValue: _selected,
      selectionMode: CoreChipGroupSelectionMode.multi,
      onChanged: (next) => setState(() => _selected = next),
      chipBuilder: (item, {required selected, required enabled, required onTap}) => Chip(
        label: item,
        selected: selected,
        enabled: enabled,
        chipColor: CoreChipColor.primary,
        onTap: onTap,
      ),
    );
  }
}
