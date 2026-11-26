/// Returns a Flutter code snippet string for the Timeline component.
String timelineCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''class TimelineChainExample extends StatelessWidget {
  const TimelineChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Timeline(
      items: [
        CoreTimelineItem(title: '주문 접수', timestamp: '오전 10:00'),
        CoreTimelineItem(title: '처리 중', timestamp: '오전 11:30'),
        CoreTimelineItem(title: '발송 완료', timestamp: '오후 2:00'),
      ],
    ).withStyle(
      const CoreTimelineStyle(
        dotColor: CoreColor.token(CoreColors.success),
        dotSize: CoreSpace.space16,
        dotCornerRadius: CoreRadius.radius4,
        connectorColor: CoreColor.token(CoreColors.outlineVariant),
        connectorThickness: CoreStrokeWidth.stroke4,
        titlePadding: CoreEdgeInsets.directional(start: CoreSpace.space16),
      ),
    );
  }
}''',
    _ =>
      '''
class TimelineDefaultExample extends StatelessWidget {
  const TimelineDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Timeline(
      items: [
        CoreTimelineItem(title: '주문 접수', timestamp: '오전 10:00'),
        CoreTimelineItem(title: '처리 중', timestamp: '오전 11:30'),
        CoreTimelineItem(title: '발송 완료', timestamp: '오후 2:00'),
      ],
    );
  }
}''',
  };
}
