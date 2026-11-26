import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'drawer.stories.g.dart';

/// Interactive demo host that opens a [Drawer] imperatively via
/// [openDrawer] — the canonical pattern shared with docs_site. The
/// panel's built-in header close button (`Drawer.title`) dismisses it;
/// the open future resolves on barrier tap / drag-to-dismiss / escape.
class DrawerDemo extends StatelessWidget {
  /// Creates a [DrawerDemo].
  const DrawerDemo({
    super.key,
    this.side = CoreDrawerSide.left,
    this.draggable = true,
    this.title = 'Drawer Title',
    this.content = 'This is the drawer content.',
    this.buttonLabel = 'Open Drawer',
    this.showFooter = false,
  });

  /// Edge the drawer slides in from.
  final CoreDrawerSide side;

  /// Whether the drawer can be dragged to dismiss.
  final bool draggable;

  /// Drawer header title.
  final String title;

  /// Drawer body text.
  final String content;

  /// Label of the trigger button.
  final String buttonLabel;

  /// Whether a Cancel / Save footer row is drawn under the content.
  final bool showFooter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Button(
        onPressed: () {
          unawaited(
            openDrawer(
              context: context,
              side: side,
              draggable: draggable,
              builder: (ctx) => Drawer(
                content: Text(content),
                title: title,
                footer: showFooter
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: CoreSpace.space8,
                        children: [
                          Button(
                            variant: CoreButtonVariant.secondary,
                            onPressed: () => closeDrawer<void>(ctx),
                            child: const Text('Cancel'),
                          ),
                          Button(
                            onPressed: () => closeDrawer<void>(ctx),
                            child: const Text('Save'),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
          );
        },
        child: Text(buttonLabel),
      ),
    );
  }
}

/// Navigation metadata for the Drawer component.
const kComponentMeta = ComponentMeta(name: 'Drawer', path: 'overlay');

/// Story metadata for [DrawerDemo].
const kMeta = Meta(DrawerDemo.new);

/// Side-panel drawer sliding in from the left edge.
final $Default = _Story();

/// Bottom-sheet flavour — the unified drawer presents from any side, so
/// a sheet is simply a drawer anchored to the bottom edge.
final $Sheet = _Story(
  args: _Args(
    side: EnumArg(CoreDrawerSide.bottom, values: CoreDrawerSide.values),
    title: StringArg('Sheet Title'),
    content: StringArg('This is the sheet content.'),
    buttonLabel: StringArg('Open Sheet'),
  ),
);

/// Side panel with a Cancel / Save footer under the content.
final $WithFooter = _Story(
  args: _Args(
    side: EnumArg(CoreDrawerSide.right, values: CoreDrawerSide.values),
    showFooter: BoolArg(true),
    buttonLabel: StringArg('Open Drawer With Footer'),
  ),
);
