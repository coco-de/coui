import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates radius and explicit paint on [Button].
class ButtonChainExample extends StatelessWidget {
  const ButtonChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: Text('기본').lineLimit(1).ellipsis,
        ).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // 여러 속성을 한 스타일로 지정합니다.
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: Text('직접 지정').lineLimit(1).ellipsis,
        ).withStyle(
          const CoreButtonStyle(
            backgroundColor: .tertiary,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
            ),
          ),
        ),
      ],
    );
  }
}
