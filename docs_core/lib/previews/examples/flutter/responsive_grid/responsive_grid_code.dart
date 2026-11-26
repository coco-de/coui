/// Returns a Flutter code snippet string for the ResponsiveGrid component.
String responsiveGridCode(String? variant) {
  return switch (variant) {
    'chain' =>
      r'''
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
}''',
    'span' =>
      r'''
class ResponsiveGridSpanExample extends StatelessWidget {
  const ResponsiveGridSpanExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.typography.bodyMedium.toValue(theme: theme).copyWith(
      color: theme.colorScheme.onSurface.toValue(),
    );
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
            child: Text('2열 차지', style: textStyle),
          ),
        ),
        Card(
          cardStyle: cardStyle,
          child: Text('셀', style: textStyle),
        ),
        Card(
          cardStyle: cardStyle,
          child: Text('셀', style: textStyle),
        ),
        GridItem(
          rowSpan: 2,
          child: Card(
            cardStyle: cardStyle,
            child: Text('2행 차지', style: textStyle),
          ),
        ),
        Card(
          cardStyle: cardStyle,
          child: Text('셀', style: textStyle),
        ),
        Card(
          cardStyle: cardStyle,
          child: Text('셀', style: textStyle),
        ),
        Card(
          cardStyle: cardStyle,
          child: Text('셀', style: textStyle),
        ),
      ],
    );
  }
}''',
    _ =>
      r'''
class ResponsiveGridDefaultExample extends StatelessWidget {
  const ResponsiveGridDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.typography.bodyMedium.toValue(theme: theme).copyWith(
      color: theme.colorScheme.onSurface.toValue(),
    );
    return ResponsiveGrid(
      columns: 3,
      cellSpacing: CoreSpace.space16,
      children: [
        for (var i = 1; i <= 5; i += 1)
          Card(
            cardStyle: const CoreCardStyle(
              padding: CoreEdgeInsets.all(CoreSpace.space16),
            ),
            child: Text('항목 $i', style: textStyle),
          ),
      ],
    );
  }
}''',
  };
}
