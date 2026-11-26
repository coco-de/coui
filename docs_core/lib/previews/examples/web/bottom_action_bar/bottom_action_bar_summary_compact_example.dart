import 'package:coui_web/coui_web.dart';

class BottomActionBarSummaryCompactExample extends StatelessComponent {
  const BottomActionBarSummaryCompactExample({super.key});

  @override
  Component build(BuildContext context) {
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
