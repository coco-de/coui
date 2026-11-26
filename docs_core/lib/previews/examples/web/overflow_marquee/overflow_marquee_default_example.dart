import 'package:coui_web/coui_web.dart';

/// Default horizontal [OverflowMarquee].
class OverflowMarqueeDefaultExample extends StatelessComponent {
  /// Creates an [OverflowMarqueeDefaultExample].
  const OverflowMarqueeDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return div(
      styles: Styles(raw: {'width': '${CoreSpace.space240}px'}),
      [
        OverflowMarquee(
          pauseOnHover: true,
          child: div(
            classes: 'text-${CoreTextStyles.bodyMedium.name} text-${cs.onSurface}',
            [
              Text(
                '상자 폭을 넘는 긴 제목은 옆으로 흘러가며 끝까지 보여요.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
