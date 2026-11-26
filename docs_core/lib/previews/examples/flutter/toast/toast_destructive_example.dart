import 'package:coui_flutter/coui_flutter.dart';

/// Destructive Toast example for docs_site Flutter preview.
class ToastDestructiveExample extends StatefulWidget {
  const ToastDestructiveExample({super.key});

  @override
  State<ToastDestructiveExample> createState() => _ToastDestructiveExampleState();
}

class _ToastDestructiveExampleState extends State<ToastDestructiveExample> {
  @override
  Widget build(BuildContext context) {
    return Toast(
      message: '저장하지 못했어요',
      description: '문제가 생겼어요. 다시 시도해 주세요.',
      variant: CoreToastVariant.destructive,
      onDismiss: () {},
    );
  }
}
