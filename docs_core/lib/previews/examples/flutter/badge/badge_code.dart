/// Returns a Flutter code snippet string for the Badge component.
String badgeCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class BadgeChainExample extends StatelessWidget {
  const BadgeChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        Badge(
          tone: CoreBadgeTone.primary,
          variant: CoreBadgeVariant.filled,
          child: const Text('주요'),
        ).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        Badge(
          child: const Text('직접 지정'),
        ).withStyle(
          const CoreBadgeStyle(
            backgroundColor: .tertiaryContainer,
            foregroundColor: .onTertiaryContainer,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space12),
          ),
        ),
      ],
    );
  }
}''',
    'tones' =>
      '''
class BadgeTonesExample extends StatelessWidget {
  const BadgeTonesExample({super.key});

  @override
  Widget build(BuildContext context) {
    // The tone says what the colour means — the same tonal label in each.
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Theme.of(context).geometry.space(CoreSpace.space12),
      children: const [
        Badge(child: Text('중립')),
        Badge(tone: CoreBadgeTone.primary, child: Text('주요')),
        Badge(tone: CoreBadgeTone.info, child: Text('정보')),
        Badge(tone: CoreBadgeTone.success, child: Text('성공')),
        Badge(tone: CoreBadgeTone.warning, child: Text('경고')),
        Badge(tone: CoreBadgeTone.destructive, child: Text('위험')),
      ],
    );
  }
}''',
    'variants' =>
      '''
class BadgeVariantsExample extends StatelessWidget {
  const BadgeVariantsExample({super.key});

  @override
  Widget build(BuildContext context) {
    // The variant says how loud one tone is — a fill, a tint, or a line.
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Theme.of(context).geometry.space(CoreSpace.space12),
      children: const [
        Badge(tone: CoreBadgeTone.primary, variant: CoreBadgeVariant.filled, child: Text('채움')),
        Badge(tone: CoreBadgeTone.primary, variant: CoreBadgeVariant.tonal, child: Text('톤')),
        Badge(tone: CoreBadgeTone.primary, variant: CoreBadgeVariant.outlined, child: Text('외곽선')),
      ],
    );
  }
}''',
    'status' =>
      '''
class BadgeStatusExample extends StatelessWidget {
  const BadgeStatusExample({super.key});

  @override
  Widget build(BuildContext context) {
    // A status label — the tone's colour plus a leading dot in the label colour.
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Theme.of(context).geometry.space(CoreSpace.space12),
      children: const [
        Badge(tone: CoreBadgeTone.info, showDot: true, child: Text('검토 중')),
        Badge(tone: CoreBadgeTone.success, showDot: true, child: Text('승인됨')),
        Badge(tone: CoreBadgeTone.warning, showDot: true, child: Text('대기 중')),
        Badge(tone: CoreBadgeTone.destructive, showDot: true, child: Text('반려됨')),
        Badge(showDot: true, child: Text('임시 저장')),
      ],
    );
  }
}''',
    'count' =>
      '''
class BadgeCountExample extends StatelessWidget {
  const BadgeCountExample({super.key});

  @override
  Widget build(BuildContext context) {
    // A number sits in a pill that is never narrower than it is tall.
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Theme.of(context).geometry.space(CoreSpace.space12),
      children: const [
        Badge(
          tone: CoreBadgeTone.info,
          variant: CoreBadgeVariant.filled,
          form: CoreBadgeForm.count,
          size: CoreComponentSize.xs,
          child: Text('3'),
        ),
        Badge(
          variant: CoreBadgeVariant.filled,
          form: CoreBadgeForm.count,
          size: CoreComponentSize.xs,
          child: Text('12'),
        ),
        Badge(
          tone: CoreBadgeTone.info,
          variant: CoreBadgeVariant.filled,
          form: CoreBadgeForm.count,
          size: CoreComponentSize.sm,
          child: Text('8'),
        ),
        Badge(
          tone: CoreBadgeTone.destructive,
          variant: CoreBadgeVariant.filled,
          form: CoreBadgeForm.count,
          size: CoreComponentSize.sm,
          child: Text('99+'),
        ),
      ],
    );
  }
}''',
    'dot' =>
      '''
class BadgeDotExample extends StatelessWidget {
  const BadgeDotExample({super.key});

  @override
  Widget build(BuildContext context) {
    // A dot holds nothing, yet it still wears its tone — the form says
    // what is inside, not which colour it is.
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Theme.of(context).geometry.space(CoreSpace.space12),
      children: const [
        Badge(form: CoreBadgeForm.dot),
        Badge(tone: CoreBadgeTone.primary, form: CoreBadgeForm.dot),
        Badge(tone: CoreBadgeTone.info, form: CoreBadgeForm.dot),
        Badge(tone: CoreBadgeTone.success, form: CoreBadgeForm.dot),
        Badge(tone: CoreBadgeTone.warning, form: CoreBadgeForm.dot),
        Badge(tone: CoreBadgeTone.destructive, form: CoreBadgeForm.dot),
      ],
    );
  }
}''',
    _ =>
      '''
class BadgeDefaultExample extends StatelessWidget {
  const BadgeDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Every default — a neutral tone, tonal strength, a word, md.
    return const Badge(child: Text('신규'));
  }
}''',
  };
}
