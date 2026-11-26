import 'package:coui_web/coui_web.dart';

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
}
