import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain-sugar quick-override pattern: build a
/// `StageContainer` normally, then patch its `CoreStageContainerStyle` after
/// the fact instead of passing `stageContainerStyle:` in the constructor.
/// Here `.withStyle` swaps the Bootstrap ladder for a constant 256px grid
/// and narrows the default 72px horizontal padding down to 32px.
class StageContainerChainExample extends StatelessWidget {
  const StageContainerChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StageContainer(
      builder: (context, padding) {
        return Padding(
          padding: padding.toValue(),
          child: Container(
            height: CoreSpace.space80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer.toValue(),
              borderRadius: BorderRadius.circular(CoreRadius.radius16),
              border: Border.all(color: theme.colorScheme.outline.toValue()),
            ),
            child: Text(
              '왼쪽: ${padding.left.toStringAsFixed(0)}, '
              '오른쪽: ${padding.right.toStringAsFixed(0)}',
              style: theme.typography.bodyMedium
                  .toValue(theme: theme)
                  .copyWith(
                    color: theme.colorScheme.onSurface.toValue(),
                  ),
            ),
          ),
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
