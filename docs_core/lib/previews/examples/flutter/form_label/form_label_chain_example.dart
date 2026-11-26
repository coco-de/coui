import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreFormLabelStyle] slot without constructing the
/// widget from scratch.
class FormLabelChainExample extends StatelessWidget {
  const FormLabelChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FormLabel(
      label: const Text('이메일'),
      isRequired: true,
    ).withStyle(
      const CoreFormLabelStyle(
        labelStyle: CoreTextStyle.token(
          CoreTextStyles.titleMedium,
          color: CoreColor.token(CoreColors.primary),
        ),
        requiredColor: CoreColor.token(CoreColors.tertiary),
        requiredIndicatorGapStyle: CoreGapStyle(size: CoreSpace.space12),
      ),
    );
  }
}
