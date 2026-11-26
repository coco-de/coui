import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreResponsiveGridStyle] slot without constructing the
/// component from scratch. The grid keeps the default example's cells
/// and routes `columns` / `cellSpacing` / `responsive` through the
/// single style slot instead of flat component params.
class ResponsiveGridChainExample extends StatelessComponent {
  const ResponsiveGridChainExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.colorScheme;
    final textClass = 'text-${CoreTextStyles.bodyMedium.name} text-${cs.onSurface}';
    return ResponsiveGrid(
      children: [
        for (var i = 1; i <= 5; i += 1)
          Card(
            cardStyle: const CoreCardStyle(
              padding: CoreEdgeInsets.all(CoreSpace.space16),
            ),
            child: div([Text('항목 $i')], classes: textClass),
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
