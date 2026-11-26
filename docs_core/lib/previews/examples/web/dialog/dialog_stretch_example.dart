import 'package:coui_web/coui_web.dart';

class DialogStretchExample extends StatefulComponent {
  const DialogStretchExample({super.key});

  @override
  State<DialogStretchExample> createState() => _DialogStretchExampleState();
}

class _DialogStretchExampleState extends State<DialogStretchExample> {
  bool _open = false;

  @override
  Component build(BuildContext context) {
    return div([
      Button(
        variant: CoreButtonVariant.primary,
        onPressed: () => setState(() => _open = true),
        child: Text('대화상자 열기'),
      ),
      Dialog(
        open: _open,
        onClose: () => setState(() => _open = false),
        title: Text('연결이 끊겼어요'),
        content: Text('네트워크를 확인하고 다시 시도해 주세요.'),
        actions: [
          Button(
            variant: CoreButtonVariant.outline,
            onPressed: () => setState(() => _open = false),
            child: Text('취소'),
          ),
          Button(
            variant: CoreButtonVariant.primary,
            onPressed: () => setState(() => _open = false),
            child: Text('다시 시도'),
          ),
        ],
        // 두 행동이 행의 폭을 반씩 나눈다.
        // 패널 폭은 휴대폰 확인창에 맞춘다.
        dialogStyle: const CoreDialogStyle(
          panelMaxWidth: CoreLayout.layout320,
          actionsLayout: CoreDialogActionsLayout.stretch,
        ),
      ),
    ]);
  }
}
