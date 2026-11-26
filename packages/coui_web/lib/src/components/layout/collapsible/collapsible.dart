import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/layout/collapsible/collapsible_style.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Unified cross-platform collapsible component for CoUI Web.
///
/// Provides a trigger element and content that can be toggled
/// between expanded and collapsed states with animated transitions.
///
/// ```dart
/// Collapsible(
///   trigger: text('Toggle Content'),
///   content: text('Hidden content here'),
///   expanded: false,
/// )
/// ```
class Collapsible extends UiStatefulComponent
    implements CoreCollapsibleContract<Component> {
  /// Creates a [Collapsible].
  const Collapsible({
    required this.trigger,
    required this.content,
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
    this.expanded = false,
    this.onExpandedChanged,
    this.collapsibleStyle,
  });

  @override
  final Component trigger;

  @override
  final Component content;

  @override
  final bool expanded;

  @override
  final void Function(bool)? onExpandedChanged;

  @override
  final CoreCollapsibleStyle? collapsibleStyle;

  /// Returns a copy of this [Collapsible] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Collapsible copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    Component? trigger,
    Component? content,
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
    bool? expanded,
    void Function(bool)? onExpandedChanged,
    CoreCollapsibleStyle? collapsibleStyle,
  }) {
    return Collapsible(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      trigger: trigger ?? this.trigger,
      content: content ?? this.content,
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
      expanded: expanded ?? this.expanded,
      onExpandedChanged: onExpandedChanged ?? this.onExpandedChanged,
      collapsibleStyle: collapsibleStyle ?? this.collapsibleStyle,
    );
  }

  @override
  State<Collapsible> createState() => _CollapsibleState();
}

/// Chain sugar mirroring the Flutter `Collapsible.withStyle` extension —
/// merges a [CoreCollapsibleStyle] patch into [Collapsible.collapsibleStyle]
/// via the existing [Collapsible.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreCollapsibleStyle.merge` right-side-wins semantics).
extension CollapsibleStyleChain on Collapsible {
  /// Returns a copy of this [Collapsible] with [patch] merged into
  /// [collapsibleStyle] (patch fields win on conflict).
  Collapsible withStyle(CoreCollapsibleStyle patch) => copyWith(
    collapsibleStyle: (collapsibleStyle ?? const CoreCollapsibleStyle()).merge(
      patch,
    ),
  );
}

class _CollapsibleState extends State<Collapsible> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = component.expanded;
  }

  void _handleToggle() {
    final callback = component.onExpandedChanged;
    if (callback != null) {
      callback(!_isExpanded);
    } else {
      setState(() {
        _isExpanded = !_isExpanded;
      });
    }
  }

  @override
  void didUpdateComponent(covariant Collapsible oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (component.expanded != oldComponent.expanded) {
      _isExpanded = component.expanded;
    }
  }

  @override
  Component build(BuildContext context) {
    // Single entry point — the resolver applies the merge chain.
    final resolved = resolveCollapsible(
      context,
      isExpanded: _isExpanded,
      collapsibleStyle: component.collapsibleStyle,
    );

    return Component.element(
      tag: 'div',
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: component.events,
      children: [
        // Composition: the trigger's tap / keyboard activation (Enter /
        // Space) / cursor / `:focus-visible` ring / selection-exclusion
        // all flow through the unified `Clickable` — no hand-rolled
        // `role="button"` div, click / keydown / focus / blur handlers,
        // or `FocusOutline` wrapper. `w-full` spreads the `inline-flex`
        // Clickable across the full row so the chevron stays pinned to
        // the right (the inner row is `flex items-center w-full`).
        // `aria-expanded` rides the Clickable root (caller-attribute
        // passthrough wins over the default `role="button"`); the
        // `hover:underline` on the trigger text is CSS-native and
        // unchanged. Press-scale off + focus-ring radius come from
        // `resolved.clickableStyle`.
        Clickable(
          onPressed: _handleToggle,
          attributes: {'aria-expanded': '$_isExpanded'},
          classes: WebLayout.wFull,
          clickableStyle: resolved.clickableStyle,
          child: div(
            [
              // Trigger content.
              div(
                [component.trigger],
                classes: resolved.triggerText.className,
                styles: resolved.triggerText.inlineStyles,
              ),
              // Trigger ↔ chevron gap — nested Gap slot. Mirrors the
              // Flutter parity exemplar (basic / breadcrumb); the
              // receiving Gap runs its own resolve/scaling step so no
              // inline `width` rem leak rides the trigger row.
              Gap(gapStyle: resolved.iconLabelGapStyle),
              // Chevron icon with rotation.
              div(
                [
                  Icon(
                    LucideIcons.chevronDown,
                    iconStyle: resolved.iconStyle,
                  ),
                ],
                classes: resolved.chevron.className,
                styles: resolved.chevron.inlineStyles,
              ),
            ],
            classes: resolved.triggerRow.className,
            styles: resolved.triggerRow.inlineStyles,
          ),
        ),
        // Collapsible content with grid-rows animation.
        div(
          [
            div(
              [component.content],
              classes: resolved.contentInner.className,
              styles: resolved.contentInner.inlineStyles,
            ),
          ],
          // Same as the accordion: clipped to zero height hides it from
          // sight only. `inert` takes it out of the accessibility tree,
          // the tab order and hit-testing together.
          classes: resolved.content.className,
          styles: resolved.content.inlineStyles,
          attributes: _isExpanded ? null : const {'inert': ''},
        ),
      ],
    );
  }
}
