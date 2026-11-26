import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreChipGroupStyle] slot without constructing the
/// component from scratch.
class ChipGroupChainExample extends StatefulComponent {
  const ChipGroupChainExample({super.key});

  @override
  State<ChipGroupChainExample> createState() => _ChipGroupChainExampleState();
}

class _ChipGroupChainExampleState extends State<ChipGroupChainExample> {
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
    ).withStyle(
      const CoreChipGroupStyle(
        itemSpacing: CoreSpace.space12,
        rowSpacing: CoreSpace.space12,
        titleGapStyle: CoreGapStyle(size: CoreSpace.space8),
        titleTextStyle: CoreTextStyle.token(
          CoreTextStyles.labelLarge,
          color: CoreColor.token(CoreColors.onSurfaceVariant),
        ),
      ),
    );
  }
}
