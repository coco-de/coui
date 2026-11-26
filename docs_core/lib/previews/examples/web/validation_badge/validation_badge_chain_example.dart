import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreValidationBadgeStyle] slot without constructing the
/// widget from scratch.
class ValidationBadgeChainExample extends StatelessComponent {
  const ValidationBadgeChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const ValidationBadge(
      label: '8자 이상',
      state: CoreValidationState.valid,
    ).withStyle(
      const CoreValidationBadgeStyle(
        validBackgroundColor: CoreColor.token(
          CoreColors.primary,
          opacity: CoreOpacity.opacity10,
        ),
        validBorderColor: CoreColor.token(CoreColors.primary),
        validLabelTextStyle: CoreTextStyle.token(
          CoreTextStyles.labelMedium,
          color: CoreColor.token(CoreColors.primary),
        ),
        borderWidth: CoreStrokeWidth.stroke2,
        iconStyle: CoreIconStyle(
          size: CoreIconSize.size16,
          color: CoreColor.token(CoreColors.primary),
        ),
        iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
      ),
    );
  }
}
