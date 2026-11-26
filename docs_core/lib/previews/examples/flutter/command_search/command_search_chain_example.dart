import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreCommandSearchStyle] slot without constructing the
/// component from scratch.
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
}
