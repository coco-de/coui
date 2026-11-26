/// Returns a Flutter code snippet string for the Indicator component.
String indicatorCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class IndicatorChainExample extends StatelessWidget {
  const IndicatorChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Indicator(
      item: const Status(
        color: CoreStatusColor.success,
        size: CoreStatusSize.lg,
      ),
      child: const Avatar(initials: 'C'),
    ).withStyle(
      const CoreIndicatorStyle(offset: CoreSpace.space8),
    );
  }
}
''',
    'bottom-start' =>
      '''
class IndicatorBottomStartExample extends StatelessWidget {
  const IndicatorBottomStartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Indicator(
      horizontalPosition: CoreIndicatorHorizontalPosition.start,
      verticalPosition: CoreIndicatorVerticalPosition.bottom,
      item: Status(
        color: CoreStatusColor.warning,
        size: CoreStatusSize.lg,
      ),
      child: Avatar(initials: 'C'),
    );
  }
}''',
    _ =>
      '''
class IndicatorDefaultExample extends StatelessWidget {
  const IndicatorDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Indicator(
      item: Status(
        color: CoreStatusColor.success,
        size: CoreStatusSize.lg,
      ),
      child: Avatar(initials: 'C'),
    );
  }
}''',
  };
}
