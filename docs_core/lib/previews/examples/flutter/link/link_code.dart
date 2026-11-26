/// Code snippets for Link examples (Flutter).
library;

/// Code snippet for Link — variant-aware entry point.
String linkCode(String? variant) => switch (variant) {
  'chain' => linkChainCode(),
  'external' => linkExternalCode(),
  'icons' => linkIconsCode(),
  'muted' => linkMutedCode(),
  'underline' => linkUnderlineCode(),
  _ => linkDefaultCode(),
};

/// Code snippet for the `withStyle` chain Link example.
String linkChainCode() => '''class LinkChainExample extends StatelessWidget {
  const LinkChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Link(
      href: '#',
      child: Text('자세히 보기'),
    ).withStyle(
      const CoreLinkStyle(
        color: CoreColor.token(CoreColors.secondary),
        underlineColor: CoreColor.token(CoreColors.tertiary),
      ),
    );
  }
}''';

/// Code snippet for the default Link example.
String linkDefaultCode() => '''class LinkDefaultExample extends StatelessWidget {
  const LinkDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Link(
      href: '#',
      child: Text('자세히 보기'),
    );
  }
}''';

/// Code snippet for the external Link example.
String linkExternalCode() => '''class LinkExternalExample extends StatelessWidget {
  const LinkExternalExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Link(
      href: 'https://example.com',
      external: true,
      child: Text('외부 링크'),
    );
  }
}''';

/// Code snippet for the always-underlined Link example.
String linkUnderlineCode() => '''class LinkUnderlineExample extends StatelessWidget {
  const LinkUnderlineExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Link(
      href: '#',
      underline: true,
      child: Text('항상 밑줄 표시'),
    );
  }
}''';

/// Code snippet for the muted Link example.
String linkMutedCode() => '''class LinkMutedExample extends StatelessWidget {
  const LinkMutedExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Link(
      href: '#',
      variant: CoreLinkVariant.muted,
      child: Text('이용약관'),
    );
  }
}''';

/// Returns the Flutter code snippet for the icons variant.
String linkIconsCode() => '''class LinkIconsExample extends StatelessWidget {
  const LinkIconsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Link(
      href: 'https://github.com/coco-de/coui',
      external: true,
      trailing: Icon(LucideIcons.externalLink),
      child: Text('GitHub에서 보기'),
    );
  }
}''';
