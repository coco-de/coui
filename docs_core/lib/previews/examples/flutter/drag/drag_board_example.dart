import 'package:coui_flutter/coui_flutter.dart';

/// A two-column board built from drag primitives alone.
///
/// There is no board component: `DropZone` measures the columns,
/// `DragItem` measures the cards, and `CoreSortableAcross` reads both out
/// of the shared registry to say where a card would land.
class DragBoardExample extends StatefulWidget {
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
  Widget build(BuildContext context) {
    return DragScope(
      controller: _controller,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: Theme.of(context).geometry.space(CoreSpace.space12),
        children: [
          _buildColumn(_todo, '할 일'),
          _buildColumn(_doing, '진행 중'),
        ],
      ),
    );
  }

  Widget _buildColumn(CoreDragId column, String title) {
    final cs = Theme.of(context).colorScheme;

    return DropZone(
      id: column,
      builder: (context, dropDetails, child) => Card(
        cardStyle: CoreCardStyle(
          backgroundColor: dropDetails.isOver ? cs.surfaceContainerHigh : cs.surfaceContainer,
          padding: const CoreEdgeInsets.all(CoreSpace.space8),
        ),
        child: child,
      ),
      child: SizedBox(
        width: CoreSpace.space160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: Theme.of(context).geometry.space(CoreSpace.space8),
          children: [
            Text(title).labelMedium.onSurfaceVariant,
            for (final card in _board[column]!) _buildCard(card),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(CoreDragId card) => DragItem(
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
}
