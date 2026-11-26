import 'package:coui_flutter/coui_flutter.dart';

class DialogStretchExample extends StatefulWidget {
  const DialogStretchExample({super.key});

  @override
  State<DialogStretchExample> createState() => _DialogStretchExampleState();
}

class _DialogStretchExampleState extends State<DialogStretchExample> {
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
          title: const Text('연결이 끊겼어요'),
          content: const Text('네트워크를 확인하고 다시 시도해 주세요.'),
          actions: [
            Button(
              variant: CoreButtonVariant.outline,
              onPressed: () => setState(() => _open = false),
              child: const Text('취소'),
            ),
            Button(
              variant: CoreButtonVariant.primary,
              onPressed: () => setState(() => _open = false),
              child: const Text('다시 시도'),
            ),
          ],
          // 두 행동이 행의 폭을 반씩 나눈다.
          // 패널 폭은 휴대폰 확인창에 맞춘다.
          dialogStyle: const CoreDialogStyle(
            panelMaxWidth: CoreLayout.layout320,
            actionsLayout: CoreDialogActionsLayout.stretch,
          ),
        ),
      ],
    );
  }
}
