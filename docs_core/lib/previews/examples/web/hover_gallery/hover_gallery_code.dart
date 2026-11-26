/// Returns a Web code snippet string for the HoverGallery component.
String hoverGalleryCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class HoverGalleryChainExample extends StatefulComponent {
  const HoverGalleryChainExample({super.key});

  @override
  State<HoverGalleryChainExample> createState() => _HoverGalleryChainExampleState();
}

class _HoverGalleryChainExampleState extends State<HoverGalleryChainExample> {
  @override
  Component build(BuildContext context) {
    return HoverGallery(
          imageUrls: [
            'https://picsum.photos/seed/a/400/300',
            'https://picsum.photos/seed/b/400/300',
            'https://picsum.photos/seed/c/400/300',
          ],
        )
        .withStyle(
          const CoreHoverGalleryStyle(
            height: CoreSpace.space256,
            animationDuration: Duration(milliseconds: CoreDuration.fast),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
          ),
        )
        .radius16;
  }
}''',
    _ =>
      '''
class HoverGalleryDefaultExample extends StatefulComponent {
  const HoverGalleryDefaultExample({super.key});

  @override
  State<HoverGalleryDefaultExample> createState() =>
      _HoverGalleryDefaultExampleState();
}

class _HoverGalleryDefaultExampleState
    extends State<HoverGalleryDefaultExample> {
  @override
  Component build(BuildContext context) {
    return HoverGallery(
      imageUrls: [
        'https://picsum.photos/seed/a/400/300',
        'https://picsum.photos/seed/b/400/300',
        'https://picsum.photos/seed/c/400/300',
      ],
    );
  }
}''',
  };
}
