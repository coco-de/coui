/// Returns a Flutter code snippet string for the BottomActionBar component.
String bottomActionBarCode(String? variant) => switch (variant) {
  'chain' => _chainCode,
  'horizontal' => _horizontalCode,
  'scaffold' => _scaffoldCode,
  'summary-compact' => _summaryCompactCode,
  _ => _defaultCode,
};

const String _chainCode = r'''
class BottomActionBarChainExample extends StatelessWidget {
  const BottomActionBarChainExample({super.key});

  @override
  Widget build(BuildContext context) {
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
class BottomActionBarHorizontalExample extends StatelessWidget {
  const BottomActionBarHorizontalExample({super.key});

  @override
  Widget build(BuildContext context) {
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
class BottomActionBarScaffoldExample extends StatelessWidget {
  const BottomActionBarScaffoldExample({super.key});

  @override
  Widget build(BuildContext context) {
    final geometry = Theme.of(context).geometry;
    // Fixed-height frame, like the Web twin's: a `Scaffold` lays its body
    // out with `Expanded`, so it needs a height to fill. 384 is the 400px
    // docs stage less its 8px inset on each side — anything taller overflows.
    return SizedBox(
      height: 384,
      child: Scaffold(
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
        // The Scaffold hands its body tight constraints; `Align` loosens them so
        // the scroll area keeps the 128 cap the Web preview gets from its
        // content-sized body, and the full-width box keeps it the width of the
        // body.
        child: Align(
          alignment: .topCenter,
          child: SizedBox(
            width: double.infinity,
            child: ScrollArea(
              scrollAreaStyle: const CoreScrollAreaStyle(
                maxHeight: CoreSize.size128,
              ),
              child: Padding(
                padding: EdgeInsets.all(geometry.space(CoreSpace.space20)),
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: geometry.space(CoreSpace.space8),
                  children: [
                    for (var i = 1; i <= 12; i += 1) Text('등록 정보 $i').bodyMedium,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
''';

const String _defaultCode = r'''
class BottomActionBarDefaultExample extends StatelessWidget {
  const BottomActionBarDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
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
class BottomActionBarSummaryCompactExample extends StatelessWidget {
  const BottomActionBarSummaryCompactExample({super.key});

  @override
  Widget build(BuildContext context) {
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
