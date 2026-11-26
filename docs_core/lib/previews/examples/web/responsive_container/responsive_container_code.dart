/// Code snippet for [ResponsiveContainer] Web examples.
String responsiveContainerCode(String? variant) {
  return switch (variant) {
    'chain' => _chainCode,
    _ => _defaultCode,
  };
}

const _chainCode = r'''
class ResponsiveContainerChainExample extends StatelessComponent {
  const ResponsiveContainerChainExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return ResponsiveContainer(
      child: Card(
        cardStyle: const CoreCardStyle(
          padding: CoreEdgeInsets.all(CoreSpace.space16),
        ),
        child: div(
          classes: 'text-${CoreTextStyles.bodyMedium.name} text-${cs.onSurface}',
          [
            Text(
              '이 내용은 가운데에 놓이고 "sm" 브레이크포인트(640 px)에서 '
              '폭이 멈춰요. 미리보기 크기를 바꿔도 컨테이너는 좌우 여백을 '
              '같게 둔 채 최대 폭 안에 머물러요.',
            ),
          ],
        ),
      ),
    ).withStyle(
      const CoreResponsiveContainerStyle(
        maxWidth: CoreResponsiveContainerMaxWidth.sm,
        centered: true,
        horizontalPadding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space24,
        ),
      ),
    );
  }
}
''';

const _defaultCode = '''
class ResponsiveContainerDefaultExample extends StatelessComponent {
  const ResponsiveContainerDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return ResponsiveContainer(
      maxWidth: CoreResponsiveContainerMaxWidth.sm,
      child: Card(
        cardStyle: const CoreCardStyle(padding: CoreSpace.space16),
        child: div(
          classes: 'text-\${CoreTextStyles.bodyMedium.name} text-\${cs.onSurface}',
          [
            Text(
              '이 내용은 가운데에 놓이고 "sm" 브레이크포인트(640 px)에서 '
              '폭이 멈춰요. 미리보기 크기를 바꿔도 컨테이너는 좌우 여백을 '
              '같게 둔 채 최대 폭 안에 머물러요.',
            ),
          ],
        ),
      ),
    );
  }
}
''';
