import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'breakpoint.stories.g.dart';

// Breakpoint widgetbook constants.
const _kObserveHostViewport = 0.0;
const _kMobileWidth = 420.0;
const _kTabletWidth = 820.0;
const _kDesktopWidth = 1280.0;
const _kDemoWidth = 360.0;
const _kPanePadding = CoreEdgeInsets.all(CoreSpace.space12);

/// Interactive demo host for [Breakpoint] stories.
///
/// [Breakpoint] renders nothing — it is a value accessor answering "how wide
/// is the global viewport right now" through [Breakpoint.width],
/// [Breakpoint.coreBreakpoint] and [Breakpoint.tier]. This host prints those
/// three values and branches its pane layout on the resolved tier, so the
/// branch is visible rather than merely described.
///
/// The preview box keeps a fixed width on purpose: [Breakpoint] observes the
/// global viewport rather than its own containing box, so the tier flips
/// while the box stays put.
class BreakpointDemo extends StatelessWidget {
  /// Creates a [BreakpointDemo].
  const BreakpointDemo({
    super.key,
    this.simulatedWidth = _kObserveHostViewport,
  });

  /// Viewport width in logical pixels reported to the subtree, or `0` to
  /// observe the widgetbook window itself.
  final double simulatedWidth;

  @override
  Widget build(BuildContext context) {
    const readout = SizedBox(width: _kDemoWidth, child: _BreakpointReadout());
    if (simulatedWidth <= _kObserveHostViewport) {
      return readout;
    }

    // Overriding `MediaQueryData.size` is how the component's own tests
    // drive it — `resolveBreakpoint` reads `MediaQuery.widthOf`, not the
    // surrounding layout constraints.
    final mediaQuery = MediaQuery.of(context);

    return MediaQuery(
      data: mediaQuery.copyWith(
        size: Size(simulatedWidth, mediaQuery.size.height),
      ),
      child: readout,
    );
  }
}

/// Value readout plus the tier-branched pane layout it explains.
class _BreakpointReadout extends StatelessWidget {
  const _BreakpointReadout();

  @override
  Widget build(BuildContext context) {
    final breakpoint = Breakpoint(context);
    final tier = breakpoint.tier;
    final panes = <Widget>[
      const _Pane(label: 'Content'),
      const _Pane(label: 'Sidebar'),
      if (tier.isAtLeast(.desktop)) const _Pane(label: 'Rail'),
    ];

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      spacing: CoreSpace.space12,
      children: [
        Text(
          'Viewport width — ${breakpoint.width.toStringAsFixed(0)} px',
        ).labelSmall.onSurfaceVariant,
        Text(
          'CoreBreakpoint.${breakpoint.coreBreakpoint.name} → '
          'CoreBreakpointTier.${tier.name}',
        ).bodySmall.onSurface,
        if (tier.isAtLeast(.tablet))
          Row(
            spacing: CoreSpace.space8,
            children: [for (final pane in panes) Expanded(child: pane)],
          )
        else
          Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            spacing: CoreSpace.space8,
            children: panes,
          ),
      ],
    );
  }
}

/// One layout pane whose presence and arrangement track the resolved tier.
class _Pane extends StatelessWidget {
  const _Pane({required this.label});

  /// Pane label.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      cardStyle: const CoreCardStyle(padding: _kPanePadding),
      child: Text(label).bodySmall.onSurface,
    );
  }
}

/// Navigation metadata for the Breakpoint component.
const kComponentMeta = ComponentMeta(name: 'Breakpoint', path: 'layout');

/// Story metadata for [BreakpointDemo].
const kMeta = Meta(BreakpointDemo.new);

/// Live reading of the widgetbook window — resize it to watch the tier flip.
final $Default = _Story();

/// Phone-width viewport: below the tablet boundary the panes stack.
final $Mobile = _Story(
  args: _Args(simulatedWidth: DoubleArg(_kMobileWidth)),
);

/// Tablet-width viewport: at or above 768 px the panes sit side by side.
final $Tablet = _Story(
  args: _Args(simulatedWidth: DoubleArg(_kTabletWidth)),
);

/// Desktop-width viewport: the rail pane appears, and the six-step
/// `CoreBreakpoint` scale (xl) diverges from the three-step tier (desktop).
final $Desktop = _Story(
  args: _Args(simulatedWidth: DoubleArg(_kDesktopWidth)),
);
