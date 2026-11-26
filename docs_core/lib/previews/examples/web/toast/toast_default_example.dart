import 'package:coui_web/coui_web.dart';

/// Default Toast example for docs_site Web preview.
class ToastDefaultExample extends StatelessComponent {
  const ToastDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Toast(
      message: '저장했어요',
      description: '변경 사항을 저장했어요.',
      onDismiss: () {},
    );
  }
}
