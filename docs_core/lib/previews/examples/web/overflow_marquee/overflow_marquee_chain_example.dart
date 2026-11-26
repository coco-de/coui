import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreOverflowMarqueeStyle] slot without constructing the
/// component from scratch.
class OverflowMarqueeChainExample extends StatelessComponent {
  /// Creates an [OverflowMarqueeChainExample].
  const OverflowMarqueeChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(raw: {'width': '${CoreSpace.space240}px'}),
      [
        OverflowMarquee(
          pauseOnHover: true,
          child: const Text(
            '상자 폭을 넘는 긴 제목은 옆으로 흘러가며 끝까지 보여요.',
          ).bodyMedium.onSurface,
        ).withStyle(
          const CoreOverflowMarqueeStyle(
            duration: Duration(milliseconds: CoreDuration.ms5000),
            delayDuration: Duration(milliseconds: CoreDuration.slow),
            fadePortion: CoreSpace.space48,
          ),
        ),
      ],
    );
  }
}
