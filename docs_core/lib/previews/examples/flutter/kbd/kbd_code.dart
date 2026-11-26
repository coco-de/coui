/// Returns a Flutter code snippet string for the Kbd component.
String kbdCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class KbdChainExample extends StatelessWidget {
  const KbdChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Kbd(keys: ['Ctrl', 'C']).withStyle(
      const CoreKbdStyle(
        keyRadius: CoreBorderRadius.all(CoreRadius.radius9999),
        keyBackgroundColor: CoreColor.token(CoreColors.primaryContainer),
        keyBorderColor: CoreColor.token(CoreColors.primary),
        keyBorderWidth: CoreStrokeWidth.stroke2,
        keyPadding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space12,
          vertical: CoreSpace.space6,
        ),
        keyTextStyle: CoreTextStyle.token(
          CoreTextStyles.labelMedium,
          color: CoreColor.token(CoreColors.onPrimaryContainer),
        ),
      ),
    );
  }
}
''',
    'combo' =>
      '''
class KbdComboExample extends StatelessWidget {
  const KbdComboExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Kbd(keys: ['Ctrl', 'Shift', 'P']);
  }
}''',
    'single' =>
      '''
class KbdSingleExample extends StatelessWidget {
  const KbdSingleExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Kbd(keys: ['Esc']);
  }
}''',
    'four' =>
      '''
class KbdFourExample extends StatelessWidget {
  const KbdFourExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Kbd(keys: ['⌃', '⇧', '⌘', '4']);
  }
}''',
    _ =>
      '''
class KbdDefaultExample extends StatelessWidget {
  const KbdDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Kbd(keys: ['Ctrl', 'C']);
  }
}''',
  };
}
