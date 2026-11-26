import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreStepItemStyle] slot without constructing the component
/// from scratch.
class StepItemChainExample extends StatelessComponent {
  const StepItemChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        const StepItem(
          title: '테스트 실행',
          status: CoreStepStatus.current,
          trailing: '41초',
        ).withStyle(
          const CoreStepItemStyle(
            padding: CoreEdgeInsets.symmetric(vertical: CoreSpace.space10),
            iconTitleGapStyle: CoreGapStyle(size: CoreSpace.space16),
            titleStyle: CoreTextStyle(
              color: CoreColor.token(CoreColors.primary),
            ),
          ),
        ),
      ],
      classes: 'w-${CoreLayout.scale.layout280}',
    );
  }
}
