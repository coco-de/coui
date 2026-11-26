/// Returns a Web code snippet string for the Tooltip component.
String tooltipCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''class TooltipChainExample extends StatelessComponent {
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
}''',
    _ =>
      '''
class TooltipDefaultExample extends StatefulComponent {
  const TooltipDefaultExample({super.key});

  @override
  State<TooltipDefaultExample> createState() => _TooltipDefaultExampleState();
}

class _TooltipDefaultExampleState extends State<TooltipDefaultExample> {
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
    );
  }
}''',
  };
}
