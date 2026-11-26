import 'package:coui_flutter/coui_flutter.dart';

/// Default Toast example for docs_site Flutter preview.
class ToastDefaultExample extends StatefulWidget {
  const ToastDefaultExample({super.key});

  @override
  State<ToastDefaultExample> createState() => _ToastDefaultExampleState();
}

class _ToastDefaultExampleState extends State<ToastDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return Toast(
      message: '저장했어요',
      description: '변경 사항을 저장했어요.',
      onDismiss: () {},
    );
  }
}
