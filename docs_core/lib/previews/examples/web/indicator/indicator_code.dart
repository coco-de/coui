/// Returns a Web code snippet string for the Indicator component.
String indicatorCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class IndicatorChainExample extends StatelessComponent {
  const IndicatorChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Indicator(
      item: Status(
        color: CoreStatusColor.success,
        size: CoreStatusSize.lg,
      ),
      child: Avatar(initials: 'C'),
    ).withStyle(
      const CoreIndicatorStyle(offset: CoreSpace.space8),
    );
  }
}
''',
    'bottom-start' =>
      '''
class IndicatorBottomStartExample extends StatelessComponent {
  const IndicatorBottomStartExample({super.key});

  @override
  Component build(BuildContext context) {
    return Indicator(
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
class IndicatorDefaultExample extends StatelessComponent {
  const IndicatorDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Indicator(
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
