import 'package:coui_flutter/coui_flutter.dart';

/// Default horizontal [OverflowMarquee].
class OverflowMarqueeDefaultExample extends StatelessWidget {
  /// Creates an [OverflowMarqueeDefaultExample].
  const OverflowMarqueeDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ts = theme.typography;
    return SizedBox(
      width: CoreSpace.space240,
      child: OverflowMarquee(
        pauseOnHover: true,
        child: DefaultTextStyle.merge(
          style: ts.bodyMedium.toValue(theme: Theme.of(context)).copyWith(color: cs.onSurface.toValue()),
          child: const Text(
            '상자 폭을 넘는 긴 제목은 옆으로 흘러가며 끝까지 보여요.',
          ),
        ),
      ),
    );
  }
}
