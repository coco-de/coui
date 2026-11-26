import 'package:coui_web/coui_web.dart';

/// Default [ResponsiveRowColumn] — three `Card` panels render as a
/// `Row` at or above the `tablet` breakpoint tier, and stack as a
/// `Column` below it. Resize the browser window to see the switch.
class ResponsiveRowColumnDefaultExample extends StatelessComponent {
  /// Creates a [ResponsiveRowColumnDefaultExample].
  const ResponsiveRowColumnDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return ResponsiveRowColumn(
      responsiveRowColumnStyle: const CoreResponsiveRowColumnStyle(
        spacing: CoreSpace.space12,
      ),
      children: [
        _StatCard(label: '조회수', value: '1,204'),
        _StatCard(label: '좋아요', value: '86'),
        _StatCard(label: '댓글', value: '12'),
      ],
    );
  }
}

class _StatCard extends StatelessComponent {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Component build(BuildContext context) {
    return Card(
      cardStyle: const CoreCardStyle(
        padding: CoreEdgeInsets.all(CoreSpace.space16),
      ),
      child: div(
        classes: 'flex flex-col items-start',
        [
          Text(value).titleMedium.semiBold.onSurface,
          Text(label).bodyMedium.onSurfaceVariant,
        ],
      ),
    );
  }
}
