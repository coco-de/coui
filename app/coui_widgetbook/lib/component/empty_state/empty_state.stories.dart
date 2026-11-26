import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'empty_state.stories.g.dart';

/// Knob input for [EmptyState] stories.
class EmptyStateInput {
  /// Creates an [EmptyStateInput].
  const EmptyStateInput({
    this.title = 'No results found',
    this.description = 'Try adjusting your search or filter criteria',
    this.showIcon = true,
    this.showAction = true,
  });

  /// Empty state title text.
  final String title;

  /// Supporting description text (hidden when empty).
  final String description;

  /// Whether the leading icon is shown.
  final bool showIcon;

  /// Whether the action button is shown.
  final bool showAction;
}

/// Navigation metadata for the EmptyState component.
const kComponentMeta = ComponentMeta(name: 'EmptyState', path: 'display');

/// Story metadata for [EmptyState].
const kMeta = Meta(EmptyState.new, argsType: EmptyStateInput.new);

void _handleNoop() {}

/// Default builder mapping [EmptyStateInput] args to an [EmptyState].
final EmptyStateDefaults defaults = _Defaults(
  setup: (context, child, args) => Center(child: child),
  builder: (context, args) => EmptyState(
    title: Text(args.title),
    icon: args.showIcon ? const Icon(LucideIcons.searchX) : null,
    description: args.description.isNotEmpty ? Text(args.description) : null,
    action: args.showAction
        ? const Button(
            onPressed: _handleNoop,
            child: Text('Clear Filters'),
          )
        : null,
  ),
);

/// Default empty state with icon, description and action knobs.
final $Default = _Story();
