import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook/widgetbook.dart';

part 'scroll_area.stories.g.dart';

// ScrollArea widgetbook constants.
const _kViewportWidth = 260.0;
const _kVerticalMaxHeight = 180.0;
const _kHorizontalHeight = 96.0;
const _kHorizontalItemWidth = 64.0;
const _kItemCount = 20;

/// Knob input for [ScrollArea] stories.
class ScrollAreaInput {
  /// Creates a [ScrollAreaInput].
  const ScrollAreaInput({
    this.direction = CoreScrollAreaDirection.vertical,
    this.showScrollbar = true,
  });

  /// Scroll direction of the viewport.
  final CoreScrollAreaDirection direction;

  /// Whether the overlay scrollbar is shown.
  final bool showScrollbar;
}

/// Navigation metadata for the ScrollArea component.
const kComponentMeta = ComponentMeta(name: 'ScrollArea', path: 'layout');

/// Story metadata for [ScrollArea].
const kMeta = Meta(ScrollArea.new, argsType: ScrollAreaInput.new);

/// Default builder mapping [ScrollAreaInput] args to a [ScrollArea].
final ScrollAreaDefaults defaults = _Defaults(
  setup: (context, child, args) =>
      material.SizedBox(width: _kViewportWidth, child: child),
  builder: (context, args) => args.direction == .horizontal
      ? ScrollArea(
          direction: args.direction,
          showScrollbar: args.showScrollbar,
          scrollAreaStyle: const CoreScrollAreaStyle(
            height: _kHorizontalHeight,
          ),
          child: material.Row(
            spacing: CoreSpace.space8,
            children: [
              for (int i = 1; i <= _kItemCount; i += 1)
                material.SizedBox(
                  width: _kHorizontalItemWidth,
                  child: material.Center(child: Text('#$i').bodyMedium),
                ),
            ],
          ),
        )
      : ScrollArea(
          showScrollbar: args.showScrollbar,
          scrollAreaStyle: const CoreScrollAreaStyle(
            maxHeight: _kVerticalMaxHeight,
          ),
          child: material.Column(
            crossAxisAlignment: material.CrossAxisAlignment.start,
            spacing: CoreSpace.space8,
            children: [
              for (int i = 1; i <= _kItemCount; i += 1)
                Text('Item $i').bodyMedium,
            ],
          ),
        ),
);

/// Vertical scroll area with a scrollbar knob.
final $Default = _Story();

/// Horizontal scroll area.
final $Horizontal = _Story(
  args: _Args(
    direction: EnumArg(
      CoreScrollAreaDirection.horizontal,
      values: CoreScrollAreaDirection.values,
    ),
  ),
);
