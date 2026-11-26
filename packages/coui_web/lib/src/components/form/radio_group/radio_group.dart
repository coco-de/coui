import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/form/form/form_controller.dart';
import 'package:coui_web/src/components/form/radio_group/radio_group_style.dart';
import 'package:coui_web/src/components/infra/focus_outline/focus_outline.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:universal_web/web.dart' as web;

/// Unified cross-platform radio group for CoUI Web with token-based rendering.
///
/// Per Epic #1302 원칙 6/7, semantic enums (`variant`, `size`,
/// `orientation`) stay as widget parameters because they identify the
/// radio group instance. All chrome / dimensional / nested-slot
/// overrides flow through the single [radioGroupStyle] (a
/// [CoreRadioGroupStyle]).
///
/// Uses custom `<div>` rendering (not native `<input type="radio">`)
/// to achieve visual parity with Flutter RadioGroup.
///
/// Example:
/// ```dart
/// RadioGroup(
///   value: 'option1',
///   onChanged: (v) => print('Selected: $v'),
///   options: [
///     (value: 'option1', label: 'Option 1'),
///     (value: 'option2', label: 'Option 2'),
///   ],
/// )
/// ```
class RadioGroup extends UiStatefulComponent
    implements
        CoreRadioGroupContract<
          String,
          Component,
          CoreFocusNode,
          CoreStatesController,
          Object
        > {
  /// Creates a [RadioGroup].
  const RadioGroup({
    super.key,
    this.value,
    this.initialValue,
    this.onChanged,
    this.enabled,
    this.options,
    this.child,
    this.variant = CoreRadioGroupVariant.defaultVariant,
    this.size = CoreComponentSize.md,
    this.orientation = CoreRadioGroupOrientation.vertical,
    this.radioGroupStyle,
    this.name,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : assert(
         child != null || options != null,
         'Provide either child or options.',
       );

  /// Custom child override (mutually exclusive with [options]).
  @override
  final Component? child;

  // === State ===

  @override
  final String? value;

  /// Seed selection for the uncontrolled path — when non-null the group
  /// owns its own selection and [value] is not read. The Flutter twin
  /// reads the same parameter.
  @override
  final String? initialValue;

  @override
  final CoreValueChanged<String?>? onChanged;

  /// Whether the radio group is enabled. `null` (the default) falls back
  /// to `onChanged != null` so a group with no callback reads as disabled —
  /// matching Flutter `RadioGroup` (Epic #2317, Flutter is the
  /// cross-platform reference). Pass `true`/`false` to force it.
  @override
  final bool? enabled;

  /// Effective interactive state — explicit [enabled] wins, else the
  /// presence of an [onChanged] callback decides (Flutter parity).
  bool get _effectiveEnabled => enabled ?? (onChanged != null);

  // === Content ===

  @override
  final List<({String value, String label})>? options;

  // === Semantic identity (widget params, not chrome) ===

  @override
  final CoreRadioGroupVariant variant;

  @override
  final CoreComponentSize size;

  @override
  final CoreRadioGroupOrientation orientation;

  // === Style (chrome / dimensional / nested slot) ===

  @override
  final CoreRadioGroupStyle? radioGroupStyle;

  // === Form ===

  @override
  final String? name;

  // === Contract defaults (Web-limited fields) ===

  @override
  CoreFocusNode? get focusNode => null;

  @override
  CoreStatesController? get statesController => null;

  @override
  Object? get controller => null;

  /// Returns a copy of this radio group with the given fields replaced.
  RadioGroup copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    String? value,
    String? initialValue,
    CoreValueChanged<String?>? onChanged,
    bool? enabled,
    List<({String value, String label})>? options,
    Component? child,
    CoreRadioGroupVariant? variant,
    CoreComponentSize? size,
    CoreRadioGroupOrientation? orientation,
    CoreRadioGroupStyle? radioGroupStyle,
    String? name,
  }) {
    return RadioGroup(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      initialValue: initialValue ?? this.initialValue,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
      options: options ?? this.options,
      variant: variant ?? this.variant,
      size: size ?? this.size,
      orientation: orientation ?? this.orientation,
      radioGroupStyle: radioGroupStyle ?? this.radioGroupStyle,
      name: name ?? this.name,
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      child: child ?? this.child,
    );
  }

  @override
  State<RadioGroup> createState() => _RadioGroupState();
}

class _RadioGroupState extends State<RadioGroup>
    with FormValueSupplier<String?, RadioGroup> {
  /// Selection owned by the group on the uncontrolled path — see
  /// [RadioGroup.initialValue]. Unread while controlled.
  String? _uncontrolledValue;

  /// Whether the group owns its selection instead of reading
  /// [RadioGroup.value].
  bool get _isUncontrolled => component.initialValue != null;

  /// The selection the radios render against.
  String? get _effectiveValue =>
      _isUncontrolled ? _uncontrolledValue : component.value;

  @override
  void initState() {
    super.initState();
    _uncontrolledValue = component.initialValue;
    formValue = _effectiveValue;
  }

  @override
  void didUpdateComponent(covariant RadioGroup oldComponent) {
    super.didUpdateComponent(oldComponent);
    // Only the controlled path tracks the incoming value — an
    // uncontrolled group's selection lives in this state, so re-reading
    // the parameter would undo what the user just picked.
    if (!_isUncontrolled && component.value != oldComponent.value) {
      formValue = component.value;
    }
  }

  /// Relays a selection: an uncontrolled group also records it, since no
  /// one outside will hand it back.
  void handleChanged(String? value) {
    if (_isUncontrolled) {
      setState(() => _uncontrolledValue = value);
      formValue = value;
    }
    component.onChanged?.call(value);
  }

  @override
  void didReplaceFormValue(String? value) {
    if (_isUncontrolled) {
      setState(() => _uncontrolledValue = value);
    }
    component.onChanged?.call(value);
  }

  @override
  Component build(BuildContext context) {
    // Resolver finishes className + inlineStyles synthesis (Epic #1603
    // 옵션 B — `WebResolvedChrome` contract). `radio_group` reads
    // the paint-ready strings directly without invoking the top-level
    // builder helpers.
    final resolved = resolveRadioGroup(
      context,
      variant: component.variant,
      size: component.size,
      orientation: component.orientation,
      radioGroupStyle: component.radioGroupStyle,
    );

    // Stay `null` when nothing can respond, so a group with neither an
    // owned selection nor a callback leaves its radios without handlers
    // rather than wiring listeners that do nothing.
    final onChanged = _isUncontrolled || component.onChanged != null
        ? handleChanged
        : null;

    final child = component.child;
    // `options` items and a `child` radio read the group the same way —
    // through the scope below, as the Flutter group hands its radios its
    // data.
    final resolvedChildren = child != null
        ? [child]
        : [
            for (final option in component.options!)
              Radio(value: option.value, label: option.label),
          ];

    return _RadioGroupScope(
      value: _effectiveValue,
      onChanged: onChanged,
      enabled: component._effectiveEnabled,
      group: resolved,
      variant: component.variant,
      size: component.size,
      name: component.name,
      child: _buildRoot(onChanged, resolved, resolvedChildren),
    );
  }

  Component _buildRoot(
    CoreValueChanged<String?>? onChanged,
    ResolvedRadioGroup resolved,
    List<Component> resolvedChildren,
  ) {
    return Component.element(
      tag: 'div',
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: {
        ...component.componentAttributes,
        'role': 'radiogroup',
        if (!component._effectiveEnabled) 'aria-disabled': 'true',
      },
      events: {
        ...component.events,
        if (component._effectiveEnabled && onChanged != null)
          'keydown': EventHandlers.createKeyboardEventHandler(
            handleGroupKeyDown,
          ),
      },
      children: resolvedChildren,
    );
  }

  /// Moves keyboard focus to the next/previous radio with the arrow
  /// keys, wrapping at the ends (native radio-group convention).
  /// Selection follows focus via the radios' keyboard-focus
  /// auto-select, so this only moves focus.
  void handleGroupKeyDown(web.KeyboardEvent event) {
    final int delta;
    switch (event.key) {
      case 'ArrowRight' || 'ArrowDown':
        delta = 1;
      case 'ArrowLeft' || 'ArrowUp':
        delta = -1;
      default:
        return;
    }
    if (event.currentTarget case final web.HTMLElement root) {
      final radios = root.querySelectorAll(
        '[role="radio"]:not([aria-disabled="true"])',
      );
      if (radios.length == 0) return;
      var current = -1;
      for (var i = 0; i < radios.length; i++) {
        if (radios.item(i) == web.document.activeElement) {
          current = i;
          break;
        }
      }
      if (current == -1) {
        for (var i = 0; i < radios.length; i++) {
          if (radios.item(i) case final web.Element el
              when el.getAttribute('aria-checked') == 'true') {
            current = i;
            break;
          }
        }
      }
      event.preventDefault();
      final next = (current + delta + radios.length) % radios.length;
      if (radios.item(next) case final web.HTMLElement target) {
        target.focus();
      }
    }
  }
}

/// What a [RadioGroup] hands the [Radio]s under it — the selection, the
/// callback, whether the group is enabled, its resolved bundle, variant,
/// size and form name. The Web counterpart to the Flutter group's ambient
/// data, so a radio passed as `child` reads the group the way an `options`
/// item does.
class _RadioGroupScope extends InheritedComponent {
  const _RadioGroupScope({
    required this.value,
    required this.onChanged,
    required this.enabled,
    required this.group,
    required this.variant,
    required this.size,
    required this.name,
    required super.child,
  });

  final String? value;
  final CoreValueChanged<String?>? onChanged;
  final bool enabled;
  final ResolvedRadioGroup group;
  final CoreRadioGroupVariant variant;
  final CoreComponentSize size;
  final String? name;

  static _RadioGroupScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedComponentOfExactType<_RadioGroupScope>();
  }

  @override
  bool updateShouldNotify(_RadioGroupScope oldComponent) {
    return value != oldComponent.value ||
        onChanged != oldComponent.onChanged ||
        enabled != oldComponent.enabled ||
        group != oldComponent.group ||
        variant != oldComponent.variant ||
        size != oldComponent.size ||
        name != oldComponent.name;
  }
}

/// Single radio inside a [RadioGroup]. Inside a `card` group
/// ([groupVariant]) it draws as a tile.
///
/// Internally a [StatefulComponent] so the wrapper can track keyboard
/// focus on the radio button (`:focus-visible`) and forward it to
/// [FocusOutline] — the same model the Flutter implementation uses.
///
/// Example:
/// ```dart
/// Radio(
///   value: 'option1',
///   groupValue: selectedValue,
///   label: 'Option 1',
///   onChanged: (value) => print('Selected: $value'),
/// )
/// ```
///
/// surface:content — a control box that sits in the flow, not something
/// mounted over content.
class Radio extends UiStatefulComponent
    implements CoreRadioItemContract<String, Component> {
  /// Creates a [Radio].
  const Radio({
    required this.value,
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
    this.groupValue,
    this.label,
    this.labelMaxLines,
    this.labelOverflow,
    this.description,
    this.prefix,
    this.suffix,
    this.enabled = true,
    this.group,
    this.groupVariant = CoreRadioGroupVariant.defaultVariant,
    this.groupSize = CoreComponentSize.md,
    this.name,
    this.onChanged,
  });

  // === Contract fields ===

  @override
  final String value;

  /// The currently selected value in the group. Inside a [RadioGroup]
  /// it falls back to the group's selection when left null.
  @override
  final String? groupValue;

  @override
  final String? label;

  @override
  final int? labelMaxLines;

  @override
  final CoreTextOverflow? labelOverflow;

  @override
  final String? description;

  @override
  final bool enabled;

  /// Resolved group bundle. Inside a [RadioGroup] it falls back to the
  /// group's when left null; standalone, the component resolves one itself
  /// from [groupVariant] / [groupSize].
  final ResolvedRadioGroup? group;

  /// Variant for a standalone radio. Inside a [RadioGroup] the group's
  /// variant decides and this is not read.
  @override
  final CoreRadioGroupVariant groupVariant;

  /// Size for a standalone radio. Inside a [RadioGroup] the group's size
  /// decides and this is not read, as with [groupVariant].
  @override
  final CoreComponentSize groupSize;

  /// Form field name for submission. Inside a [RadioGroup] it falls back to
  /// the group's name when left null.
  final String? name;

  /// Callback when radio state changes. Inside a [RadioGroup] it falls back
  /// to the group's callback when left null.
  @override
  final CoreValueChanged<String?>? onChanged;

  @override
  final Component? prefix;

  @override
  final Component? suffix;

  @override
  State<Radio> createState() => _RadioState();
}

class _RadioState extends State<Radio> {
  /// Tracks `:focus-visible` on the radio button to drive [FocusOutline].
  /// Mirrors Flutter widget's `_focusing && isSelected` gate.
  bool _focused = false;

  Map<String, EventCallback> _buildEvents({
    required CoreValueChanged<String?>? currentOnChanged,
    required bool enabled,
    required String? groupValue,
  }) {
    return {
      if (currentOnChanged != null && enabled)
        'click': (_) {
          currentOnChanged(component.value);
        },
      if (currentOnChanged != null && enabled)
        'keydown': EventHandlers.createKeyboardEventHandler((event) {
          final key = event.key;
          if (key == ' ' || key == 'Enter') {
            event.preventDefault();
            currentOnChanged(component.value);
          }
        }),
      // Mirror W3C `:focus-visible`: ring on iff focus arrived via
      // keyboard. Forward to the surrounding [FocusOutline]. Also
      // auto-select on keyboard focus, matching the Flutter widget's
      // `onShowFocusHighlight` callback (Tab-to-radio activates it).
      //
      // Typed handler via `EventHandlers.createInputTargetEventHandler`:
      // dart2js release minifies dynamic getter dispatches (e.g.
      // `event.target` → `event.gdE`) into mangled names that
      // compile-graph changes can desync, leaving the ring stuck in its
      // unfocused state in production. Routing the cast through the
      // helper keeps the call site mangling-resilient.
      'focus': EventHandlers.createInputTargetEventHandler((_, target) {
        final isVisible = target.matches(':focus-visible');
        if (isVisible &&
            enabled &&
            currentOnChanged != null &&
            component.value != groupValue) {
          currentOnChanged(component.value);
        }
        setState(() => _focused = isVisible);
      }),
      'blur': (_) => setState(() => _focused = false),
    };
  }

  @override
  Component build(BuildContext context) {
    // Inside a [RadioGroup] the radio reads the group — what an `options`
    // item is handed and a `child` radio would otherwise have to restate.
    // A value the caller passes still wins, except the variant and size:
    // the group's decide them — the Flutter radio reads them the same way.
    final scope = _RadioGroupScope.maybeOf(context);
    final groupValue = component.groupValue ?? scope?.value;
    final currentOnChanged = component.onChanged ?? scope?.onChanged;
    final enabled = component.enabled && (scope?.enabled ?? true);
    final variant = scope?.variant ?? component.groupVariant;
    final size = scope?.size ?? component.groupSize;
    final name = component.name ?? scope?.name;

    final isSelected = component.value == groupValue;
    // A semantic identifier, not a resolved value: the card draws the same
    // row inside a tile and moves the state layer and the focus ring onto it.
    final isCard = variant == CoreRadioGroupVariant.card;
    final currentDescription = component.description;
    final events = _buildEvents(
      currentOnChanged: currentOnChanged,
      enabled: enabled,
      groupValue: groupValue,
    );

    // Standalone usage falls back to a per-item resolution that runs
    // the group resolver under the hood so [resolveRadioOption]
    // always receives a fully-merged [ResolvedRadioGroup].
    final group =
        component.group ??
        scope?.group ??
        resolveRadioGroup(
          context,
          variant: variant,
          size: size,
          orientation: .vertical,
        );

    final resolved = resolveRadioOption(
      context,
      group: group,
      variant: variant,
      size: size,
      isSelected: isSelected,
      enabled: enabled,
      hasDescription: currentDescription != null,
    );
    final stateLayerRules = resolveRadioRules(
      context,
      group: group,
      enabled: enabled,
    );

    // The halo sits first so it paints under the dot.
    final halo = Component.element(
      tag: 'div',
      classes: resolved.halo.className,
      styles: resolved.halo.inlineStyles,
    );
    final innerDot = Component.element(
      tag: 'div',
      classes: resolved.dot.className,
      styles: resolved.dot.inlineStyles,
    );
    // `<style>` is `display: none` — never joins a flex row. Only an
    // enabled radio wears the scope class the selectors inside target.
    final stateLayerStyle = stateLayerRules.css.isNotEmpty
        ? Component.element(
            tag: 'style',
            children: [RawText(stateLayerRules.css)],
          )
        : null;

    // When the radio has no surrounding `<label>` wrapper, the radio
    // circle itself is the component root, so caller chrome (id / classes
    // / css / attributes / events) passes through onto it; otherwise the
    // `<label>` root below carries the passthrough.
    final hasWrapper =
        isCard ||
        component.label != null ||
        currentDescription != null ||
        name != null ||
        component.prefix != null ||
        component.suffix != null;

    // The scope class rides the ROOT — the whole row is the hit area, so
    // a pointer on the label raises the halo around the circle.
    final buttonClassName = hasWrapper
        ? resolved.button.className
        : '${resolved.button.className} ${stateLayerRules.scopeClass}';
    final radioCircle = Component.element(
      tag: 'div',
      id: hasWrapper ? null : component.id,
      classes: hasWrapper
          ? buttonClassName
          : component.rootClasses(buttonClassName),
      styles: hasWrapper
          ? resolved.button.inlineStyles
          : (component.css != null
                ? Styles.combine([
                    ?resolved.button.inlineStyles,
                    component.css!,
                  ])
                : resolved.button.inlineStyles),
      attributes: {
        if (!hasWrapper) ...component.componentAttributes,
        'role': 'radio',
        'aria-checked': isSelected ? 'true' : 'false',
        if (!enabled) 'aria-disabled': 'true',
        // Roving tab stop (native radio-group convention): only the
        // selected radio is reachable with Tab — with no selection
        // yet, every radio stays reachable. Arrow keys on the group
        // root move focus between siblings; selection follows focus
        // via the keyboard-focus auto-select above. A radio outside a
        // group has no arrow keys to reach its siblings with, so each
        // one keeps its own tab stop.
        'tabindex':
            enabled && (scope == null || isSelected || groupValue == null)
            ? '0'
            : '-1',
      },
      events: {
        if (!hasWrapper) ...component.events,
        ...events,
      },
      children: [
        if (!hasWrapper) ?stateLayerStyle,
        // A card's state layer is the tile's, not a halo around the circle.
        if (!isCard) halo,
        innerDot,
      ],
    );

    // Wrap with FocusOutline — circular shape since the radio is a circle.
    // A card rings the tile instead, so its circle goes bare.
    final ringedRadio = isCard
        ? radioCircle
        : FocusOutline(
            focused: _focused && isSelected,
            shape: .circle,
            child: radioCircle,
          );

    // Hidden input for form submission.
    final hiddenInput = name != null
        ? Component.element(
            tag: 'input',
            attributes: {
              'type': 'radio',
              'name': name,
              'value': component.value,
              if (isSelected) 'checked': '',
              'class': 'sr-only',
              'tabindex': '-1',
              'aria-hidden': 'true',
            },
          )
        : null;

    final currentLabel = component.label;

    if (!hasWrapper) {
      return ringedRadio;
    }

    // Indicator↔label gap rendered as explicit Gap widgets on either
    // side of the indicator — mirrors the Flutter widget. Gap runs its
    // own resolve / scaling step against the nested CoreGapStyle slot
    // forwarded on the resolved bundle.
    final gap = Gap(gapStyle: resolved.indicatorLabelGapStyle);

    final labelText = currentLabel != null
        ? Text(
            currentLabel,
            maxLines: component.labelMaxLines,
            overflow: component.labelOverflow,
          )
        : null;
    // The label slot and the description stack in one column — Checkbox's
    // shape, and the Flutter twin's `Column(label slot, Gap, description)`.
    // The label slot is whatever the plain row puts after the indicator:
    // the label, the suffix, or both side by side. Built only when a
    // description is present, so a labelled radio without one has no extra
    // wrapper and keeps the suffix as a row sibling.
    final suffix = component.suffix;
    final Component? labelSlot;
    if (labelText != null && suffix != null) {
      labelSlot = Component.element(
        tag: 'span',
        classes: resolved.labelLine.className,
        children: [labelText, suffix],
      );
    } else {
      labelSlot = labelText ?? suffix;
    }
    final labelContent = currentDescription != null
        ? Component.element(
            tag: 'span',
            classes: resolved.content.className,
            children: [
              ?labelSlot,
              if (labelSlot != null)
                Gap(gapStyle: resolved.labelDescriptionGapStyle),
              Component.element(
                tag: 'span',
                classes: resolved.description.className,
                styles: resolved.description.inlineStyles,
                children: [Text(currentDescription)],
              ),
            ],
          )
        : labelText;

    final rowChildren = [
      ?component.prefix,
      if (component.prefix != null) gap,
      ringedRadio,
      if (labelContent != null || suffix != null) gap,
      ?labelContent,
      // With a description the suffix already sits in the column above.
      if (currentDescription == null) ?suffix,
    ];

    final root = Component.element(
      tag: 'label',
      id: component.id,
      classes: component.rootClasses(
        '${resolved.root.className} ${stateLayerRules.scopeClass}',
      ),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      // Clicking the label triggers onChanged just like the radioCircle —
      // matches native `<label>` ↔ `<input>` association.
      events: {...component.events, ...events},
      children: isCard
          ? [
              ?stateLayerStyle,
              ?hiddenInput,
              // First, so the positioned row after it paints over it — the
              // layer washes the face, not the text.
              Component.element(
                tag: 'div',
                classes: resolved.tileStateLayer.className,
                styles: resolved.tileStateLayer.inlineStyles,
              ),
              Component.element(
                tag: 'span',
                classes: resolved.tileBody.className,
                children: rowChildren,
              ),
            ]
          : [?stateLayerStyle, ?hiddenInput, ...rowChildren],
    );

    if (!isCard) return root;

    // The ring goes around the tile, following its corner — the focus
    // stays on the circle (`role="radio"`), so `_focused` still gates it.
    return FocusOutline(
      focused: _focused && isSelected,
      focusOutlineStyle: resolved.tileFocusOutlineStyle,
      child: root,
    );
  }
}

/// Chain sugar mirroring the Flutter `RadioGroup.withStyle` extension —
/// merges a [CoreRadioGroupStyle] patch into [RadioGroup.radioGroupStyle]
/// via the existing [RadioGroup.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreRadioGroupStyle.merge` right-side-wins semantics).
extension RadioGroupStyleChain on RadioGroup {
  /// Returns a copy of this [RadioGroup] with [patch] merged into
  /// [radioGroupStyle] (patch fields win on conflict).
  RadioGroup withStyle(CoreRadioGroupStyle patch) => copyWith(
    radioGroupStyle: (radioGroupStyle ?? const CoreRadioGroupStyle()).merge(
      patch,
    ),
  );
}
