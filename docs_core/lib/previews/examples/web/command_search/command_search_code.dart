/// Returns a Web code snippet string for the CommandSearch component.
String commandSearchCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class CommandSearchChainExample extends StatelessComponent {
  const CommandSearchChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        CommandSearch(
          hint: '문서 검색',
          shortcut: const Kbd(keys: ['⌘K']),
          onPressed: () {},
        ).withStyle(
          const CoreCommandSearchStyle(
            backgroundColor: CoreColor.token(
              CoreColors.surfaceContainerHigh,
            ),
            contentGapStyle: CoreGapStyle(size: CoreSpace.space12),
          ),
        ),
      ],
      classes: 'w-\${CoreLayout.scale.layout320}',
    );
  }
}''',
    _ =>
      '''
class CommandSearchDefaultExample extends StatelessComponent {
  const CommandSearchDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    // 트리거는 자기 폭을 정하지 않는다 — 앱 바의 가운데 칸 같은 부모가
    // 정한다. 프리뷰에서는 폭 상한(`layout320`)을 부모가 대신 준다.
    return div(
      [
        CommandSearch(
          shortcut: const Kbd(keys: ['⌘K']),
          onPressed: () {},
        ),
      ],
      classes: 'w-\${CoreLayout.scale.layout320}',
    );
  }
}''',
  };
}
