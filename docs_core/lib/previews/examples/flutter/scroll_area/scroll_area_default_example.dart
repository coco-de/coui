import 'package:coui_flutter/coui_flutter.dart';

class ScrollAreaDefaultExample extends StatelessWidget {
  const ScrollAreaDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: ScrollArea(
        scrollAreaStyle: const CoreScrollAreaStyle(maxHeight: 180),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Theme.of(context).geometry.space(CoreSpace.space8),
          children: [
            for (var i = 1; i <= 20; i += 1) Text('스크롤 항목 $i').bodyMedium,
          ],
        ),
      ),
    );
  }
}
