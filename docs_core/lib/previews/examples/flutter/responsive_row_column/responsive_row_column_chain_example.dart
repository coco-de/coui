import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreResponsiveRowColumnStyle] slot without constructing
/// the widget from scratch. The three `Card` panels stay identical to
/// the default example; `spacing` / `mainAxisAlignment` /
/// `crossAxisAlignment` now flow through the single style slot.
class ResponsiveRowColumnChainExample extends StatelessWidget {
  const ResponsiveRowColumnChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveRowColumn(
      children: [
        _StatCard(label: '조회수', value: '1,204'),
        _StatCard(label: '좋아요', value: '86'),
        _StatCard(label: '댓글', value: '12'),
      ],
    ).withStyle(
      const CoreResponsiveRowColumnStyle(
        spacing: CoreSpace.space24,
        mainAxisAlignment: CoreMainAxisAlignment.center,
        crossAxisAlignment: CoreCrossAxisAlignment.start,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      cardStyle: const CoreCardStyle(
        padding: CoreEdgeInsets.all(CoreSpace.space16),
      ),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Text(value).titleMedium.semiBold.onSurface,
          Text(label).bodyMedium.onSurfaceVariant,
        ],
      ),
    );
  }
}
