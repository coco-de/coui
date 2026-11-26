import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreFormLabelStyle] slot without constructing the
/// widget from scratch.
class FormLabelChainExample extends StatelessComponent {
  const FormLabelChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return FormLabel(
      label: Text('이메일'),
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
