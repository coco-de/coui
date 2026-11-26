import 'package:coui_flutter/coui_flutter.dart';

/// A dragged card lifted out of its clipping parent by `DragOverlay`.
///
/// The list clips its children, so the card alone would be cut off at the
/// boundary. The overlay draws the copy above everything instead.
class DragOverlayExample extends StatelessWidget {
  const DragOverlayExample({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DragScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: Theme.of(context).geometry.space(CoreSpace.space8),
        children: [
          ClipRect(
            child: SizedBox(
              height: CoreSize.size64,
              child: DragItem(
                id: const CoreDragId('card'),
                child: Card(
                  cardStyle: CoreCardStyle(
                    backgroundColor: cs.surfaceContainer,
                    padding: const CoreEdgeInsets.all(CoreSpace.space12),
                  ),
                  child: const Text('가장자리 밖으로 끌어 보세요').bodyMedium.onSurface,
                ),
              ),
            ),
          ),
          DragOverlay(
            builder: (context, session) => Card(
              cardStyle: CoreCardStyle(
                backgroundColor: cs.primaryContainer,
                padding: const CoreEdgeInsets.all(CoreSpace.space12),
              ),
              child: Text(session.activeId.value).bodyMedium.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
