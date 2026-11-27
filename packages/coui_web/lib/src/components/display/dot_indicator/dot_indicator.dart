import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/display/dot_indicator/dot_indicator_style.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:universal_web/web.dart' as web;
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Radix for the generated scope id (base-36 keeps it short). Not a
/// design token.
const int _kScopeIdRadix = 36;

/// Unified cross-platform dot indicator for CoUI Web
/// with token-based rendering.
///
/// Per Epic #1302 chrome / dimensional overrides flow through the
/// single [dotIndicatorStyle] slot. Behavioural fields (`index`,
/// `length`, `onChanged`, `direction`) and the semantic [size]
/// identifier stay flat on the component.
class DotIndicator extends UiComponent
    implements CoreDotIndicatorContract<Component> {
  /// Creates a [DotIndicator].
  DotIndicator({
    required this.index,
    required this.length,
    this.onChanged,
    this.direction = CoreAxis.horizontal,
    this.size = CoreDotIndicatorSize.defaultSize,
    this.dotIndicatorStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final int index;

  @override
  final int length;

  @override
  final CoreDotIndicatorOnChanged? onChanged;

  @override
  final CoreAxis direction;

  @override
  final CoreDotIndicatorSize size;

  @override
  final CoreDotIndicatorStyle? dotIndicatorStyle;

  @override
  DotIndicator copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    int? index,
    int? length,
    CoreDotIndicatorOnChanged? onChanged,
    CoreAxis? direction,
    CoreDotIndicatorSize? size,
    CoreDotIndicatorStyle? dotIndicatorStyle,
  }) {
    return DotIndicator(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      index: index ?? this.index,
      length: length ?? this.length,
      direction: direction ?? this.direction,
      size: size ?? this.size,
      dotIndicatorStyle: dotIndicatorStyle ?? this.dotIndicatorStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }

  @override
  Component build(BuildContext context) {
    final isClickable = onChanged != null && length > 0;
    // Scope id for the per-instance pseudo-state scoped rules — used to
    // build unique `.co-dot-*` class names shared by the dots and the
    // `<style>` rules (the caller's id wins, else a generated one).
    final scopeId =
        id ??
        'co-dot-${key?.hashCode.toRadixString(_kScopeIdRadix) ?? identityHashCode(this).toRadixString(_kScopeIdRadix)}';
    final resolved = resolveDotIndicator(
      context,
      direction: direction,
      size: size,
      length: length,
      activeIndex: index,
      isClickable: isClickable,
      scopeId: scopeId,
      dotIndicatorStyle: dotIndicatorStyle,
    );
    final rules = resolveDotIndicatorRules(
      context,
      scopeId: scopeId,
      isClickable: isClickable,
      dotIndicatorStyle: dotIndicatorStyle,
    );

    final containerInline = resolved.root.inlineStyles;

    // Each dot is wrapped in `Clickable` — the unified cross-platform
    // clickable primitive (cursor / pointer activation) — mirroring the
    // Flutter widget. Roving radio-group model: the GROUP is the single
    // tab stop (root `tabindex=0` below) and arrow keys move the
    // selection, so every dot pins `tabindex=-1` and `role=tab`
    // (overriding Clickable's generic button role); the focus ring is
    // the selected dot's `group-focus-visible:` classes. `onPressed` is
    // `null` when the indicator is non-interactive.
    final dots = <Component>[
      for (int i = 0; i < length; i++)
        Clickable(
          onPressed: isClickable ? () => onChanged!(i) : null,
          semanticsButton: false,
          attributes: {
            if (!isClickable) 'aria-hidden': 'true',
            if (isClickable) 'role': 'tab',
            'tabindex': '-1',
            if (isClickable)
              'aria-label': CouiLocalizations.of(
                context,
              ).dotIndicatorGoToItem(i + 1),
            if (isClickable && i == index) 'aria-current': 'true',
          },
          // The pointer-target marker (WCAG 2.5.8) rides the dot itself,
          // not this wrapper — `buildDotClassName` emits it. The overlay
          // it turns on accepts the pointer, so on the wrapper it sat
          // over the dot and the dot never matched `:hover`.
          // The visible ring is the selected dot's `group-focus-visible:`
          // classes (scoped to the root's keyboard focus) — Clickable's
          // own hit-box-shaped ring must stay off or an arrow key after
          // a pointer click flips `:focus-visible` on the dot and shows
          // the rectangular hit-box ring instead.
          focusOutline: false,
          child: Component.element(
            tag: 'div',
            classes: resolved.dots[i].root.className,
            styles: resolved.dots[i].root.inlineStyles,
          ),
        ),
    ];

    return Component.element(
      tag: 'div',
      id: id,
      classes: mergeClasses(resolved.root.className, this.classes),
      styles: containerInline != null
          ? Styles.combine([containerInline, ?this.css])
          : this.css,
      attributes: {
        ...componentAttributes,
        'role': isClickable ? 'tablist' : 'group',
        if (length == 0) 'aria-hidden': 'true',
        if (length > 0)
          'aria-label': isClickable
              ? CouiLocalizations.of(context).dotIndicatorLabel
              : CouiLocalizations.of(
                  context,
                ).dotIndicatorPosition(index + 1, length),
        if (isClickable) 'tabindex': '0',
      },
      events: {
        ...this.events,
        if (isClickable) ...{
          'keydown': EventHandlers.createKeyboardEventHandler(
            (event) => handleKeyDown(event, onChanged!),
          ),
          // Keep the keyboard focus on the group root (single tab
          // stop). A pointer click focuses the dot (`tabindex=-1`
          // elements accept click focus), which would strand the
          // selection ring: the root never reaches `:focus-visible`,
          // so arrow keys move the selection but not the ring.
          // Redirecting the focus to the root keeps the browser's
          // focus-visible heuristic intact — click-sourced focus shows
          // no ring, keyboard-sourced focus does.
          'focusin': EventHandlers.createEventHandler(handleFocusIn),
        },
      },
      children: [
        // `<style>` is `display: none`, so it never affects the flex
        // row/column layout.
        if (rules.css.isNotEmpty)
          Component.element(tag: 'style', children: [RawText(rules.css)]),
        ...dots,
      ],
    );
  }

  /// Redirects focus landing on a child dot back to the group root.
  void handleFocusIn(web.Event event) {
    if (event.target == event.currentTarget) return;
    if (event.currentTarget case final web.HTMLElement root) {
      root.focus();
    }
  }

  /// Moves the selection with the arrow keys along the layout axis
  /// (roving radio-group model — mirrors the Flutter twin's
  /// `FocusableActionDetector` shortcuts).
  void handleKeyDown(web.KeyboardEvent event, CoreDotIndicatorOnChanged cb) {
    final horizontal = direction == .horizontal;
    final prevKey = horizontal ? 'ArrowLeft' : 'ArrowUp';
    final nextKey = horizontal ? 'ArrowRight' : 'ArrowDown';
    final int delta;
    if (event.key == nextKey) {
      delta = 1;
    } else if (event.key == prevKey) {
      delta = -1;
    } else {
      return;
    }
    event.preventDefault();
    final next = (index + delta).clamp(0, length - 1);
    if (next != index) cb(next);
  }
}

/// Chain sugar mirroring the Flutter `DotIndicator.withStyle` extension —
/// merges a [CoreDotIndicatorStyle] patch into
/// [DotIndicator.dotIndicatorStyle] via the existing
/// [DotIndicator.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDotIndicatorStyle.merge` right-side-wins semantics).
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
/// sets [CoreDotIndicatorStyle.borderRadius]. A semantic layer that
/// names these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// DotIndicator(index: 0, length: 3).radius4
/// ```
extension DotIndicatorStyleChain on DotIndicator {
  /// Sets the content padding.
  DotIndicator contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreDotIndicatorStyle(padding: value));

  /// Returns a copy of this [DotIndicator] with [patch] merged into
  /// [dotIndicatorStyle] (patch fields win on conflict).
  DotIndicator withStyle(CoreDotIndicatorStyle patch) => copyWith(
    dotIndicatorStyle: (dotIndicatorStyle ?? const CoreDotIndicatorStyle())
        .merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  DotIndicator get radius0 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  DotIndicator get radius2 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  DotIndicator get radius4 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  DotIndicator get radius6 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  DotIndicator get radius8 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  DotIndicator get radius10 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  DotIndicator get radius12 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  DotIndicator get radius14 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  DotIndicator get radius16 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  DotIndicator get radius20 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  DotIndicator get radius24 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  DotIndicator get radius28 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  DotIndicator get radius32 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  DotIndicator get radius36 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  DotIndicator get radius40 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  DotIndicator get radius48 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  DotIndicator get radius56 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  DotIndicator get radius64 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  DotIndicator get radius9999 => withStyle(
    const CoreDotIndicatorStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );
}
