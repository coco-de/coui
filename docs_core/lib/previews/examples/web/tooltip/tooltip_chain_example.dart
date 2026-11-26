import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreTooltipStyle] slot without constructing the widget
/// from scratch.
class TooltipChainExample extends StatelessComponent {
  const TooltipChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Tooltip(
      message: '링크 복사',
      position: CoreTooltipPosition.bottom,
      child: Button(
        variant: CoreButtonVariant.outline,
        onPressed: () {},
        child: Text('공유'),
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
