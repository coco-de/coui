/// Returns a Web code snippet string for the ResponsiveRowColumn
/// component.
String responsiveRowColumnCode(String? variant) {
  return switch (variant) {
    'chain' =>
      r'''
class ResponsiveRowColumnChainExample extends StatelessComponent {
  const ResponsiveRowColumnChainExample({super.key});

  @override
  Component build(BuildContext context) {
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
}''',
    'desktop' =>
      r'''
class ResponsiveRowColumnDesktopExample extends StatelessComponent {
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
}''',
    _ =>
      r'''
class ResponsiveRowColumnDefaultExample extends StatelessComponent {
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
}''',
  };
}
