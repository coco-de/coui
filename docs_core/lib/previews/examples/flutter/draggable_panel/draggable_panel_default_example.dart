import 'package:coui_flutter/coui_flutter.dart';

/// Default preview for `DraggablePanel`: a floating tool palette docked
/// to the right edge with its panel open. Mirrors the Web counterpart —
/// same tool labels and same canvas placeholder.
class DraggablePanelDefaultExample extends StatefulWidget {
  const DraggablePanelDefaultExample({super.key});

  @override
  State<DraggablePanelDefaultExample> createState() => _DraggablePanelDefaultExampleState();
}

class _DraggablePanelDefaultExampleState extends State<DraggablePanelDefaultExample> {
  final CoreDraggablePanelController _controller = CoreDraggablePanelController(initiallyOpen: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 360,
      height: 360,
      child: DraggablePanel(
        controller: _controller,
        panel: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Theme.of(context).geometry.space(CoreSpace.space8),
          children: [
            const Text('펜').bodyMedium,
            const Text('지우개').bodyMedium,
            const Text('색상').bodyMedium,
          ],
        ),
        child: ColoredBox(
          color: theme.colorScheme.surfaceContainerLow.toValue(),
          child: Center(child: const Text('캔버스').bodyMedium),
        ),
      ),
    );
  }
}
