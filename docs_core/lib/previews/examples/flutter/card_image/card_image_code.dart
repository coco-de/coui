/// Source snippet for the Flutter `CardImage` previews.
///
/// Each case must mirror its matching `card_image_*_example.dart` file
/// verbatim (minus imports) so the docs site's "View code" tab stays in
/// sync.
String cardImageCode(String? variant) => switch (variant) {
  'chain' =>
    '''
class CardImageChainExample extends StatelessWidget {
  const CardImageChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        SizedBox(
          width: 240,
          child: CardImage(
            image: Image.network(
              'https://picsum.photos/seed/coui/240/160',
              width: 240,
              height: 160,
              fit: BoxFit.cover,
            ),
            title: const Text('산 풍경'),
            subtitle: const Text('해 뜰 무렵 촬영'),
            onPressed: () {},
          ).radius16.primary,
        ),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(frameStyle.borderColor)
        // 까지 한 번에.
        SizedBox(
          width: 240,
          child:
              CardImage(
                image: Image.network(
                  'https://picsum.photos/seed/coui/240/160',
                  width: 240,
                  height: 160,
                  fit: BoxFit.cover,
                ),
                title: const Text('산 풍경'),
                subtitle: const Text('해 뜰 무렵 촬영'),
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
        ),
      ],
    );
  }
}''',
  _ =>
    '''
class CardImageDefaultExample extends StatelessWidget {
  const CardImageDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: CardImage(
        image: Image.network(
          'https://picsum.photos/seed/coui/240/160',
          width: 240,
          height: 160,
          fit: BoxFit.cover,
        ),
        title: const Text('산 풍경'),
        subtitle: const Text('해 뜰 무렵 촬영'),
        onPressed: () {},
      ),
    );
  }
}
''',
};
