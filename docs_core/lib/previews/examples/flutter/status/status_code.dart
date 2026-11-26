/// Returns a Flutter code snippet string for the Status component.
String statusCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class StatusChainExample extends StatefulWidget {
  const StatusChainExample({super.key});

  @override
  State<StatusChainExample> createState() => _StatusChainExampleState();
}

class _StatusChainExampleState extends State<StatusChainExample> {
  @override
  Widget build(BuildContext context) {
    return const Status(
          color: CoreStatusColor.primary,
          size: CoreStatusSize.lg,
        )
        .withStyle(
          const CoreStatusStyle(
            size: CoreSize.size24,
            color: CoreColor.token(CoreColors.tertiary),
          ),
        )
        .radius16;
  }
}
''',
    _ =>
      '''
class StatusDefaultExample extends StatefulWidget {
  const StatusDefaultExample({super.key});

  @override
  State<StatusDefaultExample> createState() => _StatusDefaultExampleState();
}

class _StatusDefaultExampleState extends State<StatusDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return const Status(
      color: CoreStatusColor.primary,
      size: CoreStatusSize.lg,
    );
  }
}''',
  };
}
