import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/display/kbd/kbd_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Unified cross-platform keyboard key component for CoUI Web.
///
/// Renders a `<span>`-based key sequence: each key is a filled rounded box
/// (outlined only where its border colour is visible) rendered as an
/// inline-flex `<span>`, the boxes sit `keySeparatorSpacing`
/// apart on the row's `gap`, and nothing is drawn between them. A shortcut
/// written inside a sentence is text such as "Ctrl+S", not a [Kbd].
///
/// One [Kbd] is one combination and is announced as **one** name — the root
/// is `role="img"` with an `aria-label` of the keys joined by a space
/// ("Ctrl S"), so its key boxes are not read one fragment at a time. An icon
/// key is announced only when it is named through [label].
///
/// Per Epic #1302 every chrome / dimensional / text-style override
/// flows through the single [kbdStyle] (a [CoreKbdStyle]). The
/// behavioural field ([keys]) stays flat on the component.
///
/// Example:
/// ```dart
/// Kbd(keys: ['Ctrl', 'C'])
/// Kbd.single(keyText: '⌘')
/// Kbd.icon(keyContent: Icon(LucideIcons.cornerDownLeft), label: 'Enter')
/// ```
///
/// surface:behind — whatever a key sits inline against. Each key cap's
/// root is a fixed `<span>` — wrapping it in `OutlinedContainer`'s
/// `<div>` would break the inline flow a key is meant to sit in
/// (#4358) — so the marker is restated on the key cap directly.
///
/// surface:content — a label-sized chip in the content layer, not a
/// floating affordance: no sticky, fixed, or overlay mount.
class Kbd extends UiComponent implements CoreKbdContract<Component> {
  /// Creates a [Kbd].
  const Kbd({
    required this.keys,
    super.key,
    this.kbdStyle,
    super.attributes,
    super.classes,
    super.css,
    super.id,
  }) : keyContent = null,
       label = null,
       super(tag: _kSpan);

  /// Creates a [Kbd] with a single key.
  Kbd.single({
    required String keyText,
    super.key,
    this.kbdStyle,
    super.attributes,
    super.classes,
    super.css,
    super.id,
  }) : keys = [keyText],
       keyContent = null,
       label = null,
       super(tag: _kSpan);

  /// Creates a [Kbd] with a single widget key (canonically an `Icon`
  /// glyph — identical on both platforms where a symbol text glyph
  /// would fall to per-platform font fallback).
  ///
  /// [label] is the key's accessible name; without it the glyph is silent.
  const Kbd.icon({
    required Component this.keyContent,
    super.key,
    this.label,
    this.kbdStyle,
    super.attributes,
    super.classes,
    super.css,
    super.id,
  }) : keys = const [],
       super(tag: _kSpan);

  @override
  final List<String> keys;

  @override
  final Component? keyContent;

  @override
  final String? label;

  /// Per-instance composite style. See [CoreKbdStyle] for the merge
  /// chain.
  @override
  final CoreKbdStyle? kbdStyle;

  // === Internal ===

  static const _kSpan = 'span';

  /// The one name this combination is announced by — the keys joined by a
  /// space, or the icon key's [label]. `null` when there is nothing to say,
  /// which leaves the root without a role rather than an unnamed `img`.
  String? get _accessibleName {
    final name = keyContent != null ? label : keys.join(' ');
    return name == null || name.isEmpty ? null : name;
  }

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    final name = _accessibleName;
    if (name == null) return;
    // `role="img"` makes the key boxes presentational, so a reader gets
    // "Ctrl S" rather than "Ctrl", "S" — and an `aria-label` on a bare
    // `<span>` (no role) would be ignored.
    attributes
      ..addRole('img')
      ..addAria('label', name);
  }

  @override
  Kbd copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    List<String>? keys,
    CoreKbdStyle? kbdStyle,
  }) {
    final content = keyContent;
    if (content != null) {
      return Kbd.icon(
        key: key ?? this.key,
        keyContent: content,
        label: label,
        kbdStyle: kbdStyle ?? this.kbdStyle,
        attributes: attributes ?? userAttributes,
        classes: mergeClasses(classes, this.classes),
        css: css ?? this.css,
        id: id ?? this.id,
      );
    }
    return Kbd(
      key: key ?? this.key,
      keys: keys ?? this.keys,
      kbdStyle: kbdStyle ?? this.kbdStyle,
      attributes: attributes ?? userAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
    );
  }

  @override
  Component build(BuildContext context) {
    // Resolver finishes className + inlineStyles synthesis (Epic #1601
    // PoC — `WebResolvedChrome` contract). `co_*` reads the paint-
    // ready strings directly without invoking the top-level builder
    // helpers.
    final resolved = resolveKbd(context, kbdStyle: kbdStyle);

    final userClasses = classes;
    final finalClasses = userClasses == null || userClasses.isEmpty
        ? resolved.root.className
        : '${resolved.root.className} $userClasses';

    return Component.element(
      tag: _kSpan,
      id: id,
      classes: finalClasses,
      styles: Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      attributes: componentAttributes,
      events: this.events,
      children: _buildChildren(resolved: resolved),
    );
  }

  List<Component> _buildChildren({required ResolvedKbd resolved}) {
    final content = keyContent;
    if (content != null) {
      return [
        span(
          [content],
          classes: resolved.keyCap.className,
          styles: resolved.keyCap.inlineStyles,
        ),
      ];
    }
    return [
      for (final keyText in keys)
        span(
          [Component.text(keyText)],
          classes: resolved.keyCap.className,
          styles: resolved.keyCap.inlineStyles,
        ),
    ];
  }
}

/// Chain sugar mirroring the Flutter `Kbd.withStyle` extension —
/// merges a [CoreKbdStyle] patch into [Kbd.kbdStyle] via the existing
/// [Kbd.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreKbdStyle.merge` right-side-wins semantics).
extension KbdStyleChain on Kbd {
  /// Returns a copy of this [Kbd] with [patch] merged into [kbdStyle]
  /// (patch fields win on conflict).
  Kbd withStyle(CoreKbdStyle patch) =>
      copyWith(kbdStyle: (kbdStyle ?? const CoreKbdStyle()).merge(patch));
}
