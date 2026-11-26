/// Returns a Flutter code snippet string for the Swap component.
String swapCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class SwapChainExample extends StatefulWidget {
  const SwapChainExample({super.key});

  @override
  State<SwapChainExample> createState() => _SwapChainExampleState();
}

class _SwapChainExampleState extends State<SwapChainExample> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return Swap(
      checked: _checked,
      onContent: const Text('켜짐'),
      offContent: const Text('꺼짐'),
      onToggle: (v) => setState(() => _checked = v),
    ).withStyle(
      const CoreSwapStyle(
        duration: Duration(milliseconds: CoreDuration.slow),
        textStyle: CoreTextStyle.token(
          CoreTextStyles.titleMedium,
          color: CoreColor.token(CoreColors.primary),
        ),
        clickableStyle: CoreClickableStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        ),
      ),
    );
  }
}''',
    'rotate' =>
      '''
class SwapRotateExample extends StatefulWidget {
  const SwapRotateExample({super.key});

  @override
  State<SwapRotateExample> createState() => _SwapRotateExampleState();
}

class _SwapRotateExampleState extends State<SwapRotateExample> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return Swap(
      checked: _checked,
      animation: CoreSwapAnimation.rotate,
      onContent: const Text('켜짐'),
      offContent: const Text('꺼짐'),
      onToggle: (v) => setState(() => _checked = v),
    );
  }
}''',
    'flip' =>
      '''
class SwapFlipExample extends StatefulWidget {
  const SwapFlipExample({super.key});

  @override
  State<SwapFlipExample> createState() => _SwapFlipExampleState();
}

class _SwapFlipExampleState extends State<SwapFlipExample> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return Swap(
      checked: _checked,
      animation: CoreSwapAnimation.flip,
      onContent: const Text('켜짐'),
      offContent: const Text('꺼짐'),
      onToggle: (v) => setState(() => _checked = v),
    );
  }
}''',
    _ =>
      '''
class SwapDefaultExample extends StatefulWidget {
  const SwapDefaultExample({super.key});

  @override
  State<SwapDefaultExample> createState() => _SwapDefaultExampleState();
}

class _SwapDefaultExampleState extends State<SwapDefaultExample> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return Swap(
      checked: _checked,
      onContent: const Text('켜짐'),
      offContent: const Text('꺼짐'),
      onToggle: (v) => setState(() => _checked = v),
    );
  }
}''',
  };
}
