import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreCommandSearchStyle] slot without constructing the
/// component from scratch.
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
      classes: 'w-${CoreLayout.scale.layout320}',
    );
  }
}
