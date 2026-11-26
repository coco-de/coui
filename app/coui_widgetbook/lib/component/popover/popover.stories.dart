import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_i10n/coui_i10n.dart';
import 'package:widgetbook/widgetbook.dart';

part 'popover.stories.g.dart';

void _handleNoop() {}

/// Interactive demo host for [Popover] stories.
class PopoverDemo extends StatelessWidget {
  /// Creates a [PopoverDemo].
  const PopoverDemo({
    super.key,
    this.placement = CorePopoverPlacement.bottom,
  });

  /// Side of the trigger where the popover panel opens.
  final CorePopoverPlacement placement;

  @override
  Widget build(BuildContext context) {
    final strings = t.widgetbook.popover;

    return Popover(
      trigger: Button(
        onPressed: _handleNoop,
        child: Text(strings.show_popover),
      ),
      content: Card(
        header: Text(strings.content_title),
        body: Text(strings.content_description),
      ),
      placement: placement,
    );
  }
}

/// Navigation metadata for the Popover component.
const kComponentMeta = ComponentMeta(name: 'Popover', path: 'overlay');

/// Story metadata for [PopoverDemo].
const kMeta = Meta(PopoverDemo.new);

/// Click-triggered popover opening below the trigger.
final $Default = _Story();

/// Popover opening above the trigger.
final $Top = _Story(
  args: _Args(
    placement: EnumArg(
      CorePopoverPlacement.top,
      values: CorePopoverPlacement.values,
    ),
  ),
);

/// Popover opening to the left of the trigger.
final $Left = _Story(
  args: _Args(
    placement: EnumArg(
      CorePopoverPlacement.left,
      values: CorePopoverPlacement.values,
    ),
  ),
);

/// Popover opening to the right of the trigger.
final $Right = _Story(
  args: _Args(
    placement: EnumArg(
      CorePopoverPlacement.right,
      values: CorePopoverPlacement.values,
    ),
  ),
);
