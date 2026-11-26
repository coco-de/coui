/// Code snippet for [OverflowMarquee] Flutter examples.
String overflowMarqueeCode(String? variant) => switch (variant) {
  'chain' => _chainCode,
  _ => _defaultCode,
};

const _chainCode = '''
class OverflowMarqueeChainExample extends StatelessWidget {
  /// Creates an [OverflowMarqueeChainExample].
  const OverflowMarqueeChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space240,
      child:
          OverflowMarquee(
            pauseOnHover: true,
            child: Text(
              '상자 폭을 넘는 긴 제목은 옆으로 흘러가며 끝까지 보여요.',
            ).bodyMedium.onSurface,
          ).withStyle(
            const CoreOverflowMarqueeStyle(
              duration: Duration(milliseconds: CoreDuration.ms5000),
              delayDuration: Duration(milliseconds: CoreDuration.slow),
              fadePortion: CoreSpace.space48,
            ),
          ),
    );
  }
}''';

const _defaultCode = '''
class OverflowMarqueeDefaultExample extends StatelessWidget {
  const OverflowMarqueeDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ts = theme.typography;
    return SizedBox(
      width: CoreSpace.space240,
      child: OverflowMarquee(
        pauseOnHover: true,
        child: DefaultTextStyle.merge(
          style: ts.bodyMedium.toValue(theme: Theme.of(context)).copyWith(color: cs.onSurface.toValue()),
          child: const Text(
            '상자 폭을 넘는 긴 제목은 옆으로 흘러가며 끝까지 보여요.',
          ),
        ),
      ),
    );
  }
}
''';
