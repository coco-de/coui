import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates radius and explicit paint on [Stat].
class StatChainExample extends StatefulWidget {
  const StatChainExample({super.key});

  @override
  State<StatChainExample> createState() => _StatChainExampleState();
}

class _StatChainExampleState extends State<StatChainExample> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        const Stat(
          label: '총매출',
          value: '4,523만 원',
          change: '+20.1%',
          changeType: CoreStatChangeType.positive,
        ).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        const Stat(
          label: '총매출',
          value: '4,523만 원',
          change: '+20.1%',
          changeType: CoreStatChangeType.positive,
        ).withStyle(
          const CoreStatStyle(
            backgroundColor: .tertiary,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
            ),
          ),
        ),
      ],
    );
  }
}
