import 'package:coui_flutter/coui_flutter.dart';

/// Live viewport readout for `Breakpoint`/`context.breakpointTier`.
///
/// Resize the browser window (or rotate/resize an emulator) and the
/// values below update automatically — `Breakpoint(context).width` reads
/// `MediaQuery.sizeOf(context)` under the hood, which registers an
/// `InheritedWidget` dependency on this widget's [BuildContext], so
/// Flutter rebuilds it on every viewport-size change with no extra
/// wiring (contrast with the Web example, which is one-shot by design
/// and needs its own resize listener).
class BreakpointDefaultExample extends StatelessWidget {
  /// Creates a [BreakpointDefaultExample].
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
        'width=${breakpoint.width.toStringAsFixed(0)} '
        'tier=${breakpoint.tier.name} '
        'coreBreakpoint=${breakpoint.coreBreakpoint.name}',
      ).bodyMedium.onSurface,
    );
  }
}
