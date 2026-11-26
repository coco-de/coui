import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreDialogStyle] slot without constructing the
/// component from scratch.
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
}
