import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreLabelStyle] slot without constructing the widget
/// from scratch.
class LabelChainExample extends StatelessWidget {
  const LabelChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Label(text: '이메일', isRequired: true).withStyle(
      const CoreLabelStyle(
        textStyle: CoreTextStyle.token(
          CoreTextStyles.titleMedium,
          color: CoreColor.token(CoreColors.primary),
        ),
        requiredColor: CoreColor.token(CoreColors.tertiary),
        labelRequiredGapStyle: CoreGapStyle(size: CoreSpace.space12),
        disabledOpacity: CoreOpacity.opacity50,
      ),
    );
  }
}
