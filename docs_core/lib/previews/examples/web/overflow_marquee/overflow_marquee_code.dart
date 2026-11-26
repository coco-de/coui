/// Code snippet for [OverflowMarquee] Web examples.
String overflowMarqueeCode(String? variant) => switch (variant) {
  'chain' => _chainCode,
  _ => _defaultCode,
};

const _chainCode = '''
class OverflowMarqueeChainExample extends StatelessComponent {
  /// Creates an [OverflowMarqueeChainExample].
  const OverflowMarqueeChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(raw: {'width': '\${CoreSpace.space240}px'}),
      [
        OverflowMarquee(
          pauseOnHover: true,
          child: const Text(
            '상자 폭을 넘는 긴 제목은 옆으로 흘러가며 끝까지 보여요.',
          ).bodyMedium.onSurface,
        ).withStyle(
          const CoreOverflowMarqueeStyle(
            duration: Duration(milliseconds: CoreDuration.ms5000),
            delayDuration: Duration(milliseconds: CoreDuration.slow),
            fadePortion: CoreSpace.space48,
          ),
        ),
      ],
    );
  }
}''';

const _defaultCode = '''
class OverflowMarqueeDefaultExample extends StatelessComponent {
  const OverflowMarqueeDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return div(
      styles: Styles(raw: {'width': '\${CoreSpace.space240}px'}),
      [
        OverflowMarquee(
          pauseOnHover: true,
          child: div(
            classes: 'text-\${CoreTextStyles.bodyMedium.name} text-\${cs.onSurface}',
            [
              Text(
                '상자 폭을 넘는 긴 제목은 옆으로 흘러가며 끝까지 보여요.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
''';
