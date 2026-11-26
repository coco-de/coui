import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/layout/disclosure/disclosure_style.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/util/element_scope.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;

// ---------------------------------------------------------------------------
// Disclosure
// ---------------------------------------------------------------------------

/// A titled section the reader opens and closes, rendered as
/// `<details>/<summary>`.
///
/// The browser owns the toggle, the keyboard, and the screen-reader
/// semantics, so this component holds no state and needs no hydration:
/// it opens on a statically rendered page, and it keeps working with
/// scripting off. That is the whole reason it exists beside
/// `Collapsible`, which animates the reveal from component state and so
/// ships closed until the client takes over.
///
/// ```dart
/// Disclosure(
///   title: 'What is CoUI?',
///   content: const Text('A cross-platform design system.'),
/// )
/// ```
///
/// Opening one `Disclosure` never closes another. Sections that must
/// close each other belong in `Accordion`.
class Disclosure extends UiComponent
    implements CoreDisclosureContract<Component> {
  /// Creates a [Disclosure].
  ///
  /// Supply either [title] or [trigger]; [trigger] wins when both are
  /// given.
  const Disclosure({
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
    this.onToggle,
    this.title,
    this.trigger,
    this.open = false,
    this.disclosureStyle,
  }) : assert(
         trigger != null || title != null,
         'Provide either trigger or title.',
       ),
       super(tag: 'details');

  @override
  final String? title;

  @override
  final Component? trigger;

  @override
  final Component content;

  @override
  final bool open;

  @override
  final void Function(bool)? onToggle;

  @override
  final CoreDisclosureStyle? disclosureStyle;

  /// Returns a copy of this [Disclosure] with the given fields replaced.
  @override
  Disclosure copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    Map<String, List<UiEventHandler>>? eventHandlers,
    UiInputEventHandler? onChange,
    UiMouseEventHandler? onClick,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    void Function(bool)? onToggle,
    String? title,
    Component? trigger,
    Component? content,
    bool? open,
    CoreDisclosureStyle? disclosureStyle,
  }) {
    return Disclosure(
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      key: key ?? this.key,
      onChange: onChange ?? this.onChange,
      onClick: onClick ?? this.onClick,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
      onToggle: onToggle ?? this.onToggle,
      title: title ?? this.title,
      trigger: trigger ?? this.trigger,
      content: content ?? this.content,
      open: open ?? this.open,
      disclosureStyle: disclosureStyle ?? this.disclosureStyle,
    );
  }

  @override
  Component build(BuildContext context) {
    // Single entry point — the resolver applies the merge chain.
    final resolved = resolveDisclosure(
      context,
      disclosureStyle: disclosureStyle,
    );

    // The caller's id wins; otherwise one is generated, but only the
    // focus-ring fallback rule needs it — the marker rule below is
    // class-scoped precisely so the default path stays id-less.
    final scopeId = id ?? elementScopeId(context, prefix: 'co-disclosure');
    final rules = resolveDisclosureRules(
      context,
      scopeId: scopeId,
      disclosureStyle: disclosureStyle,
    );
    final needsScopeId = rules.css.contains('#$scopeId');

    return Component.element(
      tag: tag,
      id: needsScopeId ? scopeId : id,
      classes: rootClasses(resolved.root.className),
      styles: Styles.combine([?resolved.root.inlineStyles, ?css]),
      attributes: {
        ...componentAttributes,
        // The browser maintains this attribute from here on — which is
        // also how the pre-rendered markup already shows an initially
        // open section, with nothing to hydrate.
        if (open) 'open': '',
      },
      events: {
        ...events,
        if (onToggle != null)
          'toggle': EventHandlers.createElementTargetEventHandler(
            // Read the attribute rather than the `open` property: the
            // property needs a cast through an extension type, and a
            // dynamic hop there compiles to a mangled name that dies in
            // release builds (rules/web/web-specifics.md).
            (_, target) => onToggle!(target.hasAttribute('open')),
          ),
      },
      children: [
        Component.element(
          tag: 'summary',
          classes: resolved.summaryRow.className,
          styles: resolved.summaryRow.inlineStyles,
          children: [
            Component.element(
              tag: 'div',
              classes: resolved.triggerText.className,
              styles: resolved.triggerText.inlineStyles,
              children: [trigger ?? Text(title!)],
            ),
            Gap(gapStyle: resolved.iconLabelGapStyle),
            Component.element(
              tag: 'div',
              classes: resolved.chevron.className,
              styles: resolved.chevron.inlineStyles,
              children: [
                Icon(LucideIcons.chevronDown, iconStyle: resolved.iconStyle),
              ],
            ),
          ],
        ),
        Component.element(
          tag: 'div',
          classes: resolved.content.className,
          styles: resolved.content.inlineStyles,
          children: [content],
        ),
        // `<style>` is `display: none` and unaffected by an ancestor's
        // collapsed state, so it applies whether or not the section is
        // open.
        Component.element(tag: 'style', children: [RawText(rules.css)]),
      ],
    );
  }
}

/// Chain sugar mirroring the Flutter `Disclosure.withStyle` extension.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDisclosureStyle.merge` right-side-wins semantics).
extension DisclosureStyleChain on Disclosure {
  /// Returns a copy of this [Disclosure] with [patch] merged into
  /// [disclosureStyle] (patch fields win on conflict).
  Disclosure withStyle(CoreDisclosureStyle patch) => copyWith(
    disclosureStyle: (disclosureStyle ?? const CoreDisclosureStyle()).merge(
      patch,
    ),
  );
}

// ---------------------------------------------------------------------------
// DisclosureGroup
// ---------------------------------------------------------------------------

/// A stack of independent [Disclosure]s.
///
/// Opening one leaves the others alone — that is the whole difference
/// from `Accordion`, and it is why the group needs no state: each child
/// already owns its own.
///
/// ```dart
/// DisclosureGroup(
///   items: [
///     Disclosure(title: 'First', open: true, content: const Text('…')),
///     Disclosure(title: 'Second', content: const Text('…')),
///   ],
/// )
/// ```
class DisclosureGroup extends UiComponent
    implements CoreDisclosureGroupContract<Component> {
  /// Creates a [DisclosureGroup].
  const DisclosureGroup({
    required this.items,
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
    this.disclosureStyle,
  }) : super(tag: 'div');

  @override
  final List<Component> items;

  @override
  final CoreDisclosureStyle? disclosureStyle;

  /// Returns a copy of this [DisclosureGroup] with the given fields
  /// replaced.
  @override
  DisclosureGroup copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    Map<String, List<UiEventHandler>>? eventHandlers,
    UiInputEventHandler? onChange,
    UiMouseEventHandler? onClick,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    List<Component>? items,
    CoreDisclosureStyle? disclosureStyle,
  }) {
    return DisclosureGroup(
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      key: key ?? this.key,
      onChange: onChange ?? this.onChange,
      onClick: onClick ?? this.onClick,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
      items: items ?? this.items,
      disclosureStyle: disclosureStyle ?? this.disclosureStyle,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveDisclosureGroup(
      context,
      disclosureStyle: disclosureStyle,
    );

    return Component.element(
      tag: tag,
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: Styles.combine([?resolved.root.inlineStyles, ?css]),
      attributes: componentAttributes,
      events: events,
      children: items,
    );
  }
}

/// Chain sugar mirroring [DisclosureStyleChain] for the group.
extension DisclosureGroupStyleChain on DisclosureGroup {
  /// Returns a copy of this [DisclosureGroup] with [patch] merged into
  /// [disclosureStyle] (patch fields win on conflict).
  DisclosureGroup withStyle(CoreDisclosureStyle patch) => copyWith(
    disclosureStyle: (disclosureStyle ?? const CoreDisclosureStyle()).merge(
      patch,
    ),
  );
}
