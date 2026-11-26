// preview-only sample item count.

import 'package:coui_flutter/coui_flutter.dart';

class FadeScrollWithScrollbarExample extends StatelessWidget {
  const FadeScrollWithScrollbarExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CoreSpace.space200,
      child: FadeScroll(
        showScrollbar: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < 20; i += 1)
              Padding(
                padding: const CoreEdgeInsets.symmetric(
                  vertical: CoreSpace.space8,
                  horizontal: CoreSpace.space16,
                ).toValue(geometry: Theme.of(context).geometry),
                child: Text('항목 ${i + 1}').bodyMedium.onSurface,
              ),
          ],
        ),
      ),
    );
  }
}
