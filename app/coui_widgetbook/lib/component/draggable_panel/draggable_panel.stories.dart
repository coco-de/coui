import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'draggable_panel.stories.g.dart';

// DraggablePanel widgetbook constants.
const _kCanvasSize = 320.0;
const _kCanvasColor = Color(0x110A84FF);

/// Interactive demo host that owns the [CoreDraggablePanelController] so
/// the handle position and open state survive knob-driven rebuilds.
class DraggablePanelDemo extends StatefulWidget {
  /// Creates a [DraggablePanelDemo].
  const DraggablePanelDemo({
    super.key,
    this.dockType = CoreDraggablePanelDockType.inside,
    this.closeOnTapOutside = true,
  });

  /// How the handle docks against the viewport edge.
  final CoreDraggablePanelDockType dockType;

  /// Whether tapping outside the panel closes it.
  final bool closeOnTapOutside;

  @override
  State<DraggablePanelDemo> createState() => _DraggablePanelDemoState();
}

class _DraggablePanelDemoState extends State<DraggablePanelDemo> {
  final CoreDraggablePanelController _controller = CoreDraggablePanelController(
    initiallyOpen: true,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: _kCanvasSize,
      child: DraggablePanel(
        panel: const Column(
          mainAxisSize: .min,
          spacing: CoreSpace.space8,
          children: [
            Text('Pen'),
            Text('Eraser'),
            Text('Color'),
          ],
        ),
        dockType: widget.dockType,
        closeOnTapOutside: widget.closeOnTapOutside,
        controller: _controller,
        child: const ColoredBox(
          color: _kCanvasColor,
          child: Center(child: Text('Canvas')),
        ),
      ),
    );
  }
}

/// Navigation metadata for the DraggablePanel component.
const kComponentMeta = ComponentMeta(name: 'DraggablePanel', path: 'layout');

/// Story metadata for [DraggablePanelDemo].
const kMeta = Meta(DraggablePanelDemo.new);

/// Default draggable panel over a canvas with editable knobs.
final $Default = _Story();
