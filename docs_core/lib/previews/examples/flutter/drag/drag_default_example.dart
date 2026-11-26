import 'package:coui_flutter/coui_flutter.dart';

/// The smallest complete drag interaction: one item, one zone.
class DragDefaultExample extends StatefulWidget {
  const DragDefaultExample({super.key});

  @override
  State<DragDefaultExample> createState() => _DragDefaultExampleState();
}

const _bin = CoreDragId('bin');

class _DragDefaultExampleState extends State<DragDefaultExample> {
  bool _dropped = false;

  void handleDragEnd(CoreDragEndEvent event) {
    setState(() => _dropped = event.overId == _bin);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DragScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: Theme.of(context).geometry.space(CoreSpace.space16),
        children: [
          DragItem(
            id: const CoreDragId('card'),
            onDragEnd: handleDragEnd,
            child: Card(
              cardStyle: CoreCardStyle(
                backgroundColor: cs.surfaceContainer,
                padding: const CoreEdgeInsets.all(CoreSpace.space12),
              ),
              child: const Text('끌어 보세요').bodyMedium.onSurface,
            ),
          ),
          DropZone(
            id: _bin,
            builder: (context, dropDetails, child) => Card(
              cardStyle: CoreCardStyle(
                backgroundColor: dropDetails.isOver ? cs.primaryContainer : cs.surfaceContainerLow,
                padding: const CoreEdgeInsets.all(CoreSpace.space16),
              ),
              child: child,
            ),
            child: Text(
              _dropped ? '놓았어요' : '여기에 놓으세요',
            ).bodyMedium.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
