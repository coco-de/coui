import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/display/tag/tag_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// Unified cross-platform tag for CoUI Web — a short label that files
/// something under a category, coloured by one of the category hues.
///
/// Display only: no press, no hover or press state, never focusable. A
/// label a person acts on is a `Chip`; a status is a `Badge`.
///
/// Every chrome / dimensional / nested-slot override flows through the
/// single [tagStyle] (a [CoreTagStyle]). The design axes (`color` /
/// `emphasis` / `size`) and the label (`child`) stay flat on the
/// component.
///
/// ```text
/// design system default for size × emphasis × hue
///   → CoreTagTheme.style                    // 프로젝트 공통
///   → CoreTagTheme.colorStyles[color]
///   → CoreTagTheme.emphasisStyles[emphasis]
///   → component.tagStyle                    // 인스턴스별
/// ```
///
/// Example:
/// ```dart
/// Tag(color: CoreCategoryColor.blue, child: Text('Design'))
/// ```
///
/// surface:behind — whatever the tag is set inline against. Its root is
/// an inline `<span>` — wrapping it in `OutlinedContainer`'s `<div>` would
/// break the inline flow a tag sits in — so the marker is restated on this
/// element directly, as `Badge` does.
///
/// surface:content — a label-sized part in the content layer, not a
/// floating affordance: no sticky, fixed, or overlay mount.
class Tag extends UiComponent implements CoreTagContract<Component> {
  /// Creates a [Tag].
  ///
  /// `attributes` / `eventHandlers` reach the root `<span>`, so a caller
  /// can hang a `data-*` hook or a test id on it.
  const Tag({
    required this.child,
    super.key,
    this.color = CoreTagContract.defaultColor,
    this.emphasis = CoreTagEmphasis.defaultEmphasis,
    this.size = CoreTagSize.defaultSize,
    this.tagStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'span');

  @override
  final CoreCategoryColor color;

  @override
  final CoreTagEmphasis emphasis;

  @override
  final CoreTagSize size;

  @override
  final Component child;

  /// Per-instance composite style. See [CoreTagStyle] for the merge chain.
  @override
  final CoreTagStyle? tagStyle;

  @override
  Tag copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    CoreCategoryColor? color,
    CoreTagEmphasis? emphasis,
    CoreTagSize? size,
    CoreTagStyle? tagStyle,
    Component? child,
  }) {
    return Tag(
      key: key ?? this.key,
      color: color ?? this.color,
      emphasis: emphasis ?? this.emphasis,
      size: size ?? this.size,
      tagStyle: tagStyle ?? this.tagStyle,
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers,
      child: child ?? this.child,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveTag(
      context,
      color: color,
      emphasis: emphasis,
      size: size,
      tagStyle: tagStyle,
    );

    return Component.element(
      tag: 'span',
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: Styles.combine([?resolved.root.inlineStyles, ?css]),
      attributes: componentAttributes,
      events: events.isEmpty ? null : events,
      children: [child],
    );
  }
}

/// Chain sugar mirroring the Flutter `Tag.withStyle` extension — merges a
/// [CoreTagStyle] patch into [Tag.tagStyle] without hand-reconstructing
/// every field. The label keeps using the `Text(...)` chain directly.
extension TagStyleChain on Tag {
  /// Returns a copy of this [Tag] with [patch] merged into [tagStyle]
  /// (patch fields win on conflict).
  Tag withStyle(CoreTagStyle patch) =>
      copyWith(tagStyle: (tagStyle ?? const CoreTagStyle()).merge(patch));
}
