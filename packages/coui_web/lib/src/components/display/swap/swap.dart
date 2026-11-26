import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/display/swap/swap_style.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Unified cross-platform swap component for CoUI Web.
///
/// Toggles between two visual states with optional animation.
/// Extends [UiStatefulComponent] for Flutter-parity interaction plus the
/// shared chrome passthrough (id / classes / css / attributes / events).
class Swap extends UiStatefulComponent implements CoreSwapContract<Component> {
  /// Creates a [Swap].
  const Swap({
    required this.onContent,
    required this.offContent,
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
    this.checked = false,
    this.animation = CoreSwapAnimation.none,
    this.onToggle,
    this.swapStyle,
  });

  @override
  final Component onContent;

  @override
  final Component offContent;

  @override
  final bool checked;

  @override
  final CoreSwapAnimation animation;

  /// Toggle callback.
  @override
  final ValueChanged<bool>? onToggle;

  @override
  final CoreSwapStyle? swapStyle;

  /// Returns a copy of this [Swap] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Swap copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    Component? onContent,
    Component? offContent,
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
    bool? checked,
    CoreSwapAnimation? animation,
    ValueChanged<bool>? onToggle,
    CoreSwapStyle? swapStyle,
  }) {
    return Swap(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      onContent: onContent ?? this.onContent,
      offContent: offContent ?? this.offContent,
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
      checked: checked ?? this.checked,
      animation: animation ?? this.animation,
      onToggle: onToggle ?? this.onToggle,
      swapStyle: swapStyle ?? this.swapStyle,
    );
  }

  @override
  State<Swap> createState() => _SwapState();
}

class _SwapState extends State<Swap> {
  void handleToggle() {
    component.onToggle!(!component.checked);
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveSwap(
      context,
      checked: component.checked,
      animation: component.animation,
      swapStyle: component.swapStyle,
    );

    // Both slots are always mounted so the swap can animate between
    // them, which means the one that is not showing is still in the
    // document — read aloud and tabbable — while being invisible. The
    // rest of the kit hides such a subtree with `inert`; a swap that did
    // not would announce both of its faces at once.
    final slots = [
      div(
        [component.offContent],
        classes: resolved.offSlot.className,
        styles: resolved.offSlot.inlineStyles,
        attributes: component.checked ? const {'inert': ''} : null,
      ),
      div(
        [component.onContent],
        classes: resolved.onSlot.className,
        styles: resolved.onSlot.inlineStyles,
        attributes: component.checked ? null : const {'inert': ''},
      ),
    ];

    final overlapChrome = resolveSwapOverlapLayout(component.animation);
    // The layout owner is stable across checked and animation changes.
    // Caller display/transform styles continue to target the existing root.
    final overlap = div(
      slots,
      classes: overlapChrome.className,
      styles: overlapChrome.inlineStyles,
    );

    // Non-interactive swap (no onToggle) is a pure display surface
    // driven externally — no Clickable wrapper, so it keeps the plain
    // cursor / no focus ring / full opacity (Clickable's
    // `enabled: false` would paint the disabled affordance). The caller
    // chrome passthrough lands on the root <div> as before.
    if (component.onToggle == null) {
      return div(
        [overlap],
        id: component.id,
        classes: component.rootClasses(resolved.root.className),
        styles: component.css != null
            ? Styles.combine([?resolved.root.inlineStyles, component.css!])
            : resolved.root.inlineStyles,
        attributes: component.componentAttributes,
        events: component.events,
      );
    }

    // Web twin of the Flutter swap: the outer Clickable owns tap /
    // keyboard activation / cursor / press feedback / focus ring, and
    // the caller chrome passthrough rides its root. The rotate / flip
    // CSS transform stays on the inner root <div> — Clickable's press
    // scale is a `transform` on its own wrapper node, so the two never
    // fight over the same property.
    return Clickable(
      onPressed: handleToggle,
      onClick: component.onClick,
      attributes: {
        // Toggle semantics — role stays the Clickable default `button`.
        'aria-pressed': '${component.checked}',
        // Caller identity / semantic attributes win (passthrough).
        ...component.componentAttributes,
      },
      classes: [overlapChrome.className, ?component.classes].join(' ').trim(),
      css: component.css,
      eventHandlers: component.eventHandlers,
      id: component.id,
      onChange: component.onChange,
      onInput: component.onInput,
      onKeyDown: component.onKeyDown,
      onKeyUp: component.onKeyUp,
      onMouseEnter: component.onMouseEnter,
      onMouseLeave: component.onMouseLeave,
      clickableStyle: resolved.clickableStyle,
      child: div(
        [overlap],
        classes: resolved.root.className,
        styles: resolved.root.inlineStyles,
      ),
    );
  }
}

/// Chain sugar mirroring the Flutter `Swap.withStyle` extension —
/// merges a [CoreSwapStyle] patch into [Swap.swapStyle] via the
/// existing [Swap.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreSwapStyle.merge` right-side-wins semantics).
extension SwapStyleChain on Swap {
  /// Returns a copy of this [Swap] with [patch] merged into
  /// [swapStyle] (patch fields win on conflict).
  Swap withStyle(CoreSwapStyle patch) =>
      copyWith(swapStyle: (swapStyle ?? const CoreSwapStyle()).merge(patch));
}
