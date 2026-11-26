/// Returns a Web code snippet string for the ResponsiveGrid component.
String responsiveGridCode(String? variant) {
  return switch (variant) {
    'chain' =>
      r'''
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
}''',
    'span' =>
      r'''
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
}''',
    _ =>
      r'''
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
}''',
  };
}
