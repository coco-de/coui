/// Source snippet for the Web `CardImage` previews.
///
/// Each case must mirror its matching `card_image_*_example.dart` file
/// verbatim (minus imports) so the docs site's "View code" tab stays in
/// sync.
String cardImageCode(String? variant) => switch (variant) {
  'chain' =>
    '''
class CardImageChainExample extends StatelessComponent {
  const CardImageChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        div(
          [
            CardImage(
              image: img(
                src: 'https://picsum.photos/seed/coui/240/160',
                classes: 'block object-cover',
                styles: Styles(
                  raw: const {
                    'width': '240px',
                    'height': '160px',
                    'margin': '0',
                  },
                ),
              ),
              title: Text('산 풍경'),
              subtitle: Text('해 뜰 무렵 촬영'),
              onPressed: () {},
            ).radius16.primary,
          ],
          styles: Styles(raw: const {'width': '240px'}),
        ),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(frameStyle.borderColor)
        // 까지 한 번에.
        div(
          [
            CardImage(
              image: img(
                src: 'https://picsum.photos/seed/coui/240/160',
                classes: 'block object-cover',
                styles: Styles(
                  raw: const {
                    'width': '240px',
                    'height': '160px',
                    'margin': '0',
                  },
                ),
              ),
              title: Text('산 풍경'),
              subtitle: Text('해 뜰 무렵 촬영'),
              onPressed: () {},
            ).withStyle(
              const CoreCardImageStyle(
                frameStyle: CoreOutlinedContainerStyle(
                  backgroundColor: CoreColor.token(
                    CoreColors.tertiaryContainer,
                  ),
                  borderColor: CoreColor.token(CoreColors.tertiary),
                  borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
                ),
              ),
            ),
          ],
          styles: Styles(raw: const {'width': '240px'}),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}''',
  _ =>
    '''
class CardImageDefaultExample extends StatelessComponent {
  const CardImageDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        CardImage(
          image: img(
            src: 'https://picsum.photos/seed/coui/240/160',
            classes: 'block object-cover',
            styles: Styles(
              raw: const {
                'width': '240px',
                'height': '160px',
                'margin': '0',
              },
            ),
          ),
          title: Text('산 풍경'),
          subtitle: Text('해 뜰 무렵 촬영'),
          onPressed: () {},
        ),
      ],
      styles: Styles(raw: const {'width': '240px'}),
    );
  }
}
''',
};
