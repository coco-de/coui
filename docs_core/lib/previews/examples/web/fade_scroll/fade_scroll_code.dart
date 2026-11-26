/// Returns a Web code snippet string for the FadeScroll component.
String fadeScrollCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class FadeScrollChainExample extends StatelessComponent {
  const FadeScrollChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        FadeScroll(
          child: div([
            for (var i = 0; i < 20; i += 1)
              div(
                [Text('항목 \${i + 1}').bodyMedium.onSurface],
                classes: 'py-\${CoreSpace.scale.space8} px-\${CoreSpace.scale.space16}',
              ),
          ]),
        ).withStyle(
          const CoreFadeScrollStyle(
            startOffset: CoreSpace.space80,
            endOffset: CoreSpace.space80,
            gradient: [
              CoreColor.token(CoreColors.primary),
              CoreColor.transparent,
            ],
          ),
        ),
      ],
      classes: 'inline-flex',
      styles: Styles(raw: {'height': '\${CoreSpace.space200}px'}),
    );
  }
}
''',
    'with-scrollbar' =>
      '''
class FadeScrollWithScrollbarExample extends StatelessComponent {
  const FadeScrollWithScrollbarExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        FadeScroll(
          showScrollbar: true,
          child: div([
            for (var i = 0; i < 20; i += 1)
              div(
                [Text('항목 \${i + 1}').bodyMedium.onSurface],
                classes: 'py-2 px-4',
              ),
          ]),
        ),
      ],
      classes: 'inline-flex',
      styles: Styles(raw: {'height': '200px'}),
    );
  }
}''',
    'horizontal' =>
      '''
class FadeScrollHorizontalExample extends StatelessComponent {
  const FadeScrollHorizontalExample({super.key});

  @override
  Component build(BuildContext context) {
    return FadeScroll(
      direction: .horizontal,
      showScrollbar: true,
      child: div(
        [
          for (var i = 0; i < 20; i += 1)
            div(
              [Text('항목 \${i + 1}').bodyMedium.onSurface],
              classes: 'flex items-center px-3 whitespace-nowrap',
            ),
        ],
        classes: 'flex',
        styles: Styles(raw: {'width': 'max-content'}),
      ),
    );
  }
}''',
    _ =>
      '''
class FadeScrollDefaultExample extends StatelessComponent {
  const FadeScrollDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        FadeScroll(
          child: div([
            for (var i = 0; i < 20; i += 1)
              div(
                [Text('항목 \${i + 1}').bodyMedium.onSurface],
                classes: 'py-2 px-4',
              ),
          ]),
        ),
      ],
      classes: 'inline-flex',
      styles: Styles(raw: {'height': '200px'}),
    );
  }
}''',
  };
}
