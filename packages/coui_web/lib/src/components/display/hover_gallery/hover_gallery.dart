import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/display/hover_gallery/hover_gallery_style.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// Counter for generating unique scoped IDs.
int _idCounter = 0;

/// Unified cross-platform hover gallery for CoUI Web.
///
/// Per Epic #1302 chrome / dimensional / animation overrides flow
/// through the single [hoverGalleryStyle] slot.
///
/// Two modes:
/// - [imageUrls]: pass URL strings, images rendered internally with fit.
/// - [itemBuilder] + [itemCount]: custom component per index.
///
/// Example:
/// ```dart
/// HoverGallery(imageUrls: [
///   'https://example.com/image1.jpg',
///   'https://example.com/image2.jpg',
/// ])
/// ```
class HoverGallery extends UiStatefulComponent
    implements CoreHoverGalleryContract {
  /// Creates a [HoverGallery].
  const HoverGallery({
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
    this.imageUrls,
    this.itemBuilder,
    this.itemCount,
    this.fit,
    this.hoverGalleryStyle,
  });

  @override
  final List<String>? imageUrls;

  /// Builder for custom components per index.
  final Component Function(int index)? itemBuilder;

  @override
  final int? itemCount;

  /// CSS object-fit value (e.g. 'cover', 'contain'). Default 'cover'.
  final String? fit;

  @override
  final CoreHoverGalleryStyle? hoverGalleryStyle;

  /// Returns a copy of this [HoverGallery] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  HoverGallery copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    List<String>? imageUrls,
    Component Function(int index)? itemBuilder,
    int? itemCount,
    String? fit,
    CoreHoverGalleryStyle? hoverGalleryStyle,
  }) {
    return HoverGallery(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      attributes: attributes ?? this.userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      onChange: onChange ?? this.onChange,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
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

/// Chain sugar mirroring the Flutter `HoverGallery.withStyle` extension —
/// merges a [CoreHoverGalleryStyle] patch into
/// [HoverGallery.hoverGalleryStyle] via the existing
/// [HoverGallery.copyWith].
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

class _HoverGalleryState extends State<HoverGallery> {
  int _activeIndex = 0;
  late final String _scopeId;

  @override
  void initState() {
    super.initState();
    _scopeId = 'co-hg-${_idCounter++}';
  }

  int get _count => component.imageUrls?.length ?? component.itemCount ?? 0;

  int _calcIndex(web.MouseEvent event) {
    if (event.currentTarget case final web.HTMLElement target) {
      final width = target.clientWidth.toDouble();
      if (width <= 0) return _activeIndex;
      final offsetX = event.offsetX.toDouble();
      final segmentWidth = width / _count;
      return (offsetX / segmentWidth).floor().clamp(0, _count - 1);
    }
    return _activeIndex;
  }

  void _handleMouseEvent(web.MouseEvent event) {
    if (_count == 0) return;
    final index = _calcIndex(event);
    if (index != _activeIndex) {
      setState(() {
        _activeIndex = index;
      });
    }
  }

  void _handleClickEvent(web.MouseEvent event) {
    if (_count == 0) return;
    final index = _calcIndex(event);
    setState(() {
      _activeIndex = index;
    });
  }

  Component _buildItem(int index, ResolvedHoverGallery resolved) {
    if (component.imageUrls != null) {
      return img(
        alt: CouiLocalizations.of(context).galleryImageLabel(index + 1),
        src: component.imageUrls![index],
        classes: 'not-content ${resolved.image.className}',
        styles: resolved.image.inlineStyles,
      );
    }
    return component.itemBuilder!(index);
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveHoverGallery(
      context,
      hoverGalleryStyle: component.hoverGalleryStyle,
      fit: component.fit,
    );

    if (_count == 0) {
      return div(
        [],
        id: component.id,
        classes: component.rootClasses(resolved.root.className),
        styles: component.css != null
            ? Styles.combine([?resolved.root.inlineStyles, component.css!])
            : resolved.root.inlineStyles,
        attributes: component.componentAttributes,
        events: component.events,
      );
    }

    final layers = <Component>[];
    for (var i = 0; i < _count; i++) {
      final layerChrome = i == _activeIndex
          ? resolved.layerActive
          : resolved.layerIdle;
      layers.add(
        div(
          [_buildItem(i, resolved)],
          key: ValueKey('hg-layer-$i'),
          classes: layerChrome.className,
          styles: layerChrome.inlineStyles,
        ),
      );
    }

    return div(
      layers,
      id: component.id ?? _scopeId,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: {
        ...component.events,
        'mousemove': EventHandlers.createMouseEventHandler(_handleMouseEvent),
        'click': EventHandlers.createMouseEventHandler(_handleClickEvent),
      },
    );
  }
}
