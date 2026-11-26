import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'responsive_row_column.stories.g.dart';

// ResponsiveRowColumn widgetbook constants.
const _kPanelStyle = CoreCardStyle(
  padding: CoreEdgeInsets.all(CoreSpace.space16),
);
const _kPanelLabels = <String>['Sidebar', 'Content', 'Aside'];

/// Knob input for [ResponsiveRowColumn] stories.
///
/// `crossAxisAlignment` is deliberately absent: the generator would emit
/// a dropdown over every `CoreCrossAxisAlignment`, and `baseline` maps to
/// `CrossAxisAlignment.baseline`, which `Flex` asserts against unless a
/// `textBaseline` is supplied — the resolver supplies none, so picking it
/// would blow up the preview. It stays reachable through the Style slot.
class ResponsiveRowColumnInput {
  /// Creates a [ResponsiveRowColumnInput].
  const ResponsiveRowColumnInput({
    this.switchAt = CoreResponsiveRowColumnContract.defaultSwitchAt,
    this.spacing = CoreResponsiveRowColumnStyle.defaultSpacing,
    this.mainAxisAlignment =
        CoreResponsiveRowColumnStyle.defaultMainAxisAlignment,
  });

  /// Breakpoint tier at or above which the panels render as a `Row`;
  /// below it they stack into a `Column`.
  final CoreBreakpointTier switchAt;

  /// Spacing between panels, along whichever axis is currently the main
  /// one.
  final double spacing;

  /// Alignment along whichever axis is currently the main one.
  final CoreMainAxisAlignment mainAxisAlignment;
}

/// Navigation metadata for the ResponsiveRowColumn component.
const kComponentMeta = ComponentMeta(
  name: 'ResponsiveRowColumn',
  path: 'layout',
);

/// Story metadata for [ResponsiveRowColumn].
const kMeta = Meta(
  ResponsiveRowColumn.new,
  argsType: ResponsiveRowColumnInput.new,
);

/// Default builder mapping [ResponsiveRowColumnInput] args to a
/// [ResponsiveRowColumn].
///
/// Direction is read from the ambient viewport, not from this builder —
/// widen or narrow the preview pane past the `switchAt` tier and the same
/// three panels swap between a `Row` and a `Column`.
final ResponsiveRowColumnDefaults defaults = _Defaults(
  builder: (context, args) => ResponsiveRowColumn(
    switchAt: args.switchAt,
    responsiveRowColumnStyle: CoreResponsiveRowColumnStyle(
      spacing: args.spacing,
      mainAxisAlignment: args.mainAxisAlignment,
    ),
    children: [
      for (final label in _kPanelLabels)
        Card(cardStyle: _kPanelStyle, child: Text(label).bodyMedium),
    ],
  ),
);

/// Panels laid out as a `Row` from the tablet tier up, stacking into a
/// `Column` on narrower viewports.
final $Default = _Story();

/// Panels that stay a `Row` at every viewport width.
final $SwitchAtMobile = _Story(
  name: 'Switch At Mobile',
  args: _Args(
    switchAt: EnumArg(
      CoreBreakpointTier.mobile,
      values: CoreBreakpointTier.values,
    ),
  ),
);

/// Panels that stay a `Column` until the viewport reaches the desktop
/// tier.
final $SwitchAtDesktop = _Story(
  name: 'Switch At Desktop',
  args: _Args(
    switchAt: EnumArg(
      CoreBreakpointTier.desktop,
      values: CoreBreakpointTier.values,
    ),
  ),
);

/// Panels pushed to the far ends of whichever axis is currently the main
/// one.
final $SpaceBetween = _Story(
  name: 'Space Between',
  args: _Args(
    mainAxisAlignment: EnumArg(
      CoreMainAxisAlignment.spaceBetween,
      values: CoreMainAxisAlignment.values,
    ),
  ),
);
