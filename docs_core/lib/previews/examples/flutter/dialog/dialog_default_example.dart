import 'package:coui_flutter/coui_flutter.dart';

class DialogDefaultExample extends StatefulWidget {
  const DialogDefaultExample({super.key});

  @override
  State<DialogDefaultExample> createState() => _DialogDefaultExampleState();
}

class _DialogDefaultExampleState extends State<DialogDefaultExample> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () => setState(() => _open = true),
          child: const Text('대화상자 열기'),
        ),
        Dialog(
          open: _open,
          onClose: () => setState(() => _open = false),
          title: const Text('계속할까요?'),
          content: const Text('이 작업은 되돌릴 수 없어요.'),
          actions: [
            Button(
              variant: CoreButtonVariant.outline,
              onPressed: () => setState(() => _open = false),
              child: const Text('취소'),
            ),
            Button(
              variant: CoreButtonVariant.primary,
              onPressed: () => setState(() => _open = false),
              child: const Text('계속'),
            ),
          ],
        ),
      ],
    );
  }
}
