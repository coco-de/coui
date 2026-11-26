/// Returns a Web code snippet string for the EmptyState component.
String emptyStateCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class EmptyStateChainExample extends StatefulComponent {
  const EmptyStateChainExample({super.key});

  @override
  State<EmptyStateChainExample> createState() => _EmptyStateChainExampleState();
}

class _EmptyStateChainExampleState extends State<EmptyStateChainExample> {
  @override
  Component build(BuildContext context) {
    return EmptyState(
      title: Text('결과가 없어요'),
      description: Text('검색어나 필터를 바꿔 보세요.'),
    ).withStyle(
      const CoreEmptyStateStyle(
        minHeight: 200,
        padding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space24,
          vertical: CoreSpace.space8,
        ),
      ),
    );
  }
}''',
    'normal' =>
      '''
class EmptyStateNormalExample extends StatefulComponent {
  const EmptyStateNormalExample({super.key});

  @override
  State<EmptyStateNormalExample> createState() =>
      _EmptyStateNormalExampleState();
}

class _EmptyStateNormalExampleState extends State<EmptyStateNormalExample> {
  @override
  Component build(BuildContext context) {
    return EmptyState(
      variant: CoreEmptyStateVariant.normal,
      title: Text('결과가 없어요'),
      description: Text('검색어나 필터를 바꿔 보세요.'),
    );
  }
}''',
    'large' =>
      '''
class EmptyStateLargeExample extends StatefulComponent {
  const EmptyStateLargeExample({super.key});

  @override
  State<EmptyStateLargeExample> createState() => _EmptyStateLargeExampleState();
}

class _EmptyStateLargeExampleState extends State<EmptyStateLargeExample> {
  @override
  Component build(BuildContext context) {
    return EmptyState(
      variant: CoreEmptyStateVariant.large,
      icon: Icon(LucideIcons.inbox),
      title: Text('아직 항목이 없어요'),
      description: Text('첫 항목을 추가해 시작해 보세요.'),
    );
  }
}''',
    'success' =>
      '''
class EmptyStateSuccessExample extends StatefulComponent {
  const EmptyStateSuccessExample({super.key});

  @override
  State<EmptyStateSuccessExample> createState() => _EmptyStateSuccessExampleState();
}

class _EmptyStateSuccessExampleState extends State<EmptyStateSuccessExample> {
  @override
  Component build(BuildContext context) {
    return EmptyState(
      tone: CoreEmptyStateTone.success,
      icon: Icon(LucideIcons.circleCheck),
      title: Text('모두 끝났어요'),
      description: Text('모든 항목을 처리했어요.'),
    );
  }
}''',
    'failure' =>
      '''
class EmptyStateFailureExample extends StatefulComponent {
  const EmptyStateFailureExample({super.key});

  @override
  State<EmptyStateFailureExample> createState() => _EmptyStateFailureExampleState();
}

class _EmptyStateFailureExampleState extends State<EmptyStateFailureExample> {
  @override
  Component build(BuildContext context) {
    return EmptyState(
      tone: CoreEmptyStateTone.failure,
      icon: Icon(LucideIcons.circleAlert),
      title: Text('결과를 불러오지 못했어요'),
      description: Text('연결을 확인하고 다시 시도해 주세요.'),
      action: Button(
        variant: CoreButtonVariant.outline,
        onPressed: () {},
        child: Text('다시 시도'),
      ),
    );
  }
}''',
    _ =>
      '''
class EmptyStateDefaultExample extends StatefulComponent {
  const EmptyStateDefaultExample({super.key});

  @override
  State<EmptyStateDefaultExample> createState() =>
      _EmptyStateDefaultExampleState();
}

class _EmptyStateDefaultExampleState extends State<EmptyStateDefaultExample> {
  @override
  Component build(BuildContext context) {
    return EmptyState(
      title: Text('결과가 없어요'),
      description: Text('검색어나 필터를 바꿔 보세요.'),
    );
  }
}''',
  };
}
