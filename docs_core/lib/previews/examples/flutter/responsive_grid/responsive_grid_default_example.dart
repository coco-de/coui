import 'package:coui_flutter/coui_flutter.dart';

class ResponsiveGridDefaultExample extends StatelessWidget {
  const ResponsiveGridDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.typography.bodyMedium
        .toValue(theme: theme)
        .copyWith(
          color: theme.colorScheme.onSurface.toValue(),
        );
    return ResponsiveGrid(
      columns: 3,
      cellSpacing: CoreSpace.space16,
      children: [
        for (var i = 1; i <= 5; i += 1)
          Card(child: Text('항목 $i', style: textStyle)).contentPadding(.all(CoreSpace.space16)),
      ],
    );
  }
}
