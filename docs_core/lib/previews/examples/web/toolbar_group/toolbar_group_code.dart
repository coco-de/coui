String toolbarGroupCode(String? variant) => switch (variant) {
  'vertical' => _verticalCode,
  _ => _defaultCode,
};

const String _defaultCode = r'''class ToolbarGroupDefaultExample extends StatefulComponent {
  const ToolbarGroupDefaultExample({super.key});

  @override
  State<ToolbarGroupDefaultExample> createState() => _ToolbarGroupExampleState();
}

class _ToolbarGroupExampleState extends State<ToolbarGroupDefaultExample> {
  int _zoom = 100;

  void _handleZoomOut() => setState(() => _zoom = (_zoom - 10).clamp(50, 200));
  void _handleZoomIn() => setState(() => _zoom = (_zoom + 10).clamp(50, 200));

  @override
  Component build(BuildContext context) {
    return div(
      [
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
      classes: 'flex flex-col items-center',
    );
  }
}
''';

const String _verticalCode = r'''class ToolbarGroupVerticalExample extends StatefulComponent {
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
}''';
