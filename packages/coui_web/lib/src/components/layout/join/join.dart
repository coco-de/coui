import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/layout/join/join_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

const int _kJoinScopeIdRadix = 36;
int _coJoinIdCounter = 0;

String _newJoinScopeId(Key? key) {
  final keyedId = key?.hashCode.toRadixString(_kJoinScopeIdRadix);
  return 'co-join-${keyedId ?? '${_coJoinIdCounter++}'}';
}

/// Unified cross-platform join component for Web.
///
/// Groups children into a visually connected strip. Each item wrapper
/// carries a position-aware radius + clip, and a scoped `<style>`
/// (composed by [resolveJoinElementCss]) overrides the direct children's own
/// `border-radius` to the same values — the clip alone only crops
/// outside the wrapper, so a child that paints its own rounded corners
/// (e.g. a `Button`) would otherwise leave notches at the seams (the
/// Flutter twin reaches the same result through the ambient
/// `JoinItemData` corner mask).
///
/// Uses [CoreJoinContract] from `coui_core` for consistent
/// cross-platform API. Chrome / dimensional overrides flow through
/// the single [joinStyle] slot per Epic #1302.
///
/// Example:
/// ```dart
/// Join(
///   children: [
///     Button(variant: CoreButtonVariant.outline, child: text('1')),
///     Button(variant: CoreButtonVariant.outline, child: text('2')),
///     Button(variant: CoreButtonVariant.outline, child: text('3')),
///   ],
/// )
/// ```
class Join extends UiComponent implements CoreJoinContract<Component> {
  /// Creates a [Join].
  Join({
    required this.children,
    this.vertical = false,
    this.joinStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : _scopeId = _newJoinScopeId(key),
       super(tag: 'div');

  @override
  final List<Component> children;

  @override
  final bool vertical;

  @override
  final CoreJoinStyle? joinStyle;

  /// Per-instance scope id for the child-radius `<style>` selectors —
  /// the caller-supplied [id] wins when provided.
  final String _scopeId;
  @override
  Component build(BuildContext context) {
    final count = children.length;

    final resolved = resolveJoin(
      context,
      vertical: vertical,
      count: count,
      joinStyle: joinStyle,
    );
    // Preserve the caller id and existing generated DOM fallback. The
    // resolver's Element guard owns CSS independently of that legacy id.
    final scopeId = id ?? _scopeId;
    final childRadiusCss = resolveJoinElementCss(
      context,
      join: resolved,
      scopeId: scopeId,
      vertical: vertical,
      count: count,
      joinStyle: joinStyle,
    );

    final wrapped = <Component>[
      for (var i = 0; i < count; i++)
        div(
          [children[i]],
          classes: resolved.items[i].className,
          styles: resolved.items[i].inlineStyles,
        ),
    ];

    final classString = [
      resolved.root.className,
      ?classes,
    ].where((c) => c.isNotEmpty).join(' ');

    return div(
      [
        // Child `border-radius` cannot be forced from a parent's inline
        // style, so the override rules ship as a scoped `<style>` whose
        // selectors retain the id with an Element ownership guard. The CSS
        // payload is composed by `resolveJoinElementCss` so it stays free of
        // chrome composition.
        Component.element(
          tag: 'style',
          children: [RawText(childRadiusCss)],
        ),
        ...wrapped,
      ],
      id: scopeId,
      classes: classString,
      styles: Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      attributes: componentAttributes,
      events: this.events,
    );
  }

  @override
  Join copyWith({
    List<Component>? children,
    bool? vertical,
    CoreJoinStyle? joinStyle,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
  }) {
    return Join(
      key: key ?? this.key,
      vertical: vertical ?? this.vertical,
      joinStyle: joinStyle ?? this.joinStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      children: children ?? this.children,
    );
  }
}

/// Chain sugar mirroring the Flutter `Join.withStyle` extension —
/// merges a [CoreJoinStyle] patch into [Join.joinStyle] via the
/// existing [Join.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreJoinStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreJoinStyle.borderRadius]. A semantic layer that names these
/// after component-specific intent (decided together with design) is
/// a follow-up once more components adopt this pattern.
///
/// ```dart
/// Join(children: [...]).radius4
/// ```
extension JoinStyleChain on Join {
  /// Returns a copy of this [Join] with [patch] merged into
  /// [joinStyle] (patch fields win on conflict).
  Join withStyle(CoreJoinStyle patch) =>
      copyWith(joinStyle: (joinStyle ?? const CoreJoinStyle()).merge(patch));

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Join get radius0 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.zero,
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Join get radius2 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Join get radius4 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Join get radius6 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Join get radius8 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Join get radius10 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Join get radius12 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Join get radius14 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Join get radius16 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Join get radius20 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Join get radius24 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Join get radius28 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Join get radius32 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Join get radius36 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Join get radius40 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Join get radius48 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Join get radius56 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Join get radius64 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Join get radius9999 => withStyle(
    const CoreJoinStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );
}
