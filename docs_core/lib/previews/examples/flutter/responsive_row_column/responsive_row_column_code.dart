/// Returns a Flutter code snippet string for the ResponsiveRowColumn
/// component.
String responsiveRowColumnCode(String? variant) {
  return switch (variant) {
    'chain' =>
      r'''
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
}''',
    'desktop' =>
      r'''
class ResponsiveRowColumnDesktopExample extends StatelessWidget {
  const ResponsiveRowColumnDesktopExample({super.key});

  @override
  Widget build(BuildContext context) {
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
}''',
    _ =>
      r'''
class ResponsiveRowColumnDefaultExample extends StatelessWidget {
  const ResponsiveRowColumnDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
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
}''',
  };
}
