/// Returns a Web code snippet string for the Badge component.
String badgeCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class BadgeChainExample extends StatelessComponent {
  const BadgeChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Badge(
          tone: CoreBadgeTone.primary,
          variant: CoreBadgeVariant.filled,
          child: Text('주요'),
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        Badge(
          child: Text('직접 지정'),
        ).withStyle(
          const CoreBadgeStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiaryContainer),
            foregroundColor: CoreColor.token(CoreColors.onTertiaryContainer),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space12),
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}''',
    'tones' =>
      '''
class BadgeTonesExample extends StatelessComponent {
  const BadgeTonesExample({super.key});

  @override
  Component build(BuildContext context) {
    // The tone says what the colour means — the same tonal label in each.
    return div([
      Badge(child: Text('중립')),
      Badge(tone: CoreBadgeTone.primary, child: Text('주요')),
      Badge(tone: CoreBadgeTone.info, child: Text('정보')),
      Badge(tone: CoreBadgeTone.success, child: Text('성공')),
      Badge(tone: CoreBadgeTone.warning, child: Text('경고')),
      Badge(tone: CoreBadgeTone.destructive, child: Text('위험')),
    ], classes: 'flex items-center gap-\${CoreSpace.scale.space12}');
  }
}''',
    'variants' =>
      '''
class BadgeVariantsExample extends StatelessComponent {
  const BadgeVariantsExample({super.key});

  @override
  Component build(BuildContext context) {
    // The variant says how loud one tone is — a fill, a tint, or a line.
    return div([
      Badge(tone: CoreBadgeTone.primary, variant: CoreBadgeVariant.filled, child: Text('채움')),
      Badge(tone: CoreBadgeTone.primary, variant: CoreBadgeVariant.tonal, child: Text('톤')),
      Badge(tone: CoreBadgeTone.primary, variant: CoreBadgeVariant.outlined, child: Text('외곽선')),
    ], classes: 'flex items-center gap-\${CoreSpace.scale.space12}');
  }
}''',
    'status' =>
      '''
class BadgeStatusExample extends StatelessComponent {
  const BadgeStatusExample({super.key});

  @override
  Component build(BuildContext context) {
    // A status label — the tone's colour plus a leading dot in the label colour.
    return div([
      Badge(tone: CoreBadgeTone.info, showDot: true, child: Text('검토 중')),
      Badge(tone: CoreBadgeTone.success, showDot: true, child: Text('승인됨')),
      Badge(tone: CoreBadgeTone.warning, showDot: true, child: Text('대기 중')),
      Badge(tone: CoreBadgeTone.destructive, showDot: true, child: Text('반려됨')),
      Badge(showDot: true, child: Text('임시 저장')),
    ], classes: 'flex items-center gap-\${CoreSpace.scale.space12}');
  }
}''',
    'count' =>
      '''
class BadgeCountExample extends StatelessComponent {
  const BadgeCountExample({super.key});

  @override
  Component build(BuildContext context) {
    // A number sits in a pill that is never narrower than it is tall.
    return div([
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
    ], classes: 'flex items-center gap-\${CoreSpace.scale.space12}');
  }
}''',
    'dot' =>
      '''
class BadgeDotExample extends StatelessComponent {
  const BadgeDotExample({super.key});

  @override
  Component build(BuildContext context) {
    // A dot holds nothing, yet it still wears its tone — the form says
    // what is inside, not which colour it is.
    return div([
      Badge(form: CoreBadgeForm.dot),
      Badge(tone: CoreBadgeTone.primary, form: CoreBadgeForm.dot),
      Badge(tone: CoreBadgeTone.info, form: CoreBadgeForm.dot),
      Badge(tone: CoreBadgeTone.success, form: CoreBadgeForm.dot),
      Badge(tone: CoreBadgeTone.warning, form: CoreBadgeForm.dot),
      Badge(tone: CoreBadgeTone.destructive, form: CoreBadgeForm.dot),
    ], classes: 'flex items-center gap-\${CoreSpace.scale.space12}');
  }
}''',
    _ =>
      '''
class BadgeDefaultExample extends StatelessComponent {
  const BadgeDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    // Every default — a neutral tone, tonal strength, a word, md.
    return Badge(child: Text('신규'));
  }
}''',
  };
}
