/// Returns a Flutter code snippet string for the AppBar component.
String appBarCode(String? variant) => switch (variant) {
  'foldable' => _foldableCode,
  'glass' => _foldableCode,
  'centered' => _centeredCode,
  'chain' => _chainCode,
  'compact' => _compactCode,
  'dense' => _denseCode,
  'medium' => _mediumCode,
  'prominent' => _prominentCode,
  'text' => _textCode,
  _ => _defaultCode,
};

const String _centeredCode = r'''
class AppBarCenteredExample extends StatelessWidget {
  const AppBarCenteredExample({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      leading: [
        Button(
          variant: CoreButtonVariant.plain,
          onPressed: () {},
          child: const Icon(LucideIcons.arrowLeft),
        ),
      ],
      title: const Text('주문 상세'),
      trailing: [
        Button(
          variant: CoreButtonVariant.ghost,
          size: CoreComponentSize.sm,
          onPressed: () {},
          child: const Text('공유'),
        ),
        Button(
          variant: CoreButtonVariant.ghost,
          size: CoreComponentSize.sm,
          onPressed: () {},
          child: const Text('편집'),
        ),
      ],
    );
  }
}
''';

const String _chainCode = r'''
class AppBarChainExample extends StatelessWidget {
  const AppBarChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
          leading: [
            Button(
              variant: CoreButtonVariant.plain,
              onPressed: () {},
              child: const Icon(LucideIcons.arrowLeft),
            ),
          ],
          title: const Text('대시보드'),
          trailing: [
            Button(
              variant: CoreButtonVariant.plain,
              onPressed: () {},
              child: const Icon(LucideIcons.settings),
            ),
          ],
        )
        .withStyle(
          const CoreAppBarStyle(
            dividerColor: CoreColor.token(CoreColors.outline),
            dividerWidth: CoreStrokeWidth.stroke2,
          ),
        )
        .surfaceContainer;
  }
}
''';

const String _compactCode = r'''
class AppBarCompactExample extends StatelessWidget {
  const AppBarCompactExample({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      variant: CoreAppBarVariant.compact,
      leading: [
        Button(
          variant: CoreButtonVariant.plain,
          onPressed: () {},
          child: const Icon(LucideIcons.arrowLeft),
        ),
      ],
      title: const Text('알림'),
      trailing: [
        Button(
          variant: CoreButtonVariant.plain,
          onPressed: () {},
          child: const Icon(LucideIcons.check),
        ),
      ],
    );
  }
}
''';

const String _denseCode = r'''
class AppBarDenseExample extends StatelessWidget {
  const AppBarDenseExample({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      variant: CoreAppBarVariant.dense,
      leading: [
        Button(
          variant: CoreButtonVariant.plain,
          size: CoreComponentSize.sm,
          onPressed: () {},
          child: const Icon(LucideIcons.panelLeft),
        ),
      ],
      title: const Text('워크스페이스'),
      trailing: [
        Button(
          variant: CoreButtonVariant.plain,
          size: CoreComponentSize.sm,
          onPressed: () {},
          child: const Icon(LucideIcons.search),
        ),
        Button(
          variant: CoreButtonVariant.plain,
          size: CoreComponentSize.sm,
          onPressed: () {},
          child: const Icon(LucideIcons.settings),
        ),
      ],
    );
  }
}
''';

const String _mediumCode = r'''
class AppBarMediumExample extends StatelessWidget {
  const AppBarMediumExample({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      variant: CoreAppBarVariant.medium,
      leading: [
        Button(
          variant: CoreButtonVariant.plain,
          onPressed: () {},
          child: const Icon(LucideIcons.arrowLeft),
        ),
      ],
      title: const Text('받은편지함'),
      trailing: [
        Button(
          variant: CoreButtonVariant.plain,
          onPressed: () {},
          child: const Icon(LucideIcons.ellipsisVertical),
        ),
      ],
    );
  }
}
''';

const String _prominentCode = r'''
class AppBarProminentExample extends StatelessWidget {
  const AppBarProminentExample({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      variant: CoreAppBarVariant.prominent,
      title: const Text('지도'),
      trailing: [
        Button(
          variant: CoreButtonVariant.ghost,
          buttonStyle: const CoreButtonStyle(
            foregroundColor: CoreColor.token(CoreColors.onSurfaceVariant),
          ),
          onPressed: () {},
          child: const Text('목록으로'),
        ),
      ],
    );
  }
}
''';

const String _textCode = r'''
class AppBarTextExample extends StatelessWidget {
  const AppBarTextExample({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: [
        Button(
          variant: CoreButtonVariant.ghost,
          onPressed: () {},
          child: const Text('뒤로'),
        ),
      ],
      trailing: [
        Button(
          variant: CoreButtonVariant.ghost,
          buttonStyle: const CoreButtonStyle(
            foregroundColor: CoreColor.token(CoreColors.onSurfaceVariant),
          ),
          onPressed: () {},
          child: const Text('목록으로'),
        ),
      ],
    );
  }
}
''';

const String _defaultCode = r'''
class AppBarDefaultExample extends StatelessWidget {
  const AppBarDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: [
        Button(
          variant: CoreButtonVariant.plain,
          onPressed: () {},
          child: const Icon(LucideIcons.arrowLeft),
        ),
      ],
      title: const Text('대시보드'),
      trailing: [
        Button(
          variant: CoreButtonVariant.plain,
          onPressed: () {},
          child: const Icon(LucideIcons.settings),
        ),
      ],
    );
  }
}
''';

const String _foldableCode = r'''
/// Toggle the preview variant between a phone bar and a Duo control rail.
class AppBarFoldableExample extends StatelessWidget {
  const AppBarFoldableExample({this.controlRail = true, super.key});
  final bool controlRail;

  @override
  Widget build(BuildContext context) => SizedBox(height: 384, child:
    Scaffold(
      adaptiveAppBarActions: true,
      // A device preview supplies physical safe-area geometry. Apps omit it.
      appBarControlInsets: controlRail
        ? const CoreEdgeInsets.only(right: 84, bottom: 34) : CoreEdgeInsets.zero,
      scaffoldStyle: const CoreScaffoldStyle(headerBorderWidth: 0),
      headers: [AppBar(
        centerTitle: true, showDivider: false,
        appBarStyle: const CoreAppBarStyle(surfaceStyle: .liquidGlass),
        title: const Text('보관함'),
        leading: [Semantics(label: '이전', child: Button(variant: .ghost, shape: .square, onPressed: () {}, child: const Icon(LucideIcons.chevronLeft)))],
        trailing: [Semantics(label: '공유', child: Button(variant: .ghost, shape: .square, onPressed: () {}, child: const Icon(LucideIcons.share))), BarAction(axisBehavior: .horizontalOnly,
          child: Button(variant: .ghost, onPressed: () {}, child: const Text('편집')))],
      )],
      child: const Center(child: Text('본문 · 아이콘은 우측 레일')),
    ),
  );
}
''';
