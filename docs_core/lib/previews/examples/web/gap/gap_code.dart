/// Returns a Web code snippet string for the Gap component.
String gapCode(String? variant) {
  return switch (variant) {
    'chain' =>
      r'''
class GapChainExample extends StatelessComponent {
  const GapChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: Text('A'),
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
          child: Text('B'),
        ),
      ],
      classes: 'inline-flex flex-row items-center',
    );
  }
}
''',
    'max' =>
      r'''
class GapMaxExample extends StatelessComponent {
  const GapMaxExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: Text('A'),
        ),
        MaxGap.space64(),
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: Text('B'),
        ),
      ],
      classes: 'inline-flex flex-row items-center',
    );
  }
}''',
    'sliver' =>
      r'''
class GapSliverExample extends StatelessComponent {
  const GapSliverExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.colorScheme;
    final textClass = 'text-\${CoreTextStyles.bodyMedium.name} text-\${cs.onSurface}';
    return div(
      [
        div([Text('위 항목')], classes: textClass),
        SliverGap.space24(),
        div([Text('가운데 항목')], classes: textClass),
        SliverGap.space24(),
        div([Text('아래 항목')], classes: textClass),
      ],
      // `w-full` mirrors Flutter's `CustomScrollView`, which always
      // stretches to the cross-axis extent — without it the column
      // shrinks to fit and the preview centres it while Flutter's list
      // sits at the left edge.
      classes: 'flex flex-col items-start w-full',
      styles: Styles(raw: {'height': '\${160 / 16}rem'}),
    );
  }
}''',
    _ =>
      r'''
class GapDefaultExample extends StatelessComponent {
  const GapDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: Text('A'),
        ),
        Gap.space16(),
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: Text('B'),
        ),
      ],
      classes: 'inline-flex flex-row items-center',
    );
  }
}''',
  };
}
