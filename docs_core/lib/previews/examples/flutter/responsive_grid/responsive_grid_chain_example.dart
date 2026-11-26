import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreResponsiveGridStyle] slot without constructing the
/// widget from scratch. The grid keeps the default example's cells and
/// routes `columns` / `cellSpacing` / `responsive` through the single
/// style slot instead of flat widget params.
class ResponsiveGridChainExample extends StatelessWidget {
  const ResponsiveGridChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.typography.bodyMedium
        .toValue(theme: theme)
        .copyWith(
          color: theme.colorScheme.onSurface.toValue(),
        );
    return ResponsiveGrid(
      children: [
        for (var i = 1; i <= 5; i += 1)
          Card(
            cardStyle: const CoreCardStyle(
              padding: CoreEdgeInsets.all(CoreSpace.space16),
            ),
            child: Text('항목 $i', style: textStyle),
          ),
      ],
    ).withStyle(
      const CoreResponsiveGridStyle(
        columns: 2,
        cellSpacing: CoreSpace.space24,
        responsive: false,
      ),
    );
  }
}
