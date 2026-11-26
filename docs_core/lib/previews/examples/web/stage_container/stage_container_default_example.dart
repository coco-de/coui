import 'package:coui_web/coui_web.dart';

/// Default preview for `StageContainer` on Web. Mirrors the Flutter
/// counterpart token-for-token — uses the same Bootstrap-style breakpoints
/// (576/768/992/1200/1400) and renders a height-80 surface-container box
/// showing the resolved left/right padding.
class StageContainerDefaultExample extends StatelessComponent {
  const StageContainerDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final boxClasses =
        'h-${CoreSpace.scale.space80} '
        'flex items-center justify-center '
        'bg-${cs.surfaceContainer} border border-${cs.outline} '
        'rounded-${CoreRadius.scale.radius16} '
        'text-${CoreTextStyles.bodyMedium.name} text-${cs.onSurface}';
    return StageContainer(
      builder: (context, padding) {
        return div(
          [
            Text(
              '왼쪽: ${padding.left.toStringAsFixed(0)}, '
              '오른쪽: ${padding.right.toStringAsFixed(0)}',
            ),
          ],
          classes: boxClasses,
        );
      },
    );
  }
}
