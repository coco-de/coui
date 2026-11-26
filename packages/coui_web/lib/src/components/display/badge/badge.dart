import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/display/badge/badge_style.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/theme/icon_theme.dart';
import 'package:coui_web/src/util/element_scope.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// Unified cross-platform badge for CoUI Web with token-based rendering.
///
/// Every chrome / dimensional / nested-slot override flows through the
/// single [badgeStyle] (a [CoreBadgeStyle]). The design axes (`tone` /
/// `variant` / `form` / `size` / `showDot`) and behaviour fields (`child` /
/// `leading` / `trailing` / `onPressed`) stay flat on the component.
///
/// ```text
/// design system default for size × form × tone × variant
///   → CoreBadgeTheme.style                  // 프로젝트 공통
///   → CoreBadgeTheme.toneStyles[tone]
///   → CoreBadgeTheme.variantStyles[variant]
///   → component.badgeStyle                  // 인스턴스별
/// ```
///
/// Example:
/// ```dart
/// // A status label — tonal, a word, md.
/// Badge(tone: CoreBadgeTone.success, showDot: true, child: Text('Done'))
///
/// // An unread count.
/// Badge(
///   tone: CoreBadgeTone.info,
///   variant: CoreBadgeVariant.filled,
///   form: CoreBadgeForm.count,
///   size: CoreComponentSize.xs,
///   child: Text('3'),
/// )
/// ```
///
/// surface:behind — whatever the badge is set inline against. Its root
/// is a fixed `<span>` — wrapping it in `OutlinedContainer`'s `<div>`
/// would break the inline flow a badge is meant to sit in — so the
/// marker is restated on this element directly, the same restatement
/// `Button` does for the same "can't compose" reason.
///
/// surface:content — a label-sized chip in the content layer, not a
/// floating affordance: no sticky, fixed, or overlay mount.
class Badge extends UiComponent implements CoreBadgeContract<Component> {
  /// Creates a [Badge].
  ///
  /// `attributes` / `eventHandlers` reach the root `<span>`, so a caller
  /// can give a decorative badge an `aria-label`, hang a `data-*` hook on
  /// it, or set a test id. A caller's `click` / key handlers run before the
  /// badge's own press handling, not instead of it.
  const Badge({
    this.tone = CoreBadgeTone.defaultTone,
    this.variant = CoreBadgeVariant.defaultVariant,
    this.child,
    super.key,
    this.form = CoreBadgeForm.defaultForm,
    this.size = CoreBadgeContract.defaultSize,
    this.showDot = CoreBadgeContract.defaultShowDot,
    this.leading,
    this.trailing,
    this.onPressed,
    this.badgeStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'span');

  @override
  final CoreBadgeTone tone;

  @override
  final CoreBadgeVariant variant;

  @override
  final Component? child;

  @override
  final CoreBadgeForm form;

  @override
  final CoreComponentSize size;

  @override
  final bool showDot;

  @override
  final Component? leading;

  @override
  final Component? trailing;

  @override
  final CoreVoidCallback? onPressed;

  /// Per-instance composite style. See [CoreBadgeStyle] for the
  /// merge chain.
  @override
  final CoreBadgeStyle? badgeStyle;

  @override
  Badge copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    CoreBadgeTone? tone,
    CoreBadgeVariant? variant,
    Component? child,
    CoreBadgeForm? form,
    CoreComponentSize? size,
    bool? showDot,
    Component? leading,
    Component? trailing,
    CoreVoidCallback? onPressed,
    CoreBadgeStyle? badgeStyle,
  }) {
    return Badge(
      tone: tone ?? this.tone,
      variant: variant ?? this.variant,
      key: key ?? this.key,
      form: form ?? this.form,
      size: size ?? this.size,
      showDot: showDot ?? this.showDot,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      onPressed: onPressed ?? this.onPressed,
      badgeStyle: badgeStyle ?? this.badgeStyle,
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
    final isInteractive = onPressed != null;
    final isDot = form == CoreBadgeForm.dot;

    // Resolver finishes className + inlineStyles synthesis — the widget
    // reads the paint-ready strings directly.
    final resolved = resolveBadge(
      context,
      tone: tone,
      variant: variant,
      form: form,
      size: size,
      interactive: isInteractive,
      badgeStyle: badgeStyle,
    );

    // Scope id for the per-instance scoped rules (state layer, and the
    // focus ring when it has no class form) — the caller's id wins
    // (passthrough), else a generated one.
    final scopeId = id ?? elementScopeId(context, prefix: 'co-badge');
    final rules = resolveBadgeRules(
      context,
      scopeId: scopeId,
      tone: tone,
      variant: variant,
      form: form,
      size: size,
      interactive: isInteractive,
      badgeStyle: badgeStyle,
    );

    // `kWebTouchTargetMarker` only when the badge accepts a press, and
    // it widens where a pointer is accepted rather than what is drawn:
    // the dot form renders as small as 4px, which no pointer lands on
    // reliably (WCAG 2.5.8). Mirrors the Flutter twin's `TouchTarget`
    // wrap; a non-interactive badge accepts nothing so it needs none.
    final base = isInteractive
        ? '${resolved.root.className} $kWebTouchTargetMarker'
        : resolved.root.className;
    final userClasses = classes;
    final finalClasses = userClasses == null || userClasses.isEmpty
        ? base
        : '$base $userClasses';

    return Component.element(
      tag: 'span',
      // The id is only needed when a scoped rule is present (or the caller
      // passed one) — non-interactive badges stay id-less so SSR markup
      // doesn't churn.
      id: rules.css.isNotEmpty ? scopeId : id,
      classes: finalClasses,
      styles: Styles.combine([?resolved.root.inlineStyles, ?css]),
      attributes: {
        ...componentAttributes,
        if (isInteractive) 'role': 'button',
        if (isInteractive) 'tabindex': '0',
      },
      events: _buildEvents(),
      children: [
        // `<style>` is `display: none`, so it never affects the
        // inline-flex layout.
        if (rules.css.isNotEmpty)
          Component.element(tag: 'style', children: [RawText(rules.css)]),
        // A dot emits no content children at all. Emitting them
        // empty would still leave the inline-flex box sized by its
        // padding rather than by the step, which is the one thing the
        // dot form exists to state.
        if (!isDot) ...[
          // The leading status dot — drawn by the label and count forms
          // only (a dot form is a dot already). Decorative: the label next
          // to it carries the meaning.
          if (showDot) ...[
            Component.element(
              tag: 'span',
              classes: resolved.leadingDot.className,
              styles: resolved.leadingDot.inlineStyles,
              attributes: const {'aria-hidden': 'true'},
            ),
            Gap(gapStyle: resolved.iconLabelGapStyle),
          ],
          // The slots take the step's icon size (and an overridden icon
          // colour) from the ambient `IconTheme`, as the Flutter twin's
          // `IconTheme(size, color)` gives them. `IconTheme` emits no DOM.
          if (leading != null) ...[
            IconTheme(
              data: IconThemeData.fromCoreIconStyle(resolved.iconStyle),
              child: form == CoreBadgeForm.label
                  ? Component.element(
                      tag: 'span',
                      classes: resolved.adornment.className,
                      styles: resolved.adornment.inlineStyles,
                      children: [leading!],
                    )
                  : leading!,
            ),
            Gap(gapStyle: resolved.iconLabelGapStyle),
          ],
          if (child != null)
            if (form == CoreBadgeForm.label)
              Component.element(
                tag: 'span',
                classes: resolved.label.className,
                styles: resolved.label.inlineStyles,
                children: [child!],
              )
            else
              Component.element(
                tag: 'span',
                classes: resolved.count.className,
                styles: resolved.count.inlineStyles,
                children: [child!],
              ),
          if (trailing != null) ...[
            Gap(gapStyle: resolved.iconLabelGapStyle),
            IconTheme(
              data: IconThemeData.fromCoreIconStyle(resolved.iconStyle),
              child: form == CoreBadgeForm.label
                  ? Component.element(
                      tag: 'span',
                      classes: resolved.adornment.className,
                      styles: resolved.adornment.inlineStyles,
                      children: [trailing!],
                    )
                  : trailing!,
            ),
          ],
        ],
      ],
    );
  }

  /// The root's event map — the caller's handlers (`eventHandlers` and the
  /// typed callbacks), with the press chained after them when the badge is
  /// pressable (`EventHandlers.chain`: the caller's handler runs, then the
  /// badge's — neither replaces the other). `null` when there is nothing to
  /// listen for, so a static badge renders no listeners.
  ///
  /// The press answers a click and, on the focused badge, Enter and Space
  /// — the activation keys a `<span role="button">` does not get from the
  /// browser, and which the Flutter twin's `Clickable` maps to the press.
  /// While the key is down the badge carries
  /// [kClickableKeyPressedMarker], which the pressed wash reads alongside
  /// `:active` (the pointer's press), so a keyboard press shows the same
  /// state the Flutter twin shows for it.
  Map<String, EventCallback>? _buildEvents() {
    final callerEvents = events;
    final currentOnPressed = onPressed;
    if (currentOnPressed == null) {
      return callerEvents.isEmpty ? null : callerEvents;
    }

    return {
      ...callerEvents,
      'click': EventHandlers.chain(
        callerEvents['click'],
        (_) => currentOnPressed(),
      ),
      'keydown': EventHandlers.chain(
        callerEvents['keydown'],
        EventHandlers.createKeyboardEventHandler((event) {
          if (!_isActivationKey(event) || !_isSelfTarget(event)) return;
          // Space would scroll the page; Enter has no default on a span
          // but is claimed alike, as a native button claims both.
          event.preventDefault();
          _setKeyPressed(event, pressed: true);
          currentOnPressed();
        }),
      ),
      'keyup': EventHandlers.chain(
        callerEvents['keyup'],
        EventHandlers.createKeyboardEventHandler((event) {
          if (_isActivationKey(event) && _isSelfTarget(event)) {
            _setKeyPressed(event, pressed: false);
          }
        }),
      ),
      // A key held while focus moves away never sees its keyup — without
      // this the badge would read as pressed until the next key.
      'focusout': EventHandlers.chain(
        callerEvents['focusout'],
        EventHandlers.createEventHandler((event) {
          if (_isSelfTarget(event)) _setKeyPressed(event, pressed: false);
        }),
      ),
    };
  }
}

/// Whether [event] is one of the keys that activate a button — Enter and
/// Space (`Spacebar` is the older spelling some browsers still send).
bool _isActivationKey(web.KeyboardEvent event) {
  final key = event.key;
  return key == 'Enter' || key == ' ' || key == 'Spacebar';
}

/// Whether [event] was dispatched on the element its listener is bound to,
/// rather than bubbled up from a focusable inside a slot — that control's
/// key press is its own, not the badge's.
bool _isSelfTarget(web.Event event) {
  final target = event.target;
  final currentTarget = event.currentTarget;
  if (target == null || currentTarget == null) return false;
  return (target as web.Node).isSameNode(currentTarget as web.Node);
}

/// Sets or clears [kClickableKeyPressedMarker] on the element [event] is
/// bound to — a class-list write, not a rebuild, so the pressed wash
/// follows the key without a render (as `:active` follows the pointer).
void _setKeyPressed(web.Event event, {required bool pressed}) {
  if (event.currentTarget case final web.HTMLElement element) {
    if (pressed) {
      element.classList.add(kClickableKeyPressedMarker);
    } else {
      element.classList.remove(kClickableKeyPressedMarker);
    }
  }
}

/// Chain sugar mirroring the Flutter `Badge.withStyle` extension —
/// merges a [CoreBadgeStyle] patch into [Badge.badgeStyle] via the
/// existing [Badge.copyWith]. Composition slots (`child` / `leading` /
/// `trailing`) keep using the `Text(...).bodyMedium...` chain directly.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreBadgeStyle.merge` right-side-wins semantics).
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
/// sets [CoreBadgeStyle.borderRadius] and `.primary` sets
/// [CoreBadgeStyle.backgroundColor]. A semantic layer that names these
/// after component-specific intent (decided together with design) is
/// a follow-up once more components adopt this pattern.
///
/// ```dart
/// Badge(child: Text('New')).radius4.primary
/// ```
extension BadgeStyleChain on Badge {
  /// Returns a copy of this [Badge] with [patch] merged into
  /// [badgeStyle] (patch fields win on conflict).
  Badge withStyle(CoreBadgeStyle patch) =>
      copyWith(badgeStyle: (badgeStyle ?? const CoreBadgeStyle()).merge(patch));

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Badge get radius0 => withStyle(
    const CoreBadgeStyle(borderRadius: CoreBorderRadius.zero),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Badge get radius2 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Badge get radius4 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Badge get radius6 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Badge get radius8 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Badge get radius10 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Badge get radius12 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Badge get radius14 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Badge get radius16 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Badge get radius20 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Badge get radius24 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Badge get radius28 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Badge get radius32 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Badge get radius36 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Badge get radius40 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Badge get radius48 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Badge get radius56 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Badge get radius64 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Badge get radius9999 => withStyle(
    const CoreBadgeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Badge get primary => withStyle(
    const CoreBadgeStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Badge get secondary => withStyle(
    const CoreBadgeStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Badge get tertiary => withStyle(
    const CoreBadgeStyle(backgroundColor: CoreColor.token(CoreColors.tertiary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Badge get surface => withStyle(
    const CoreBadgeStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Badge get surfaceContainer => withStyle(
    const CoreBadgeStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Badge get error => withStyle(
    const CoreBadgeStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Badge get success => withStyle(
    const CoreBadgeStyle(backgroundColor: CoreColor.token(CoreColors.success)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Badge get warning => withStyle(
    const CoreBadgeStyle(backgroundColor: CoreColor.token(CoreColors.warning)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Badge get info => withStyle(
    const CoreBadgeStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Badge get outline => withStyle(
    const CoreBadgeStyle(backgroundColor: CoreColor.token(CoreColors.outline)),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Badge get transparent =>
      withStyle(const CoreBadgeStyle(backgroundColor: .transparent));
}
