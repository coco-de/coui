import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreStepItemStyle] slot without constructing the widget
/// from scratch.
class StepItemChainExample extends StatelessWidget {
  const StepItemChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreLayout.layout280,
      child:
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
    );
  }
}
