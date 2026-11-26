/// Code snippet for `Breakpoint` Web examples.
String breakpointCode(String? variant) => _defaultCode;

const _defaultCode = '''
class BreakpointDefaultExample extends StatefulComponent {
  const BreakpointDefaultExample({super.key});

  @override
  State<BreakpointDefaultExample> createState() => _BreakpointDefaultExampleState();
}

class _BreakpointDefaultExampleState extends State<BreakpointDefaultExample> {
  void Function()? _disposeListener;

  @override
  void initState() {
    super.initState();
    _disposeListener = listenForViewportResize(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _disposeListener?.call();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final breakpoint = Breakpoint(context);
    final cs = context.theme.colorScheme;
    return div(
      [
        Text(
          'width=\${breakpoint.width.toStringAsFixed(0)} '
          'tier=\${breakpoint.tier.name} '
          'coreBreakpoint=\${breakpoint.coreBreakpoint.name}',
        ).bodyMedium.onSurface,
      ],
      classes: 'w-full p-\${CoreSpace.scale.space16} rounded-\${CoreRadius.scale.radius8} bg-\${cs.surfaceContainer}',
    );
  }
}
''';
