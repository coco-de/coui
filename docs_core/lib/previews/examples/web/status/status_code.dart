/// Returns a Web code snippet string for the Status component.
String statusCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class StatusChainExample extends StatefulComponent {
  const StatusChainExample({super.key});

  @override
  State<StatusChainExample> createState() => _StatusChainExampleState();
}

class _StatusChainExampleState extends State<StatusChainExample> {
  @override
  Component build(BuildContext context) {
    return Status(
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
class StatusDefaultExample extends StatefulComponent {
  const StatusDefaultExample({super.key});

  @override
  State<StatusDefaultExample> createState() => _StatusDefaultExampleState();
}

class _StatusDefaultExampleState extends State<StatusDefaultExample> {
  @override
  Component build(BuildContext context) {
    return Status(
      color: CoreStatusColor.primary,
      size: CoreStatusSize.lg,
    );
  }
}''',
  };
}
