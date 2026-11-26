/// Returns a Web code snippet string for the DisclosureBadge component.
String disclosureBadgeCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''class DisclosureBadgeChainExample extends StatelessComponent {
  const DisclosureBadgeChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const DisclosureBadge(
      kind: CoreDisclosureKind.commitment,
      label: '킥오프 시 제공',
    ).withStyle(
      const CoreDisclosureBadgeStyle(
        foregroundColor: CoreColor.token(CoreColors.primary),
        borderColor: CoreColor.token(CoreColors.primary),
        borderWidth: CoreStrokeWidth.stroke2,
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        padding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space8,
          vertical: CoreSpace.space4,
        ),
        labelStyle: CoreTextStyle.token(CoreTextStyles.labelMedium),
        markerSize: CoreSize.size6,
        markerSpacing: CoreSpace.space6,
      ),
    );
  }
}''',
    'commitment' =>
      '''
class DisclosureBadgeCommitmentExample extends StatelessComponent {
  const DisclosureBadgeCommitmentExample({super.key});

  @override
  Component build(BuildContext context) {
    return const DisclosureBadge(
      kind: CoreDisclosureKind.commitment,
      label: '계약 시 제공',
    );
  }
}''',
    'private' =>
      '''
class DisclosureBadgePrivateExample extends StatelessComponent {
  const DisclosureBadgePrivateExample({super.key});

  @override
  Component build(BuildContext context) {
    return const DisclosureBadge(
      kind: CoreDisclosureKind.private,
      label: '비공개 · NDA',
    );
  }
}''',
    _ =>
      '''
class DisclosureBadgeDefaultExample extends StatelessComponent {
  const DisclosureBadgeDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return const DisclosureBadge(
      kind: CoreDisclosureKind.open,
      label: '근거 공개',
    );
  }
}''',
  };
}
