import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/form/checkbox/checkbox.dart';
import 'package:coui_web/src/components/form/multi_answer_card/multi_answer_card_style.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart';

/// Unified cross-platform selectable answer card for CoUI Web.
///
/// `MultiAnswerCard` is a card-styled selectable surface — typically
/// used in quizzes / surveys where the user picks one or more answers.
/// It carries an opaque [value] and reflects [selected] state with
/// distinct border / background chrome. Uses custom `<div>` rendering
/// for visual parity with Flutter `MultiAnswerCard`.
///
/// Per Epic #1302 원칙 6/7, behaviour / semantic fields (`value`,
/// `selected`, `enabled`, `onChanged`, `child`) stay flat on the widget.
/// All chrome / dimensional overrides flow through the single
/// [multiAnswerCardStyle] (a [CoreMultiAnswerCardStyle]).
///
/// Example:
/// ```dart
/// MultiAnswerCard<String>(
///   value: 'a',
///   selected: true,
///   onChanged: (v) => print('picked $v'),
///   child: text('Answer A'),
/// )
/// ```
///
/// surface:content — draws its own box (a single `<div>` restating the
/// surface marker rather than a parent panel drawing it), on the page
/// rather than floating over it.
class MultiAnswerCard<T> extends UiStatefulComponent
    implements CoreMultiAnswerCardContract<T, Component> {
  /// Creates a [MultiAnswerCard].
  const MultiAnswerCard({
    required this.value,
    required this.child,
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
    this.selected = false,
    this.enabled = true,
    this.onChanged,
    this.multiAnswerCardStyle,
  });

  @override
  final T value;

  @override
  final bool selected;

  @override
  final bool enabled;

  @override
  final void Function(T)? onChanged;

  @override
  final Component child;

  // === Style (chrome / dimensional) ===

  @override
  final CoreMultiAnswerCardStyle? multiAnswerCardStyle;

  /// Returns a copy of this [MultiAnswerCard] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  MultiAnswerCard<T> copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    void Function(T)? onChanged,
    T? value,
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
    bool? selected,
    bool? enabled,
    CoreMultiAnswerCardStyle? multiAnswerCardStyle,
    Component? child,
  }) {
    return MultiAnswerCard(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      onChanged: onChanged ?? this.onChanged,
      value: value ?? this.value,
      attributes: attributes ?? userAttributes,
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
      selected: selected ?? this.selected,
      enabled: enabled ?? this.enabled,
      multiAnswerCardStyle: multiAnswerCardStyle ?? this.multiAnswerCardStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<MultiAnswerCard<T>> createState() => _MultiAnswerCardState<T>();
}

class _MultiAnswerCardState<T> extends State<MultiAnswerCard<T>> {
  bool _hovering = false;

  void _handleTap() {
    if (!component.enabled) return;
    component.onChanged?.call(component.value);
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveMultiAnswerCard(
      context,
      multiAnswerCardStyle: component.multiAnswerCardStyle,
    );

    // State select — the resolver pre-baked the mutually-exclusive
    // idle / hover / selected / disabled chrome bundles; the widget only
    // picks. Priority matches Flutter parity: `disabled` wins over
    // `selected` wins over `hovered` wins over the idle base.
    final chrome = !component.enabled
        ? resolved.disabledRoot
        : component.selected
        ? resolved.selectedRoot
        : (_hovering ? resolved.hoverRoot : resolved.root);

    // Web twin of the Flutter card: the composed Clickable owns tap /
    // keyboard activation / cursor / press feedback / focus ring /
    // disabled opacity; the inner <div> carries only the card chrome.
    // Hover state flows back through `onHover` for the chrome select
    // above. `w-full` keeps the inline-flex Clickable root spanning
    // the row (structural layout passthrough — the card is a block
    // surface); caller classes merge after it.
    return Clickable(
      onPressed: _handleTap,
      onClick: component.onClick,
      attributes: {
        'role': 'button',
        'aria-pressed': component.selected.toString(),
        ...component.componentAttributes,
      },
      classes: component.rootClasses(WebLayout.wFull),
      css: component.css,
      eventHandlers: component.eventHandlers,
      id: component.id,
      onChange: component.onChange,
      onInput: component.onInput,
      onKeyDown: component.onKeyDown,
      onKeyUp: component.onKeyUp,
      onMouseEnter: component.onMouseEnter,
      onMouseLeave: component.onMouseLeave,
      onHover: (hovered) => setState(() => _hovering = hovered),
      enabled: component.enabled,
      clickableStyle: resolved.clickableStyle,
      child: Component.element(
        tag: 'div',
        classes: chrome.className,
        styles: chrome.inlineStyles,
        children: [
          Component.element(
            tag: 'div',
            classes: resolved.content.className,
            children: [component.child],
          ),
          Gap(gapStyle: resolved.checkboxGapStyle),
          // The checkbox only shows the selection — the card's own
          // Clickable owns the click — so it is taken out of pointer
          // events and the accessibility tree (the Flutter twin
          // excludes it from hit-testing, focus and semantics).
          // A flex wrapper, not a plain block: the checkbox is inline-level,
          // and a block holding it keeps a line box whose strut is the
          // card's text line height — it would make the 18px box 24px tall
          // and the card taller than the Flutter twin's.
          Component.element(
            tag: 'div',
            classes: '${WebLayout.flex} ${WebLayout.pointerEventsNone}',
            attributes: const {'aria-hidden': 'true'},
            children: [
              Checkbox(
                checked: component.selected,
                enabled: component.enabled,
                size: resolved.checkboxSize,
                checkboxStyle: resolved.checkboxStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chain sugar mirroring the Flutter `MultiAnswerCard.withStyle`
/// extension — merges a [CoreMultiAnswerCardStyle] patch into
/// [MultiAnswerCard.multiAnswerCardStyle] via the existing
/// [MultiAnswerCard.copyWith]. The composition slot (`child`) keeps
/// using its own content directly — this extension only covers the
/// [CoreMultiAnswerCardStyle] chrome slot.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreMultiAnswerCardStyle.merge` right-side-wins semantics).
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
/// sets [CoreMultiAnswerCardStyle.borderRadius] and `.primary` sets
/// [CoreMultiAnswerCardStyle.backgroundColor]. A semantic layer that
/// names these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// MultiAnswerCard<String>(
///   value: 'a',
///   child: text('Answer A'),
/// ).radius4.surface
/// ```
extension MultiAnswerCardStyleChain<T> on MultiAnswerCard<T> {
  /// Sets the background paint and preserves the other style fields.
  MultiAnswerCard<T> backgroundColor(CoreColor value) =>
      withStyle(CoreMultiAnswerCardStyle(backgroundColor: value));

  /// Returns a copy of this [MultiAnswerCard] with [patch] merged into
  /// [multiAnswerCardStyle] (patch fields win on conflict).
  MultiAnswerCard<T> withStyle(CoreMultiAnswerCardStyle patch) => copyWith(
    multiAnswerCardStyle:
        (multiAnswerCardStyle ?? const CoreMultiAnswerCardStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  MultiAnswerCard<T> get radius0 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.zero,
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  MultiAnswerCard<T> get radius2 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  MultiAnswerCard<T> get radius4 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  MultiAnswerCard<T> get radius6 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  MultiAnswerCard<T> get radius8 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  MultiAnswerCard<T> get radius10 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  MultiAnswerCard<T> get radius12 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  MultiAnswerCard<T> get radius14 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  MultiAnswerCard<T> get radius16 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  MultiAnswerCard<T> get radius20 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  MultiAnswerCard<T> get radius24 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  MultiAnswerCard<T> get radius28 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  MultiAnswerCard<T> get radius32 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  MultiAnswerCard<T> get radius36 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  MultiAnswerCard<T> get radius40 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  MultiAnswerCard<T> get radius48 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  MultiAnswerCard<T> get radius56 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  MultiAnswerCard<T> get radius64 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  MultiAnswerCard<T> get radius9999 => withStyle(
    const CoreMultiAnswerCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  MultiAnswerCard<T> get primary => withStyle(
    const CoreMultiAnswerCardStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  MultiAnswerCard<T> get secondary => withStyle(
    const CoreMultiAnswerCardStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  MultiAnswerCard<T> get tertiary => withStyle(
    const CoreMultiAnswerCardStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  MultiAnswerCard<T> get surface => withStyle(
    const CoreMultiAnswerCardStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  MultiAnswerCard<T> get surfaceContainer => withStyle(
    const CoreMultiAnswerCardStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  MultiAnswerCard<T> get error => withStyle(
    const CoreMultiAnswerCardStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  MultiAnswerCard<T> get success => withStyle(
    const CoreMultiAnswerCardStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  MultiAnswerCard<T> get warning => withStyle(
    const CoreMultiAnswerCardStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  MultiAnswerCard<T> get info => withStyle(
    const CoreMultiAnswerCardStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  MultiAnswerCard<T> get outline => withStyle(
    const CoreMultiAnswerCardStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  MultiAnswerCard<T> get transparent => withStyle(
    const CoreMultiAnswerCardStyle(backgroundColor: .transparent),
  );
}
