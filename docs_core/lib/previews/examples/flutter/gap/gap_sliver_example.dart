import 'package:coui_flutter/coui_flutter.dart';

class GapSliverExample extends StatelessWidget {
  const GapSliverExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.typography.bodyMedium
        .toValue(theme: theme)
        .copyWith(
          color: theme.colorScheme.onSurface.toValue(),
        );
    return SizedBox(
      height: 160,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: Text('위 항목', style: textStyle)),
          const SliverGap.space24(),
          SliverToBoxAdapter(child: Text('가운데 항목', style: textStyle)),
          const SliverGap.space24(),
          SliverToBoxAdapter(child: Text('아래 항목', style: textStyle)),
        ],
      ),
    );
  }
}
