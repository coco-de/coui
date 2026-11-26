/// Code snippets for Link examples (Web).
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
String linkChainCode() => '''class LinkChainExample extends StatelessComponent {
  const LinkChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Link(
      href: '#',
      child: const Text('자세히 보기'),
    ).withStyle(
      const CoreLinkStyle(
        color: CoreColor.token(CoreColors.secondary),
        underlineColor: CoreColor.token(CoreColors.tertiary),
      ),
    );
  }
}''';

/// Code snippet for the default Link example.
String linkDefaultCode() => '''class LinkDefaultExample extends StatelessComponent {
  const LinkDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Link(
      href: '#',
      child: const Text('자세히 보기'),
    );
  }
}''';

/// Code snippet for the external Link example.
String linkExternalCode() => '''class LinkExternalExample extends StatelessComponent {
  const LinkExternalExample({super.key});

  @override
  Component build(BuildContext context) {
    return Link(
      href: 'https://example.com',
      external: true,
      child: const Text('외부 링크'),
    );
  }
}''';

/// Code snippet for the always-underlined Link example.
String linkUnderlineCode() => '''class LinkUnderlineExample extends StatelessComponent {
  const LinkUnderlineExample({super.key});

  @override
  Component build(BuildContext context) {
    return Link(
      href: '#',
      underline: true,
      child: const Text('항상 밑줄 표시'),
    );
  }
}''';

/// Code snippet for the muted Link example.
String linkMutedCode() => '''class LinkMutedExample extends StatelessComponent {
  const LinkMutedExample({super.key});

  @override
  Component build(BuildContext context) {
    return Link(
      href: '#',
      variant: CoreLinkVariant.muted,
      child: const Text('이용약관'),
    );
  }
}''';

/// Returns the Web code snippet for the icons variant.
String linkIconsCode() => '''class LinkIconsExample extends StatelessComponent {
  const LinkIconsExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Link(
      href: 'https://github.com/coco-de/coui',
      external: true,
      trailing: Icon(LucideIcons.externalLink),
      child: Text('GitHub에서 보기'),
    );
  }
}''';
