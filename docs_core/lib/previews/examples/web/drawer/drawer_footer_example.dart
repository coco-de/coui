import 'package:coui_web/coui_web.dart';

/// Drawer with a footer for docs_site web preview.
///
/// The footer slot sits under the content behind a hairline and is aligned
/// to the end; the caller owns the buttons and the space between them.
class DrawerFooterExample extends StatelessComponent {
  const DrawerFooterExample({super.key});

  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {
        openDrawer<void>(
          context: context,
          side: CoreDrawerSide.right,
          builder: (close) => Drawer(
            title: '프로필',
            description: '다른 사람에게 보이는 모습을 바꿔요.',
            content: div(
              [
                const Text('이름'),
                const Text('이메일'),
              ],
              classes: 'flex flex-col gap-${CoreSpace.scale.space8}',
            ),
            footer: div(
              [
                Button(
                  variant: CoreButtonVariant.secondary,
                  onPressed: () => close(),
                  child: const Text('취소'),
                ),
                Button(
                  variant: CoreButtonVariant.primary,
                  onPressed: () => close(),
                  child: const Text('저장'),
                ),
              ],
              classes: 'flex gap-${CoreSpace.scale.space8}',
            ),
          ),
        );
      },
      child: const Text('푸터 있는 패널 열기'),
    );
  }
}
