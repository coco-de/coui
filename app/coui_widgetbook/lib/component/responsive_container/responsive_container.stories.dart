import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'responsive_container.stories.g.dart';

// ResponsiveContainer widgetbook constants.
const _kCardPadding = CoreEdgeInsets.all(CoreSpace.space16);

/// Knob input for [ResponsiveContainer] stories.
class ResponsiveContainerInput {
  /// Creates a [ResponsiveContainerInput].
  const ResponsiveContainerInput({
    this.maxWidth = CoreResponsiveContainerMaxWidth.sm,
    this.centered = true,
  });

  /// Breakpoint that caps the container width.
  final CoreResponsiveContainerMaxWidth maxWidth;

  /// Whether the constrained content is horizontally centered.
  final bool centered;
}

/// Navigation metadata for the ResponsiveContainer component.
const kComponentMeta = ComponentMeta(
  name: 'ResponsiveContainer',
  path: 'layout',
);

/// Story metadata for [ResponsiveContainer].
const kMeta = Meta(
  ResponsiveContainer.new,
  argsType: ResponsiveContainerInput.new,
);

/// Default builder mapping [ResponsiveContainerInput] args to a
/// [ResponsiveContainer].
final ResponsiveContainerDefaults defaults = _Defaults(
  builder: (context, args) {
    final resolvedMaxWidth = args.maxWidth.maxWidth;
    final breakpointLabel = resolvedMaxWidth == null
        ? 'no limit'
        : '${resolvedMaxWidth.toStringAsFixed(0)} px';
    final capLabel = 'the ${args.maxWidth.name} breakpoint ($breakpointLabel)';

    return ResponsiveContainer(
      maxWidth: args.maxWidth,
      centered: args.centered,
      child: Card(
        cardStyle: const CoreCardStyle(padding: _kCardPadding),
        child: Text(
          'Centered content capped at $capLabel max width.',
        ).bodyMedium.onSurface,
      ),
    );
  },
);

/// Content capped at the sm breakpoint.
final $Default = _Story();

/// Configurable breakpoint cap with centering knob.
final $MaxWidth = _Story(
  name: 'Max Width',
  args: _Args(
    maxWidth: EnumArg(
      CoreResponsiveContainerMaxWidth.md,
      values: CoreResponsiveContainerMaxWidth.values,
    ),
  ),
);
