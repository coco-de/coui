import 'package:coui_web/coui_web.dart';

class ToolbarGroupVerticalExample extends StatefulComponent {
  const ToolbarGroupVerticalExample({super.key});

  @override
  State<ToolbarGroupVerticalExample> createState() => _ToolbarGroupVerticalExampleState();
}

class _ToolbarGroupVerticalExampleState extends State<ToolbarGroupVerticalExample> {
  int _zoom = 100;

  void _handleZoomOut() => setState(() => _zoom = (_zoom - 10).clamp(50, 200));
  void _handleZoomIn() => setState(() => _zoom = (_zoom + 10).clamp(50, 200));

  @override
  Component build(BuildContext context) {
    return div(
      [
        Text('배율: $_zoom%'),
        const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space16)),
        ToolbarGroup(
          ariaLabel: '배율 조절',
          direction: CoreAxis.vertical,
          popupStyle: const CorePopupStyle(surfaceStyle: .liquidGlass),
          children: [
            Button(
              variant: .ghost,
              shape: .square,
              onPressed: _zoom < 200 ? _handleZoomIn : null,
              attributes: const {'aria-label': '확대'},
              child: const Icon(LucideIcons.plus),
            ),
            Button(
              variant: .ghost,
              shape: .square,
              onPressed: _zoom > 50 ? _handleZoomOut : null,
              attributes: const {'aria-label': '축소'},
              child: const Icon(LucideIcons.minus),
            ),
          ],
        ),
      ],
      classes: 'flex flex-row items-center',
    );
  }
}
