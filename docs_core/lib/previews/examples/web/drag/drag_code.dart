/// Returns a Web code snippet string for the drag primitives.
String dragCode(String? variant) {
  return switch (variant) {
    'board' =>
      '''
/// A two-column board built from drag primitives alone.
///
/// There is no board component: `DropZone` measures the columns,
/// `DragItem` measures the cards, and `CoreSortableAcross` reads both out
/// of the shared registry to say where a card would land.
class DragBoardExample extends StatefulComponent {
  const DragBoardExample({super.key});

  @override
  State<DragBoardExample> createState() => _DragBoardExampleState();
}

const _todo = CoreDragId('todo');
const _doing = CoreDragId('doing');

class _DragBoardExampleState extends State<DragBoardExample> {
  final DragScopeController _controller = DragScopeController();

  Map<CoreDragId, List<CoreDragId>> _board = {
    _todo: const [CoreDragId('명세 작성'), CoreDragId('PR 리뷰')],
    _doing: const [CoreDragId('버그 수정')],
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void handleDragEnd(CoreDragEndEvent event) {
    final result = CoreSortableAcross.resolve(
      activeId: event.session.activeId,
      containers: _board,
      itemRects: _controller.registry.itemRects,
      // The columns registered themselves as drop zones, so their measured
      // rects are already here — nothing extra to wire up.
      containerRects: _controller.registry.dropZoneRects,
      pointer: event.session.pointer,
      transform: event.session.transform,
    );
    if (!result.moves) return;

    setState(() {
      final next = {
        for (final entry in _board.entries) entry.key: [...entry.value],
      };
      next[result.fromContainer]!.removeAt(result.fromIndex);
      next[result.toContainer]!.insert(
        result.toIndex.clamp(0, next[result.toContainer]!.length),
        event.session.activeId,
      );
      _board = next;
    });
  }

  @override
  Component build(BuildContext context) {
    return DragScope(
      controller: _controller,
      child: div(
        [_buildColumn(context, _todo, '할 일'), _buildColumn(context, _doing, '진행 중')],
        classes: 'flex items-start gap-\${CoreSpace.scale.space12}',
      ),
    );
  }

  Component _buildColumn(BuildContext context, CoreDragId column, String title) {
    final cs = context.colorScheme;

    return DropZone(
      id: column,
      builder: (context, dropDetails, child) => Card(
        cardStyle: CoreCardStyle(
          backgroundColor: dropDetails.isOver
              ? cs.surfaceContainerHigh
              : cs.surfaceContainer,
          padding: const CoreEdgeInsets.all(CoreSpace.space8),
        ),
        child: child,
      ),
      child: div(
        [
          Text(title).labelMedium.onSurfaceVariant,
          for (final card in _board[column]!) _buildCard(card),
        ],
        classes:
            'flex flex-col w-\${CoreSpace.scale.space160} '
            'gap-\${CoreSpace.scale.space8}',
      ),
    );
  }

  Component _buildCard(CoreDragId card) => DragItem(
    id: card,
    onDragEnd: handleDragEnd,
    child: Card(
      cardStyle: const CoreCardStyle(
        padding: CoreEdgeInsets.all(CoreSpace.space8),
        sizing: CoreCardSizing.expand,
      ),
      child: Text(card.value).bodySmall.onSurface,
    ),
  );
}''',
    'overlay' =>
      '''
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
            classes: 'overflow-hidden h-\${CoreSpace.scale.space64}',
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
        classes: 'flex flex-col items-start gap-\${CoreSpace.scale.space8}',
      ),
    );
  }
}''',
    _ =>
      '''
/// The smallest complete drag interaction: one item, one zone.
class DragDefaultExample extends StatefulComponent {
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
  Component build(BuildContext context) {
    final cs = context.colorScheme;

    return DragScope(
      child: div(
        [
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
                backgroundColor: dropDetails.isOver
                    ? cs.primaryContainer
                    : cs.surfaceContainerLow,
                padding: const CoreEdgeInsets.all(CoreSpace.space16),
              ),
              child: child,
            ),
            child: Text(
              _dropped ? '놓았어요' : '여기에 놓으세요',
            ).bodyMedium.onSurfaceVariant,
          ),
        ],
        classes: 'flex flex-col items-start gap-\${CoreSpace.scale.space16}',
      ),
    );
  }
}''',
  };
}
