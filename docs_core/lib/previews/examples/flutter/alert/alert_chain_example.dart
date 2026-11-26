import 'package:coui_flutter/coui_flutter.dart';

/// T1 저작 규약 형태의 chain 예제 — 두 인스턴스로 구성한다:
/// (1) 토큰-정확 getter **combo 체인** 1개 (`.radius16.primary` — radius
/// 축·색 축 getter 가 base 전체에서 정확히 1회씩, 랜덤 순열 토글의 치환
/// 앵커), (2) **withStyle full-control** 1개 — getter 밖 필드까지 조합해
/// `CoreAlertStyle` 슬롯 전체를 여는 경로.
class AlertChainExample extends StatefulWidget {
  const AlertChainExample({super.key});

  @override
  State<AlertChainExample> createState() => _AlertChainExampleState();
}

class _AlertChainExampleState extends State<AlertChainExample> {
  bool _showCombo = true;
  bool _showFull = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        if (_showCombo)
          Alert(
            title: '확인이 필요해요',
            description: '결제 수단을 다시 확인해 주세요.',
            onDismiss: () => setState(() => _showCombo = false),
          ).radius16.primary
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
              backgroundColor: CoreColor.token(CoreColors.tertiaryContainer),
              foregroundColor: CoreColor.token(
                CoreColors.onTertiaryContainer,
              ),
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
    );
  }
}
