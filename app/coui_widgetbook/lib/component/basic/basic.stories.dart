import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'basic.stories.g.dart';

const _kBasicWidth = 400.0;

/// Knob input for [Basic] stories.
class BasicInput {
  /// Creates a [BasicInput].
  const BasicInput({
    this.title = 'John Doe',
    this.subtitle = 'Software Engineer',
    this.content = 'This is the content area of the Basic layout.',
    this.showLeading = true,
    this.showTrailing = true,
  });

  /// Title text.
  final String title;

  /// Subtitle text.
  final String subtitle;

  /// Content area text.
  final String content;

  /// Whether the leading icon is shown.
  final bool showLeading;

  /// Whether the trailing icon is shown.
  final bool showTrailing;
}

/// Navigation metadata for the Basic layout component.
const kComponentMeta = ComponentMeta(name: 'Basic', path: 'layout');

/// Story metadata for [Basic].
const kMeta = Meta(Basic.new, argsType: BasicInput.new);

/// Default builder mapping [BasicInput] args to a [Basic] layout.
final BasicDefaults defaults = _Defaults(
  setup: (context, child, args) => SizedBox(
    width: _kBasicWidth,
    child: child,
  ),
  builder: (context, args) => Basic(
    leading: args.showLeading ? const Icon(LucideIcons.user) : null,
    title: Text(args.title),
    subtitle: Text(args.subtitle),
    content: Text(args.content),
    trailing: args.showTrailing ? const Icon(LucideIcons.chevronRight) : null,
  ),
);

/// Basic layout with editable knobs.
final $Default = _Story();
