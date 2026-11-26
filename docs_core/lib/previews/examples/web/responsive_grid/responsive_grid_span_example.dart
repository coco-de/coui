import 'package:coui_web/coui_web.dart';

class ResponsiveGridSpanExample extends StatelessComponent {
  const ResponsiveGridSpanExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.colorScheme;
    final textClass = 'text-${CoreTextStyles.bodyMedium.name} text-${cs.onSurface}';
    const cardStyle = CoreCardStyle(
      padding: CoreEdgeInsets.all(CoreSpace.space16),
    );
    return ResponsiveGrid(
      columns: 4,
      cellSpacing: CoreSpace.space16,
      responsive: false,
      children: [
        GridItem(
          colSpan: 2,
          child: Card(
            cardStyle: cardStyle,
            child: div(
              [Text('2열 차지')],
              classes: textClass,
            ),
          ),
        ),
        Card(
          cardStyle: cardStyle,
          child: div([Text('셀')], classes: textClass),
        ),
        Card(
          cardStyle: cardStyle,
          child: div([Text('셀')], classes: textClass),
        ),
        GridItem(
          rowSpan: 2,
          child: Card(
            cardStyle: cardStyle,
            child: div(
              [Text('2행 차지')],
              classes: textClass,
            ),
          ),
        ),
        Card(
          cardStyle: cardStyle,
          child: div([Text('셀')], classes: textClass),
        ),
        Card(
          cardStyle: cardStyle,
          child: div([Text('셀')], classes: textClass),
        ),
        Card(
          cardStyle: cardStyle,
          child: div([Text('셀')], classes: textClass),
        ),
      ],
    );
  }
}
