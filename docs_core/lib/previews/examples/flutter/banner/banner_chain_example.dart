import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates radius and explicit paint on [Banner].
class BannerChainExample extends StatefulWidget {
  const BannerChainExample({super.key});

  @override
  State<BannerChainExample> createState() => _BannerChainExampleState();
}

class _BannerChainExampleState extends State<BannerChainExample> {
  bool _showCombo = true;
  bool _showFull = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        if (_showCombo)
          Banner.info(
            message: const Text('일반 안내예요.'),
            onDismiss: () => setState(() => _showCombo = false),
          ).radius16.backgroundColor(.primary)
        else
          Button(
            variant: CoreButtonVariant.outline,
            onPressed: () => setState(() => _showCombo = true),
            child: const Text('배너 보기'),
          ),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        if (_showFull)
          Banner.info(
            message: const Text('일반 안내예요.'),
            onDismiss: () => setState(() => _showFull = false),
          ).withStyle(
            const CoreBannerStyle(
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
            child: const Text('배너 보기'),
          ),
      ],
    );
  }
}
