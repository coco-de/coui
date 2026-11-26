import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook/widgetbook.dart';

part 'resizable.stories.g.dart';

// Resizable widgetbook constants.
const _kDemoWidth = 360.0;
const _kDemoHeight = 220.0;
const _kPaneAInitialSize = 0.4;
const _kPaneBInitialSize = 0.6;
const _kPercentMultiplier = 100;

/// Interactive demo host for [Resizable] stories.
///
/// Renders a two-pane split and optionally reports live pane sizes via
/// [Resizable.onResize].
class ResizableDemo extends material.StatefulWidget {
  /// Creates a [ResizableDemo].
  const ResizableDemo({
    super.key,
    this.direction = CoreResizableDirection.horizontal,
    this.showDragHandle = false,
    this.showSizes = false,
  });

  /// Split direction of the panes.
  final CoreResizableDirection direction;

  /// Whether the divider renders a visible drag handle.
  final bool showDragHandle;

  /// Whether the live pane size ratios are shown below the split.
  final bool showSizes;

  @override
  material.State<ResizableDemo> createState() => _ResizableDemoState();
}

class _ResizableDemoState extends material.State<ResizableDemo> {
  List<double> _sizes = const [_kPaneAInitialSize, _kPaneBInitialSize];

  void handleResize(List<double> sizes) {
    setState(() => _sizes = sizes);
  }

  @override
  material.Widget build(material.BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sizesLabel = _sizes
        .map((s) => '${(s * _kPercentMultiplier).round()}%')
        .join(' / ');

    return material.Column(
      mainAxisSize: material.MainAxisSize.min,
      spacing: CoreSpace.space12,
      children: [
        material.SizedBox(
          width: _kDemoWidth,
          height: _kDemoHeight,
          child: Resizable(
            panes: [
              CoreResizablePaneData(
                content: material.Container(
                  alignment: material.Alignment.center,
                  color: scheme.surfaceContainer.toValue(),
                  child: const Text('Panel A').bodySmall().onSurface(),
                ),
                initialSize: _kPaneAInitialSize,
              ),
              CoreResizablePaneData(
                content: material.Container(
                  alignment: material.Alignment.center,
                  color: scheme.surfaceContainerHigh.toValue(),
                  child: const Text('Panel B').bodySmall().onSurface(),
                ),
                initialSize: _kPaneBInitialSize,
              ),
            ],
            direction: widget.direction,
            onResize: handleResize,
            showDragHandle: widget.showDragHandle,
          ),
        ),
        if (widget.showSizes)
          Text('Sizes: $sizesLabel').bodySmall().onSurface(),
      ],
    );
  }
}

/// Navigation metadata for the Resizable component.
const kComponentMeta = ComponentMeta(name: 'Resizable', path: 'layout');

/// Story metadata for [ResizableDemo].
const kMeta = Meta(ResizableDemo.new);

/// Two-pane split with direction and drag-handle knobs.
final $Default = _Story();

/// Split reporting live pane sizes while dragging.
final $Interactive = _Story(
  args: _Args(showSizes: BoolArg(true)),
);
