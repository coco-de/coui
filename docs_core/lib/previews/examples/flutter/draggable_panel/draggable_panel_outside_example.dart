import 'package:coui_flutter/coui_flutter.dart';

/// `outside` dock preview: the closed handle rests half past the right
/// edge; tapping it pulls it back in and opens the panel. Mirrors the Web
/// counterpart — same tool labels and same canvas placeholder.
class DraggablePanelOutsideExample extends StatelessWidget {
  const DraggablePanelOutsideExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 360,
      height: 360,
      child: DraggablePanel(
        dockType: CoreDraggablePanelDockType.outside,
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
