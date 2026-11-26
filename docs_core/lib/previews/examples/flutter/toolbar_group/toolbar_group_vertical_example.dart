import 'package:coui_flutter/coui_flutter.dart';

class ToolbarGroupVerticalExample extends StatefulWidget {
  const ToolbarGroupVerticalExample({super.key});

  @override
  State<ToolbarGroupVerticalExample> createState() => _ToolbarGroupVerticalExampleState();
}

class _ToolbarGroupVerticalExampleState extends State<ToolbarGroupVerticalExample> {
  int _zoom = 100;

  void _handleZoomOut() => setState(() => _zoom = (_zoom - 10).clamp(50, 200));
  void _handleZoomIn() => setState(() => _zoom = (_zoom + 10).clamp(50, 200));

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('배율: $_zoom%'),
        const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space16)),
        ToolbarGroup(
          ariaLabel: '배율 조절',
          direction: CoreAxis.vertical,
          popupStyle: const CorePopupStyle(surfaceStyle: .liquidGlass),
          children: [
            Semantics(
              label: '확대',
              child: Button(
                variant: .ghost,
                shape: .square,
                onPressed: _zoom < 200 ? _handleZoomIn : null,
                child: const Icon(LucideIcons.plus),
              ),
            ),
            Semantics(
              label: '축소',
              child: Button(
                variant: .ghost,
                shape: .square,
                onPressed: _zoom > 50 ? _handleZoomOut : null,
                child: const Icon(LucideIcons.minus),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
