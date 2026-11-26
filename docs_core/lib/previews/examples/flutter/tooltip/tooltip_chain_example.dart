import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreTooltipStyle] slot without constructing the widget
/// from scratch.
class TooltipChainExample extends StatelessWidget {
  const TooltipChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '링크 복사',
      position: CoreTooltipPosition.bottom,
      child: Button(
        variant: CoreButtonVariant.outline,
        onPressed: () {},
        child: const Text('공유'),
      ),
    ).withStyle(
      const CoreTooltipStyle(
        panelBackgroundColor: CoreColor.token(CoreColors.primary),
        panelBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
        panelPadding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space16,
          vertical: CoreSpace.space8,
        ),
        labelStyle: CoreTextStyle.token(
          CoreTextStyles.bodySmall,
          color: CoreColor.token(CoreColors.onPrimary),
        ),
      ),
    );
  }
}
