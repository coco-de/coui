import 'package:coui_web/coui_web.dart';

/// A dragged card lifted out of its clipping parent by `DragOverlay`.
///
/// The list clips its children, so the card alone would be cut off at the
/// boundary. The overlay draws the copy above everything instead.
class DragOverlayExample extends StatelessComponent {
  const DragOverlayExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.colorScheme;

    return DragScope(
      child: div(
        [
          div(
            [
              DragItem(
                id: const CoreDragId('card'),
                child: Card(
                  cardStyle: CoreCardStyle(
                    backgroundColor: cs.surfaceContainer,
                    padding: const CoreEdgeInsets.all(CoreSpace.space12),
                  ),
                  child: const Text('가장자리 밖으로 끌어 보세요').bodyMedium.onSurface,
                ),
              ),
            ],
            classes: 'overflow-hidden h-${CoreSpace.scale.space64}',
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
        classes: 'flex flex-col items-start gap-${CoreSpace.scale.space8}',
      ),
    );
  }
}
