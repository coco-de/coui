/// Returns a Flutter code snippet string for the CommandSearch component.
String commandSearchCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class CommandSearchChainExample extends StatelessWidget {
  const CommandSearchChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreLayout.layout320,
      child:
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
    );
  }
}''',
    _ =>
      '''
class CommandSearchDefaultExample extends StatelessWidget {
  const CommandSearchDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    // 트리거는 자기 폭을 정하지 않는다 — 앱 바의 가운데 칸 같은 부모가
    // 정한다. 프리뷰에서는 폭 상한(`layout320`)을 부모가 대신 준다.
    return SizedBox(
      width: CoreLayout.layout320,
      child: CommandSearch(
        shortcut: const Kbd(keys: ['⌘K']),
        onPressed: () {},
      ),
    );
  }
}''',
  };
}
