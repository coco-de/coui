import 'package:coui_flutter/coui_flutter.dart';

/// Solid-emphasis Banner example for docs_site Flutter preview.
///
/// `emphasis` is Banner's second axis: `variant` says what kind of message
/// this is, `emphasis` says how hard it presses. `solid` fills with the
/// tone's own colour instead of its tinted container and drops the hairline
/// rule.
///
/// It is deliberately reserved for messages a user genuinely cannot be
/// allowed to miss — outages, forced maintenance. Spending it on ordinary
/// information wears the signal out, and then it is not available when
/// something actually is urgent. Hence the outage copy here rather than a
/// generic notice.
class BannerSolidExample extends StatefulWidget {
  const BannerSolidExample({super.key});

  @override
  State<BannerSolidExample> createState() => _BannerSolidExampleState();
}

class _BannerSolidExampleState extends State<BannerSolidExample> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    if (_show) {
      return Banner(
        variant: CoreBannerVariant.destructive,
        emphasis: CoreBannerEmphasis.solid,
        message: const Text('지금은 결제를 할 수 없어요.'),
        description: const Text('복구하고 있어요. 따로 하실 일은 없어요.'),
        onDismiss: () => setState(() => _show = false),
      );
    }
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () => setState(() => _show = true),
      child: const Text('배너 보기'),
    );
  }
}
