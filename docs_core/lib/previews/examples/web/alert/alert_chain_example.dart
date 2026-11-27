import 'package:coui_web/coui_web.dart';

/// Demonstrates radius and explicit paint on [Alert].
class AlertChainExample extends StatefulComponent {
  const AlertChainExample({super.key});

  @override
  State<AlertChainExample> createState() => _AlertChainExampleState();
}

class _AlertChainExampleState extends State<AlertChainExample> {
  bool _showCombo = true;
  bool _showFull = true;

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        if (_showCombo)
          Alert(
            title: '확인이 필요해요',
            description: '결제 수단을 다시 확인해 주세요.',
            onDismiss: () => setState(() => _showCombo = false),
          ).radius16.backgroundColor(.primary)
        else
          Button(
            variant: CoreButtonVariant.outline,
            onPressed: () => setState(() => _showCombo = true),
            child: const Text('알림 보기'),
          ),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        if (_showFull)
          Alert(
            title: '확인이 필요해요',
            description: '결제 수단을 다시 확인해 주세요.',
            onDismiss: () => setState(() => _showFull = false),
          ).withStyle(
            const CoreAlertStyle(
              backgroundColor: .tertiaryContainer,
              foregroundColor: .onTertiaryContainer,
              borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
              padding: CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space24,
                vertical: CoreSpace.space8,
              ),
            ),
          )
        else
          Button(
            variant: CoreButtonVariant.outline,
            onPressed: () => setState(() => _showFull = true),
            child: const Text('알림 보기'),
          ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}
