import 'package:coui_web/coui_web.dart';

/// Destructive Toast example for docs_site Web preview.
class ToastDestructiveExample extends StatelessComponent {
  const ToastDestructiveExample({super.key});

  @override
  Component build(BuildContext context) {
    return Toast(
      message: '저장하지 못했어요',
      description: '문제가 생겼어요. 다시 시도해 주세요.',
      variant: CoreToastVariant.destructive,
      onDismiss: () {},
    );
  }
}
