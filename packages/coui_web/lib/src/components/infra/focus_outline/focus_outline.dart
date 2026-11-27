import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/infra/focus_outline/focus_outline_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// Unified cross-platform focus outline component for CoUI Web.
///
/// Per Epic #1302 chrome / dimensional / animation overrides flow
/// through the single [focusOutlineStyle] slot. Behavioural fields
/// (`child`, `focused`, `shape`) stay flat on the widget.
///
/// ```dart
/// FocusOutline(
///   focused: _focused,
///   focusOutlineStyle: CoreFocusOutlineStyle(
///     borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
///   ),
///   child: triggerDiv,
/// )
/// ```
class FocusOutline extends UiComponent
    implements CoreFocusOutlineContract<Component> {
  /// Creates a [FocusOutline].
  const FocusOutline({
    required this.child,
    this.focused = false,
    this.shape = CoreFocusOutlineShape.rectangle,
    this.focusOutlineStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final Component? child;

  @override
  final bool focused;

  @override
  final CoreFocusOutlineShape shape;

  @override
  final CoreFocusOutlineStyle? focusOutlineStyle;
  @override
  Component build(BuildContext context) {
    final resolved = resolveFocusOutline(
      context,
      focused: focused,
      shape: shape,
      focusOutlineStyle: focusOutlineStyle,
    );

    // The Flutter `FocusOutline` is a `Stack(fit: passthrough)` only
    // because Flutter needs an extra render object to draw the ring
    // outside the child's bounds. On the web, `outline` (and the gap
    // band's `box-shadow`) already paints outside the element's box
    // without affecting layout, so
    // the wrapper can be a plain block `<div>` that keeps the child
    // in normal flow. No `position: absolute`, no extra layer — the
    // ring is drawn on the same wrapper that hosts the child.
    return Component.element(
      tag: tag,
      id: id,
      classes: [
        resolved.root.className,
        ?classes,
      ].join(' ').trim(),
      styles: Styles.combine([
        ?resolved.root.inlineStyles,
        ?css,
      ]),
      attributes: componentAttributes,
      events: events,
      children: [?child],
    );
  }

  @override
  FocusOutline copyWith({
    Component? child,
    bool? focused,
    CoreFocusOutlineShape? shape,
    CoreFocusOutlineStyle? focusOutlineStyle,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
  }) {
    return FocusOutline(
      key: key ?? this.key,
      focused: focused ?? this.focused,
      shape: shape ?? this.shape,
      focusOutlineStyle: focusOutlineStyle ?? this.focusOutlineStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      child: child ?? this.child,
    );
  }
}

/// Chain sugar mirroring the Flutter `FocusOutline.withStyle` extension —
/// merges a [CoreFocusOutlineStyle] patch into
/// [FocusOutline.focusOutlineStyle] via the existing
/// [FocusOutline.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreFocusOutlineStyle.merge` right-side-wins semantics).
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
/// sets [CoreFocusOutlineStyle.borderRadius]. A semantic layer that
/// names these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// FocusOutline(child: triggerDiv).radius4
/// ```
extension FocusOutlineStyleChain on FocusOutline {
  /// Sets the border color.
  FocusOutline borderColor(CoreColor value) =>
      withStyle(CoreFocusOutlineStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  FocusOutline borderWidth(double value) =>
      withStyle(CoreFocusOutlineStyle(borderWidth: value));

  /// Returns a copy of this [FocusOutline] with [patch] merged into
  /// [focusOutlineStyle] (patch fields win on conflict).
  FocusOutline withStyle(CoreFocusOutlineStyle patch) => copyWith(
    focusOutlineStyle: (focusOutlineStyle ?? const CoreFocusOutlineStyle())
        .merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  FocusOutline get radius0 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  FocusOutline get radius2 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  FocusOutline get radius4 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  FocusOutline get radius6 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  FocusOutline get radius8 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  FocusOutline get radius10 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  FocusOutline get radius12 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  FocusOutline get radius14 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  FocusOutline get radius16 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  FocusOutline get radius20 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  FocusOutline get radius24 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  FocusOutline get radius28 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  FocusOutline get radius32 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  FocusOutline get radius36 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  FocusOutline get radius40 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  FocusOutline get radius48 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  FocusOutline get radius56 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  FocusOutline get radius64 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  FocusOutline get radius9999 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );
}
