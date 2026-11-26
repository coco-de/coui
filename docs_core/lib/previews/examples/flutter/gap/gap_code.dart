/// Returns a Flutter code snippet string for the Gap component.
String gapCode(String? variant) {
  return switch (variant) {
    'chain' =>
      r'''
class GapChainExample extends StatelessWidget {
  const GapChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: const Text('A'),
        ),
        const Gap.space16().withStyle(
          const CoreGapStyle(
            size: CoreSpace.space64,
            crossAxisExtent: CoreSpace.space24,
            color: CoreColor.token(CoreColors.primary),
          ),
        ),
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: const Text('B'),
        ),
      ],
    );
  }
}
''',
    'max' =>
      r'''
class GapMaxExample extends StatelessWidget {
  const GapMaxExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: const Text('A'),
        ),
        const MaxGap.space64(),
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: const Text('B'),
        ),
      ],
    );
  }
}''',
    'sliver' =>
      r'''
class GapSliverExample extends StatelessWidget {
  const GapSliverExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.typography.bodyMedium.toValue(theme: theme).copyWith(
      color: theme.colorScheme.onSurface.toValue(),
    );
    return SizedBox(
      height: 160,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: Text('위 항목', style: textStyle)),
          const SliverGap.space24(),
          SliverToBoxAdapter(child: Text('가운데 항목', style: textStyle)),
          const SliverGap.space24(),
          SliverToBoxAdapter(child: Text('아래 항목', style: textStyle)),
        ],
      ),
    );
  }
}''',
    _ =>
      r'''
class GapDefaultExample extends StatelessWidget {
  const GapDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: const Text('A'),
        ),
        const Gap.space16(),
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: const Text('B'),
        ),
      ],
    );
  }
}''',
  };
}
