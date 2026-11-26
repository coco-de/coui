/// Code snippet for `Breakpoint` Flutter examples.
String breakpointCode(String? variant) => _defaultCode;

const _defaultCode = '''
class BreakpointDefaultExample extends StatelessWidget {
  const BreakpointDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    final breakpoint = Breakpoint(context);
    return Container(
      width: double.infinity,
      padding: const CoreEdgeInsets.all(CoreSpace.space16).toValue(geometry: Theme.of(context).geometry),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer.toValue(),
        borderRadius: BorderRadius.circular(CoreRadius.radius8),
      ),
      child: Text(
        'width=\${breakpoint.width.toStringAsFixed(0)} '
        'tier=\${breakpoint.tier.name} '
        'coreBreakpoint=\${breakpoint.coreBreakpoint.name}',
      ).bodyMedium.onSurface,
    );
  }
}
''';
