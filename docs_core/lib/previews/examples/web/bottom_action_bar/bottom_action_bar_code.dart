/// Returns a Web code snippet string for the BottomActionBar component.
String bottomActionBarCode(String? variant) => switch (variant) {
  'chain' => _chainCode,
  'horizontal' => _horizontalCode,
  'scaffold' => _scaffoldCode,
  'summary-compact' => _summaryCompactCode,
  _ => _defaultCode,
};

const String _chainCode = r'''
class BottomActionBarChainExample extends StatelessComponent {
  const BottomActionBarChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return BottomActionBar(
      description: const Text('계속하면 이용약관에 동의한 것으로 봐요'),
      primaryAction: Button(
        variant: .primary,
        size: .xl,
        onPressed: () {},
        child: const Text('등록하기'),
      ),
    ).withStyle(
      const CoreBottomActionBarStyle(
        backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
        descriptionTextAlign: .start,
        spacing: CoreSpace.space12,
      ),
    );
  }
}
''';

const String _horizontalCode = r'''
class BottomActionBarHorizontalExample extends StatelessComponent {
  const BottomActionBarHorizontalExample({super.key});

  @override
  Component build(BuildContext context) {
    return BottomActionBar(
      layout: .horizontal,
      primaryAction: Button(
        variant: .primary,
        size: .xl,
        onPressed: () {},
        child: const Text('등록하기'),
      ),
      secondaryAction: Button(
        variant: .ghost,
        size: .xl,
        onPressed: () {},
        child: const Text('나중에 하기'),
      ),
    );
  }
}
''';

const String _scaffoldCode = r'''
class BottomActionBarScaffoldExample extends StatelessComponent {
  const BottomActionBarScaffoldExample({super.key});

  @override
  Component build(BuildContext context) {
    // Fixed-height frame (matches the Flutter preview canvas height)
    // so the scaffold's `min-h-full` has a definite parent to fill —
    // the Flutter twin fills its canvas constraints the same way.
    return div(
      [
        Scaffold(
          headers: [AppBar(title: const Text('새 항목 등록').titleMedium)],
          footers: [
            BottomActionBar(
              description: const Text('계속하면 이용약관에 동의한 것으로 봐요'),
              primaryAction: Button(
                variant: .primary,
                size: .xl,
                onPressed: () {},
                child: const Text('등록하기'),
              ),
              secondaryAction: Button(
                variant: .ghost,
                size: .lg,
                onPressed: () {},
                child: const Text('나중에 하기'),
              ),
            ),
          ],
          child: ScrollArea(
            scrollAreaStyle: const CoreScrollAreaStyle(maxHeight: CoreSize.size128),
            child: div(
              [
                for (var i = 1; i <= 12; i += 1) Text('등록 정보 $i').bodyMedium,
              ],
              classes: 'flex flex-col p-${CoreSpace.scale.space20} gap-${CoreSpace.scale.space8}',
            ),
          ),
        ),
      ],
      classes: 'w-full',
      styles: Styles(raw: const {'height': '${384 / 16}rem'}),
    );
  }
}
''';

const String _defaultCode = r'''
class BottomActionBarDefaultExample extends StatelessComponent {
  const BottomActionBarDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return BottomActionBar(
      description: const Text('계속하면 이용약관에 동의한 것으로 봐요'),
      primaryAction: Button(
        variant: .primary,
        size: .xl,
        onPressed: () {},
        child: const Text('등록하기'),
      ),
      secondaryAction: Button(
        variant: .ghost,
        size: .lg,
        onPressed: () {},
        child: const Text('나중에 하기'),
      ),
    );
  }
}
''';

const String _summaryCompactCode = r'''
class BottomActionBarSummaryCompactExample extends StatelessComponent {
  const BottomActionBarSummaryCompactExample({super.key});

  @override
  Component build(BuildContext context) {
    return BottomActionBar(
      layout: .summaryCompact,
      summaryLabel: const Text('총 금액'),
      summaryValue: const Text('64,000원'),
      primaryAction: Button(
        variant: .primary,
        size: .lg,
        onPressed: () {},
        child: const Text('결제하기'),
      ),
    );
  }
}''';
