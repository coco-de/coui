// preview-only sample item count.

import 'package:coui_flutter/coui_flutter.dart';

class FadeScrollHorizontalExample extends StatelessWidget {
  const FadeScrollHorizontalExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FadeScroll(
      direction: .horizontal,
      showScrollbar: true,
      child: Row(
        children: [
          for (var i = 0; i < 20; i += 1)
            Padding(
              padding: const CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space12,
              ).toValue(geometry: Theme.of(context).geometry),
              child: Center(
                child: Text('항목 ${i + 1}').bodyMedium.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}
