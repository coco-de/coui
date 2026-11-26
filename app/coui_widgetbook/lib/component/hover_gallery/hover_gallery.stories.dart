import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'hover_gallery.stories.g.dart';

const _kItemCountDefault = 4;
const _kImageUrls = [
  'https://picsum.photos/seed/a/400/300',
  'https://picsum.photos/seed/b/400/300',
  'https://picsum.photos/seed/c/400/300',
];

/// Interactive demo host for [HoverGallery] stories.
///
/// Renders either an image-url gallery or a custom item-builder
/// gallery, driven by the knob parameters.
class HoverGalleryDemo extends StatelessWidget {
  /// Creates a [HoverGalleryDemo].
  const HoverGalleryDemo({
    super.key,
    this.useCustomItems = false,
    this.itemCount = _kItemCountDefault,
  });

  /// Whether the gallery uses a custom item builder instead of
  /// image urls.
  final bool useCustomItems;

  /// Item count for the custom item-builder gallery.
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    if (!useCustomItems) {
      return const HoverGallery(imageUrls: _kImageUrls);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
    ];

    return HoverGallery(
      itemBuilder: (index) => ColoredBox(
        color: colors[index % colors.length].toValue(),
        child: Center(
          child: Column(
            mainAxisAlignment: .center,
            mainAxisSize: .min,
            spacing: CoreSpace.space8,
            children: [
              const Icon(
                LucideIcons.image,
                iconStyle: CoreIconStyle(
                  size: CoreSpace.space32,
                  color: CoreColor.token(CoreColors.onPrimary),
                ),
              ),
              Text('Item ${index + 1}').semiBold.onPrimary,
            ],
          ),
        ),
      ),
      itemCount: itemCount,
    );
  }
}

/// Navigation metadata for the HoverGallery component.
const kComponentMeta = ComponentMeta(name: 'HoverGallery', path: 'display');

/// Story metadata for [HoverGalleryDemo].
const kMeta = Meta(HoverGalleryDemo.new);

/// Image-url gallery — hover to cycle through the images.
final $Default = _Story();

/// Gallery items produced by a custom item builder.
final $CustomItemBuilder = _Story(
  name: 'Custom Item Builder',
  args: _Args(useCustomItems: BoolArg(true)),
);
