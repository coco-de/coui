import 'package:coui_web/coui_web.dart';

class ResponsiveGridDefaultExample extends StatelessComponent {
  const ResponsiveGridDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.colorScheme;
    final textClass = 'text-${CoreTextStyles.bodyMedium.name} text-${cs.onSurface}';
    return ResponsiveGrid(
      columns: 3,
      cellSpacing: CoreSpace.space16,
      children: [
        for (var i = 1; i <= 5; i += 1)
          Card(
            cardStyle: const CoreCardStyle(padding: CoreEdgeInsets.all(CoreSpace.space16)),
            child: div([Text('항목 $i')], classes: textClass),
          ),
      ],
    );
  }
}
