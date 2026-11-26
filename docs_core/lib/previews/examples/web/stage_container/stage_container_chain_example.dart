import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain-sugar quick-override pattern: build a
/// `StageContainer` normally, then patch its `CoreStageContainerStyle` after
/// the fact instead of passing `stageContainerStyle:` in the constructor.
/// Here `.withStyle` swaps the Bootstrap ladder for a constant 256px grid
/// and narrows the default 72px horizontal padding down to 32px.
class StageContainerChainExample extends StatelessComponent {
  const StageContainerChainExample({super.key});

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
    ).withStyle(
      const CoreStageContainerStyle(
        breakpoint: CoreConstantStageBreakpoint(CoreSpace.space256),
        padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space32),
      ),
    );
  }
}
