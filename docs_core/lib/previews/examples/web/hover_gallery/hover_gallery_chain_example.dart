import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreHoverGalleryStyle] slot without constructing the
/// widget from scratch — chained with the primitive-token `.radius16`
/// getter (a direct 1:1 alias for `CoreRadius.radius16`), which is
/// shorter than a second `.withStyle(const CoreHoverGalleryStyle(
/// borderRadius: CoreBorderRadius.all(CoreRadius.radius16)))` call.
///
/// Patch fields win on conflict, so the trailing getter decides
/// `borderRadius` — the `radius24` supplied to `withStyle` here is the
/// value `.radius16` overrides.
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
}
