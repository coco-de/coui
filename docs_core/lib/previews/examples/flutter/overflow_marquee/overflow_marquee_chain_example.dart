import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreOverflowMarqueeStyle] slot without constructing the
/// widget from scratch.
class OverflowMarqueeChainExample extends StatelessWidget {
  /// Creates an [OverflowMarqueeChainExample].
  const OverflowMarqueeChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space240,
      child:
          OverflowMarquee(
            pauseOnHover: true,
            child: Text(
              '상자 폭을 넘는 긴 제목은 옆으로 흘러가며 끝까지 보여요.',
            ).bodyMedium.onSurface,
          ).withStyle(
            const CoreOverflowMarqueeStyle(
              duration: Duration(milliseconds: CoreDuration.ms5000),
              delayDuration: Duration(milliseconds: CoreDuration.slow),
              fadePortion: CoreSpace.space48,
            ),
          ),
    );
  }
}
