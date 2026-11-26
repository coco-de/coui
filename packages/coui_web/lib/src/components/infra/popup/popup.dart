import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/infra/popup/popup_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// A unified styled floating-panel container for CoUI Web.
///
/// `Popup` is a chrome-styled surface for floating content such as
/// menus, dropdowns and tooltips. It lays its children out along
/// [direction] inside a bordered, elevated, rounded panel and shows /
/// hides through the [open] flag.
///
/// Per Epic #1302 every chrome / dimensional / nested-slot override
/// flows through the single [popupStyle] (a [CorePopupStyle]).
///
/// ```text
/// design system default for popup
///   → CorePopupTheme.style                  // 프로젝트 공통
///   → component.popupStyle                  // 인스턴스별
/// ```
///
/// Example:
/// ```dart
/// Popup(
///   children: [
///     div([text('Profile')]),
///     div([text('Settings')]),
///   ],
/// )
/// ```
///
/// surface:behind — a floating anchored panel — its host mounts it over page content.
///
/// surface:functional — the anchored panel itself — its host mounts it over
/// page content.
class Popup extends UiComponent implements CorePopupContract<Component> {
  /// Creates a [Popup].
  const Popup({
    required this.children,
    this.open = true,
    this.direction = CoreAxis.vertical,
    this.popupStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: _kDiv);

  @override
  final bool open;

  @override
  final CoreAxis direction;

  @override
  final CorePopupStyle? popupStyle;

  @override
  final List<Component> children;

  // === Internal ===

  static const _kDiv = 'div';
  static const _kRoleAttr = 'role';
  static const _kRoleMenu = 'menu';
  @override
  Component build(BuildContext context) {
    if (!open) return const Component.fragment([]);

    // Resolver finishes className + inlineStyles synthesis (Epic #1601
    // PoC — `WebResolvedChrome` contract). `co_*` reads the paint-
    // ready strings directly without invoking the top-level builder
    // helpers.
    final resolved = resolvePopup(
      context,
      direction: direction,
      popupStyle: popupStyle,
    );

    final userClasses = classes;
    final finalClasses = userClasses == null || userClasses.isEmpty
        ? resolved.root.className
        : '${resolved.root.className} $userClasses';

    return div(
      children,
      id: id,
      classes: finalClasses,
      styles: Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      // Default `role="menu"` first so a caller-supplied role (e.g. a
      // composing `Menu` passing `menubar`, a tooltip passing `tooltip`)
      // wins via the spread — the popup itself has no opinion beyond the
      // sensible default.
      attributes: {
        _kRoleAttr: _kRoleMenu,
        ...componentAttributes,
      },
      events: this.events,
    );
  }

  @override
  Popup copyWith({
    bool? open,
    CoreAxis? direction,
    CorePopupStyle? popupStyle,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    List<Component>? children,
  }) {
    return Popup(
      key: key ?? this.key,
      open: open ?? this.open,
      direction: direction ?? this.direction,
      popupStyle: popupStyle ?? this.popupStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      children: children ?? this.children,
    );
  }
}

/// Chain sugar mirroring the Flutter `Popup.withStyle` extension —
/// merges a [CorePopupStyle] patch into [Popup.popupStyle] via the
/// existing [Popup.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CorePopupStyle.merge` right-side-wins semantics).
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
/// sets [CorePopupStyle.borderRadius] and `.primary` sets
/// [CorePopupStyle.backgroundColor]. A semantic layer that names these
/// after component-specific intent (decided together with design) is
/// a follow-up once more components adopt this pattern.
///
/// ```dart
/// Popup(children: [text('Profile')]).radius4.surface
/// ```
extension PopupStyleChain on Popup {
  /// Returns a copy of this [Popup] with [patch] merged into
  /// [popupStyle] (patch fields win on conflict).
  Popup withStyle(CorePopupStyle patch) => copyWith(
    popupStyle: (popupStyle ?? const CorePopupStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Popup get radius0 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Popup get radius2 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Popup get radius4 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Popup get radius6 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Popup get radius8 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Popup get radius10 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Popup get radius12 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Popup get radius14 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Popup get radius16 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Popup get radius20 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Popup get radius24 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Popup get radius28 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Popup get radius32 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Popup get radius36 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Popup get radius40 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Popup get radius48 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Popup get radius56 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Popup get radius64 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Popup get radius9999 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Popup get primary => withStyle(
    const CorePopupStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Popup get secondary => withStyle(
    const CorePopupStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Popup get tertiary => withStyle(
    const CorePopupStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Popup get surface => withStyle(
    const CorePopupStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Popup get surfaceContainer => withStyle(
    const CorePopupStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Popup get error => withStyle(
    const CorePopupStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Popup get success => withStyle(
    const CorePopupStyle(backgroundColor: CoreColor.token(CoreColors.success)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Popup get warning => withStyle(
    const CorePopupStyle(backgroundColor: CoreColor.token(CoreColors.warning)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Popup get info => withStyle(
    const CorePopupStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Popup get outline => withStyle(
    const CorePopupStyle(backgroundColor: CoreColor.token(CoreColors.outline)),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Popup get transparent =>
      withStyle(const CorePopupStyle(backgroundColor: .transparent));
}
