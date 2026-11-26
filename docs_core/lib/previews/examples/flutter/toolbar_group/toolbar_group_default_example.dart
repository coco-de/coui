import 'package:coui_flutter/coui_flutter.dart';

class ToolbarGroupDefaultExample extends StatefulWidget {
  const ToolbarGroupDefaultExample({super.key});

  @override
  State<ToolbarGroupDefaultExample> createState() => _ToolbarGroupExampleState();
}

class _ToolbarGroupExampleState extends State<ToolbarGroupDefaultExample> {
  int _zoom = 100;

  void _handleZoomOut() => setState(() => _zoom = (_zoom - 10).clamp(50, 200));
  void _handleZoomIn() => setState(() => _zoom = (_zoom + 10).clamp(50, 200));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('배율: $_zoom%'),
        ToolbarGroup(
          ariaLabel: '배율 조절',
          popupStyle: const CorePopupStyle(surfaceStyle: .liquidGlass),
          children: [
            Button(variant: .ghost, onPressed: _zoom > 50 ? _handleZoomOut : null, child: const Text('축소')),
            Button(variant: .ghost, onPressed: _zoom < 200 ? _handleZoomIn : null, child: const Text('확대')),
          ],
        ),
      ],
    );
  }
}
