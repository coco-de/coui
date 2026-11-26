/// Returns a Web code snippet string for the Dialog component.
String dialogCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class DialogChainExample extends StatefulComponent {
  const DialogChainExample({super.key});

  @override
  State<DialogChainExample> createState() => _DialogChainExampleState();
}

class _DialogChainExampleState extends State<DialogChainExample> {
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
        title: Text('계속할까요?'),
        content: Text('이 작업은 되돌릴 수 없어요.'),
        actions: [
          Button(
            variant: CoreButtonVariant.outline,
            onPressed: () => setState(() => _open = false),
            child: Text('취소'),
          ),
          Button(
            variant: CoreButtonVariant.primary,
            onPressed: () => setState(() => _open = false),
            child: Text('계속'),
          ),
        ],
      ).withStyle(
        const CoreDialogStyle(
          panelBackgroundColor: CoreColor.token(
            CoreColors.surfaceContainerHigh,
          ),
          panelBorderRadius: CoreBorderRadius.all(CoreRadius.radius24),
          panelPadding: CoreEdgeInsets.all(CoreSpace.space24),
          sectionGapStyle: CoreGapStyle(size: CoreSpace.space12),
          actionSpacing: CoreSpace.space12,
        ),
      ),
    ]);
  }
}''',
    'stretch' =>
      '''
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
}''',
    _ =>
      '''
class DialogDefaultExample extends StatefulComponent {
  const DialogDefaultExample({super.key});

  @override
  State<DialogDefaultExample> createState() => _DialogDefaultExampleState();
}

class _DialogDefaultExampleState extends State<DialogDefaultExample> {
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
        title: Text('계속할까요?'),
        content: Text('이 작업은 되돌릴 수 없어요.'),
        actions: [
          Button(
            variant: CoreButtonVariant.outline,
            onPressed: () => setState(() => _open = false),
            child: Text('취소'),
          ),
          Button(
            variant: CoreButtonVariant.primary,
            onPressed: () => setState(() => _open = false),
            child: Text('계속'),
          ),
        ],
      ),
    ]);
  }
}''',
  };
}
