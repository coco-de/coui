import 'package:coui_flutter/coui_flutter.dart';

/// Drawer with a footer for docs_site flutter preview.
///
/// The footer slot sits under the content behind a hairline and is aligned
/// to the end; the caller owns the buttons and the space between them.
class DrawerFooterExample extends StatelessWidget {
  const DrawerFooterExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {
        openDrawer<void>(
          context: context,
          side: CoreDrawerSide.right,
          builder: (ctx) => Drawer(
            title: '프로필',
            description: '다른 사람에게 보이는 모습을 바꿔요.',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('이름'),
                Text('이메일'),
              ],
            ),
            footer: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: CoreSpace.space8,
              children: [
                Button(
                  variant: CoreButtonVariant.secondary,
                  onPressed: () => closeDrawer<void>(ctx),
                  child: const Text('취소'),
                ),
                Button(
                  variant: CoreButtonVariant.primary,
                  onPressed: () => closeDrawer<void>(ctx),
                  child: const Text('저장'),
                ),
              ],
            ),
          ),
        );
      },
      child: const Text('푸터 있는 패널 열기'),
    );
  }
}
