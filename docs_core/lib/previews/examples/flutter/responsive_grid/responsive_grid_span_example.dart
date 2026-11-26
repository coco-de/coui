import 'package:coui_flutter/coui_flutter.dart';

class ResponsiveGridSpanExample extends StatelessWidget {
  const ResponsiveGridSpanExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.typography.bodyMedium
        .toValue(theme: theme)
        .copyWith(
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
}
