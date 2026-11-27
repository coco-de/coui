import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates radius and explicit paint on [Chip].
class ChipChainExample extends StatefulWidget {
  const ChipChainExample({super.key});

  @override
  State<ChipChainExample> createState() => _ChipChainExampleState();
}

class _ChipChainExampleState extends State<ChipChainExample> {
  bool _comboSelected = false;
  bool _fullSelected = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        Chip(
          label: '디자인',
          selected: _comboSelected,
          onTap: () => setState(() => _comboSelected = !_comboSelected),
        ).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        Chip(
          label: '직접 지정',
          selected: _fullSelected,
          onTap: () => setState(() => _fullSelected = !_fullSelected),
        ).withStyle(
          const CoreChipStyle(
            backgroundColor: .tertiaryContainer,
            foregroundColor: .onTertiaryContainer,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space12,
              vertical: CoreSpace.space4,
            ),
          ),
        ),
      ],
    );
  }
}
