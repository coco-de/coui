import 'package:coui_web/coui_web.dart';

/// [ResponsiveRowColumn] with `switchAt: .desktop` — raises the
/// switch threshold so the panels stay stacked as a `Column` through
/// the `tablet` tier and only lay out as a `Row` at the `desktop`
/// tier and above.
class ResponsiveRowColumnDesktopExample extends StatelessComponent {
  /// Creates a [ResponsiveRowColumnDesktopExample].
  const ResponsiveRowColumnDesktopExample({super.key});

  @override
  Component build(BuildContext context) {
    return ResponsiveRowColumn(
      switchAt: .desktop,
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
