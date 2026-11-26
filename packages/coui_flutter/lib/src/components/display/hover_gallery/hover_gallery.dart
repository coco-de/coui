import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform hover gallery with token-based rendering.
///
/// Displays a container of images where the visible image
/// changes based on horizontal hover/tap position.
///
/// Two modes:
/// - [imageUrls]: pass URL strings, images rendered internally with [fit].
/// - [itemBuilder] + [itemCount]: custom widget per index.
///
/// Per Epic #1302 chrome / dimensional / animation overrides flow
/// through the single [hoverGalleryStyle] slot. Content / behaviour
/// fields (`imageUrls`, `itemCount`, `itemBuilder`, `fit`) stay flat
/// on the widget.
///
/// Example:
/// ```dart
/// HoverGallery(imageUrls: [
///   'https://example.com/image1.jpg',
///   'https://example.com/image2.jpg',
/// ])
/// ```
class HoverGallery extends StatefulWidget implements CoreHoverGalleryContract {
  /// Creates a [HoverGallery] from image URLs.
  const HoverGallery({
    super.key,
    this.imageUrls,
    this.itemBuilder,
    this.itemCount,
    this.fit = BoxFit.cover,
    this.hoverGalleryStyle,
  }) : assert(
         imageUrls != null || (itemBuilder != null && itemCount != null),
         'Provide imageUrls or itemBuilder + itemCount',
       );

  @override
  final List<String>? imageUrls;

  /// Builder for custom widgets per index.
  final Widget Function(int index)? itemBuilder;

  @override
  final int? itemCount;

  /// How images should be fitted (only for [imageUrls] mode).
  final BoxFit fit;

  @override
  final CoreHoverGalleryStyle? hoverGalleryStyle;

  /// Returns a copy of this [HoverGallery] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  HoverGallery copyWith({
    Key? key,
    List<String>? imageUrls,
    Widget Function(int index)? itemBuilder,
    int? itemCount,
    BoxFit? fit,
    CoreHoverGalleryStyle? hoverGalleryStyle,
  }) {
    return HoverGallery(
      key: key ?? this.key,
      imageUrls: imageUrls ?? this.imageUrls,
      itemBuilder: itemBuilder ?? this.itemBuilder,
      itemCount: itemCount ?? this.itemCount,
      fit: fit ?? this.fit,
      hoverGalleryStyle: hoverGalleryStyle ?? this.hoverGalleryStyle,
    );
  }

  @override
  State<HoverGallery> createState() => _HoverGalleryState();
}

class _HoverGalleryState extends State<HoverGallery> {
  int _activeIndex = 0;

  int get _count => widget.imageUrls?.length ?? widget.itemCount ?? 0;

  Widget _buildItem(int index) {
    if (widget.imageUrls != null) {
      return Image.network(
        widget.imageUrls![index],
        semanticLabel: CoUILocalizations.of(
          context,
        ).galleryImageLabel(index + 1),
        fit: widget.fit,
      );
    }
    return widget.itemBuilder!(index);
  }

  void _handleHover(PointerEvent event, double width) {
    if (_count == 0) return;
    final segmentWidth = width / _count;
    final index = (event.localPosition.dx / segmentWidth).floor().clamp(
      0,
      _count - 1,
    );
    if (index != _activeIndex) {
      setState(() {
        _activeIndex = index;
      });
    }
  }

  void _handleTap(TapUpDetails details, double width) {
    if (_count == 0) return;
    final segmentWidth = width / _count;
    final index = (details.localPosition.dx / segmentWidth).floor().clamp(
      0,
      _count - 1,
    );
    setState(() {
      _activeIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveHoverGallery(
      context,
      hoverGalleryStyle: widget.hoverGalleryStyle,
    );

    if (_count == 0) {
      return SizedBox(height: resolved.height);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onHover: (event) => _handleHover(event, constraints.maxWidth),
          child: GestureDetector(
            onTapUp: (details) => _handleTap(details, constraints.maxWidth),
            child: Container(
              decoration: BoxDecoration(borderRadius: resolved.borderRadius),
              height: resolved.height,
              clipBehavior: .antiAlias,
              child: AnimatedSwitcher(
                duration: resolved.animationDuration,
                child: KeyedSubtree(
                  key: ValueKey<int>(_activeIndex),
                  child: SizedBox.expand(
                    child: _buildItem(_activeIndex),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Chain sugar for merging a [CoreHoverGalleryStyle] patch into
/// [HoverGallery.hoverGalleryStyle] without hand-reconstructing every
/// field. Mirrors the Web `HoverGallery.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreHoverGalleryStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` primitive — the
/// getter *name* is the token name, so `.radius4` always means
/// `CoreRadius.radius4`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreHoverGalleryStyle.borderRadius]. A semantic layer that
/// names these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// HoverGallery(imageUrls: urls).radius4
/// ```
extension HoverGalleryStyleChain on HoverGallery {
  /// Returns a copy of this [HoverGallery] with [patch] merged into
  /// [hoverGalleryStyle] (patch fields win on conflict).
  HoverGallery withStyle(CoreHoverGalleryStyle patch) => copyWith(
    hoverGalleryStyle: (hoverGalleryStyle ?? const CoreHoverGalleryStyle())
        .merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  HoverGallery get radius0 => withStyle(
    const CoreHoverGalleryStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  HoverGallery get radius2 => withStyle(
    const CoreHoverGalleryStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  HoverGallery get radius4 => withStyle(
    const CoreHoverGalleryStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  HoverGallery get radius6 => withStyle(
    const CoreHoverGalleryStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  HoverGallery get radius8 => withStyle(
    const CoreHoverGalleryStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  HoverGallery get radius10 => withStyle(
    const CoreHoverGalleryStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  HoverGallery get radius12 => withStyle(
    const CoreHoverGalleryStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  HoverGallery get radius14 => withStyle(
    const CoreHoverGalleryStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  HoverGallery get radius16 => withStyle(
    const CoreHoverGalleryStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  HoverGallery get radius20 => withStyle(
    const CoreHoverGalleryStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  HoverGallery get radius24 => withStyle(
    const CoreHoverGalleryStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  HoverGallery get radius28 => withStyle(
    const CoreHoverGalleryStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  HoverGallery get radius32 => withStyle(
    const CoreHoverGalleryStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  HoverGallery get radius36 => withStyle(
    const CoreHoverGalleryStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  HoverGallery get radius40 => withStyle(
    const CoreHoverGalleryStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  HoverGallery get radius48 => withStyle(
    const CoreHoverGalleryStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  HoverGallery get radius56 => withStyle(
    const CoreHoverGalleryStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  HoverGallery get radius64 => withStyle(
    const CoreHoverGalleryStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  HoverGallery get radius9999 => withStyle(
    const CoreHoverGalleryStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );
}
