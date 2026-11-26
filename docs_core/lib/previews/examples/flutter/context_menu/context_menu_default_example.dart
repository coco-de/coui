import 'package:coui_flutter/coui_flutter.dart';

class ContextMenuDefaultExample extends StatelessWidget {
  const ContextMenuDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ContextMenu(
      items: [
        CoreMenuItem.action('복사', onPressed: () {}),
        CoreMenuItem.action('붙여넣기', onPressed: () {}),
        const CoreMenuItem.divider(),
        CoreMenuItem.action('삭제', onPressed: () {}),
      ],
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: context.theme.colorScheme.outline.toValue(),
            width: CoreStrokeWidth.stroke1,
          ),
          borderRadius: BorderRadius.circular(CoreRadius.radius8),
        ),
        child: Padding(
          padding: const CoreEdgeInsets.symmetric(
            horizontal: CoreSpace.space24,
            vertical: CoreSpace.space16,
          ).toValue(geometry: Theme.of(context).geometry),
          child: Text('여기를 오른쪽 클릭해 보세요').bodyMedium,
        ),
      ),
    );
  }
}
