import 'package:coui_web/coui_web.dart';

/// Live viewport readout for `Breakpoint`/`context.breakpointTier`.
///
/// `resolveBreakpoint` observes the viewport once per call on Web (a
/// deliberate one-shot design — see its doc comment in
/// `breakpoint_style.dart`), so this example wires up a small `window`
/// `resize` listener + `setState`: exactly the `StatefulComponent`
/// pattern a real consumer builds when it wants live reactivity on Web.
/// Resize the browser window and the readout below updates.
class BreakpointDefaultExample extends StatefulComponent {
  /// Creates a [BreakpointDefaultExample].
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
          'width=${breakpoint.width.toStringAsFixed(0)} '
          'tier=${breakpoint.tier.name} '
          'coreBreakpoint=${breakpoint.coreBreakpoint.name}',
        ).bodyMedium.onSurface,
      ],
      classes: 'w-full p-${CoreSpace.scale.space16} rounded-${CoreRadius.scale.radius8} bg-${cs.surfaceContainer}',
    );
  }
}
