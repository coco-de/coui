/// Code snippet for default HoverCard (Flutter).
String hoverCardCode(String? variant) => switch (variant) {
  'chain' =>
    '''class HoverCardChainExample extends StatelessWidget {
  const HoverCardChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        HoverCard(
          trigger: const Text('@coui').bodyMedium.onPrimaryContainer.underline,
          content: const Text('크로스 플랫폼 UI 디자인 시스템.').bodySmall.onSurface,
          placement: CorePopoverPlacement.bottom,
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·padding)까지 한 번에.
        HoverCard(
          trigger: const Text('직접 지정').bodyMedium.onPrimaryContainer.underline,
          content: const Text('크로스 플랫폼 UI 디자인 시스템.').bodySmall.onSurface,
          placement: CorePopoverPlacement.bottom,
        ).withStyle(
          const CoreHoverCardStyle(
            panelStyle: CorePopupStyle(
              backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
              borderColor: CoreColor.token(CoreColors.tertiary),
              borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
              padding: CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space24,
                vertical: CoreSpace.space8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}''',
  _ =>
    '''class HoverCardDefaultExample extends StatefulWidget {
  const HoverCardDefaultExample({super.key});

  @override
  State<HoverCardDefaultExample> createState() =>
      _HoverCardDefaultExampleState();
}

class _HoverCardDefaultExampleState extends State<HoverCardDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return HoverCard(
      trigger: const Text('@coui').bodyMedium.onPrimaryContainer.underline,
      content: const Text('크로스 플랫폼 UI 디자인 시스템.').bodySmall.onSurface,
      placement: CorePopoverPlacement.bottom,
    );
  }
}''',
};
