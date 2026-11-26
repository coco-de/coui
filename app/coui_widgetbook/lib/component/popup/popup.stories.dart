import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'popup.stories.g.dart';

void _handleNoop() {}

/// Knob input for [Popup] stories.
class PopupInput {
  /// Creates a [PopupInput].
  const PopupInput({
    this.open = true,
    this.direction = CoreAxis.vertical,
  });

  /// Whether the popup panel is shown.
  final bool open;

  /// Main axis of the popup content.
  final CoreAxis direction;
}

/// Navigation metadata for the Popup component.
const kComponentMeta = ComponentMeta(name: 'Popup', path: 'infra');

/// Story metadata for [Popup].
const kMeta = Meta(Popup.new, argsType: PopupInput.new);

/// Default builder mapping [PopupInput] args to a menu-hosting [Popup].
final PopupDefaults defaults = _Defaults(
  builder: (context, args) => Popup(
    open: args.open,
    direction: args.direction,
    children: const [
      Menu(
        items: [
          CoreMenuItem.action(
            'New File',
            onPressed: _handleNoop,
            leading: Icon(RadixIcons.file),
          ),
          CoreMenuItem.action(
            'Open File',
            onPressed: _handleNoop,
            leading: Icon(RadixIcons.fileText),
          ),
          CoreMenuItem.divider(),
          CoreMenuItem.action(
            'Settings',
            onPressed: _handleNoop,
            leading: Icon(RadixIcons.gear),
          ),
        ],
      ),
    ],
  ),
);

/// Popup panel hosting a simple action menu.
final $Default = _Story();
