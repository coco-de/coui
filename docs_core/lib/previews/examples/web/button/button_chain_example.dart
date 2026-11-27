import 'package:coui_web/coui_web.dart';

/// Demonstrates radius and explicit paint on [Button].
class ButtonChainExample extends StatelessComponent {
  const ButtonChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: Text('기본').lineLimit(1).ellipsis,
        ).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
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
      classes: 'flex flex-col items-start',
    );
  }
}
