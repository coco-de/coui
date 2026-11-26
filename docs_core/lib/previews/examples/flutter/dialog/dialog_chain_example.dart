import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreDialogStyle] slot without constructing the widget
/// from scratch.
class DialogChainExample extends StatefulWidget {
  const DialogChainExample({super.key});

  @override
  State<DialogChainExample> createState() => _DialogChainExampleState();
}

class _DialogChainExampleState extends State<DialogChainExample> {
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
      ],
    );
  }
}
