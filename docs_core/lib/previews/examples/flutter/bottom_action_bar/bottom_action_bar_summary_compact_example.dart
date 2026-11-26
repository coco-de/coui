import 'package:coui_flutter/coui_flutter.dart';

class BottomActionBarSummaryCompactExample extends StatelessWidget {
  const BottomActionBarSummaryCompactExample({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomActionBar(
      layout: .summaryCompact,
      summaryLabel: const Text('총 금액'),
      summaryValue: const Text('64,000원'),
      primaryAction: Button(
        variant: .primary,
        size: .lg,
        onPressed: () {},
        child: const Text('결제하기'),
      ),
    );
  }
}
