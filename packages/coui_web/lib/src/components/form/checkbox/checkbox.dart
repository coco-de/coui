import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/form/checkbox/checkbox_style.dart';
import 'package:coui_web/src/components/form/form/form_controller.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' hide Text;

/// Unified cross-platform checkbox for CoUI Web with token-based rendering.
///
/// The value is Flutter's tristate `bool?` — [checked] is `true` / `false`
/// / `null` for indeterminate — and [onChanged] receives the next value.
/// The semantic `size` stays a widget parameter (it identifies the checkbox
/// instance) while all chrome / dimensional / nested-slot overrides flow
/// through the single [checkboxStyle] (a [CoreCheckboxStyle]).
///
/// Uses custom `<div>` rendering (not native `<input type="checkbox">`) to
/// achieve visual parity with Flutter Checkbox. Both platforms share the
/// same design tokens from [CoreCheckboxStyle]'s flat defaults and
/// [CoreCheckboxStyle.defaultsBySize].
///
/// Hover / pressed / focus are DETECTION — the browser's `:hover` /
/// `:active` / `:focus-visible` on the composed `Clickable` root — and the
/// chrome for each (the halo, the ring around the box) rides scoped rules
/// the resolver emits.
///
/// When placed inside a [Form] with a [FormController] (via a `FormField`),
/// the checkbox reports its [checked] value through [FormValueSupplier] so
/// the form tracks and validates it — matching Flutter `Checkbox`.
///
/// Example:
/// ```dart
/// Checkbox(
///   checked: true,
///   label: 'Accept terms',
///   onChanged: (value) => print('Checked: $value'),
/// )
/// ```
///
/// surface:content — a control box that sits in the flow, not something
/// mounted over content.
class Checkbox extends UiStatefulComponent
    implements
        CoreCheckboxContract<
          Component,
          CoreFocusNode,
          CoreStatesController,
          Object
        > {
  /// Creates a [Checkbox].
  const Checkbox({
    super.key,
    this.checked = false,
    this.onChanged,
    this.enabled,
    this.tristate = false,
    this.prefix,
    this.suffix,
    this.label,
    this.labelMaxLines,
    this.labelOverflow,
    this.description,
    this.trailing,
    this.size = CoreComponentSize.md,
    this.checkboxStyle,
    this.name,
    super.id,
  });

  // === Value ===

  @override
  final bool? checked;

  @override
  final CoreValueChanged<bool?>? onChanged;

  /// Whether the checkbox is enabled. `null` (the default) falls back to
  /// `onChanged != null` so a checkbox with no callback reads as disabled —
  /// matching the Flutter `Checkbox._enabled` getter (Flutter is the
  /// cross-platform reference). Pass `true`/`false` to force it.
  @override
  final bool? enabled;

  /// Effective interactive state — explicit [enabled] wins, else the
  /// presence of an [onChanged] callback decides (Flutter parity).
  bool get _effectiveEnabled => enabled ?? (onChanged != null);

  @override
  final bool tristate;

  // === Content ===

  @override
  final Component? prefix;

  @override
  final Component? suffix;

  @override
  final String? label;

  @override
  final int? labelMaxLines;

  @override
  final CoreTextOverflow? labelOverflow;

  @override
  final String? description;

  @override
  final Component? trailing;

  // === Semantic identity (widget params, not chrome) ===

  @override
  final CoreComponentSize size;

  // === Style (chrome / dimensional / nested slot) ===

  @override
  final CoreCheckboxStyle? checkboxStyle;

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

  // === Public overrides ===

  /// Returns a copy of this checkbox with the given fields replaced.
  ///
  /// [checked] is tristate, so `null` cannot mean "keep mine" — pass
  /// [checkedProvided] `true` to set it (to any of the three values).
  Checkbox copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    bool? checked,
    bool checkedProvided = false,
    CoreValueChanged<bool?>? onChanged,
    bool? enabled,
    bool? tristate,
    Component? prefix,
    Component? suffix,
    String? label,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    String? description,
    Component? trailing,
    CoreComponentSize? size,
    CoreCheckboxStyle? checkboxStyle,
    String? name,
  }) {
    return Checkbox(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      checked: checkedProvided ? checked : this.checked,
      enabled: enabled ?? this.enabled,
      tristate: tristate ?? this.tristate,
      prefix: prefix ?? this.prefix,
      suffix: suffix ?? this.suffix,
      label: label ?? this.label,
      labelMaxLines: labelMaxLines ?? this.labelMaxLines,
      labelOverflow: labelOverflow ?? this.labelOverflow,
      description: description ?? this.description,
      trailing: trailing ?? this.trailing,
      size: size ?? this.size,
      checkboxStyle: checkboxStyle ?? this.checkboxStyle,
      name: name ?? this.name,
      id: id ?? this.id,
    );
  }

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    attributes.add('role', 'checkbox');
    attributes.add(
      'aria-checked',
      switch (checked) {
        null => 'mixed',
        true => 'true',
        false => 'false',
      },
    );
    if (!_effectiveEnabled) {
      attributes.add('aria-disabled', 'true');
    }
    attributes.add('tabindex', _effectiveEnabled ? '0' : '-1');
  }

  @override
  State<Checkbox> createState() => _CheckboxState();
}

/// Chain sugar mirroring the Flutter `Checkbox.withStyle` extension —
/// merges a [CoreCheckboxStyle] patch into [Checkbox.checkboxStyle] via
/// the existing [Checkbox.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreCheckboxStyle.merge` right-side-wins semantics).
extension CheckboxStyleChain on Checkbox {
  /// Returns a copy of this [Checkbox] with [patch] merged into
  /// [checkboxStyle] (patch fields win on conflict).
  Checkbox withStyle(CoreCheckboxStyle patch) => copyWith(
    checkboxStyle: (checkboxStyle ?? const CoreCheckboxStyle()).merge(patch),
  );
}

class _CheckboxState extends State<Checkbox>
    with FormValueSupplier<bool?, Checkbox> {
  @override
  void initState() {
    super.initState();
    formValue = component.checked;
  }

  bool? _nextChecked() {
    if (component.tristate) {
      // true → false → null (indeterminate) → true.
      return switch (component.checked) {
        true => false,
        false => null,
        null => true,
      };
    }
    return !(component.checked ?? false);
  }

  @override
  void didUpdateComponent(covariant Checkbox oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (component.checked != oldComponent.checked) {
      formValue = component.checked;
    }
  }

  @override
  void didReplaceFormValue(bool? value) {
    component.onChanged?.call(value);
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveCheckbox(
      context,
      size: component.size,
      checked: component.checked,
      enabled: component._effectiveEnabled,
      hasDescription: component.description != null,
      checkboxStyle: component.checkboxStyle,
    );
    // The halo + ring ride scoped rules keyed on the `Clickable` root's
    // pseudo-classes. Re-walks the same chain, so the box the rules
    // target is the box the chrome above drew.
    final rules = resolveCheckboxRules(
      context,
      enabled: component._effectiveEnabled,
      checkboxStyle: component.checkboxStyle,
    );

    final checked = component.checked;
    final isChecked = checked ?? false;
    final isIndet = checked == null;

    // Both glyphs always mounted so the CSS transition
    // (`scale-0 ↔ scale-100`) animates between values instead of
    // jumping when the element first appears.
    final checkIcon = Component.element(
      tag: 'span',
      classes: resolved.checkGlyph.className,
      styles: resolved.checkGlyph.inlineStyles,
      children: [
        Icon(
          LucideIcons.check,
          iconStyle: resolved.checkmarkIconStyle,
        ),
      ],
    );

    final indeterminateIcon = Component.element(
      tag: 'span',
      classes: resolved.indeterminateGlyph.className,
      styles: resolved.indeterminateGlyph.inlineStyles,
      children: [
        Component.element(
          tag: 'div',
          classes: resolved.indicator.className,
          styles: resolved.indicator.inlineStyles,
        ),
      ],
    );

    // Wrap in a fragment-equivalent: a single span carrying no own
    // styles, just hosting the two stacked glyphs. The parent box is
    // already `relative`, so the inner `absolute inset-0` glyphs
    // anchor to it.
    final innerIcon = Component.element(
      tag: 'span',
      classes: resolved.glyphStack.className,
      styles: resolved.glyphStack.inlineStyles,
      children: [checkIcon, indeterminateIcon],
    );

    // Pure visual chrome. The `Clickable` root below owns `id`, the
    // checkbox role, its `aria-*` state and `tabindex` — putting them
    // here too gave the document two elements with the same id and two
    // nested `role=checkbox` stops, so a screen reader announced one
    // control twice and the second Tab stop did nothing. The box is the
    // same element the Flutter twin wraps in `FocusOutline`; that is a
    // paint relationship, not an accessibility one.
    final checkboxSquare = Component.element(
      tag: 'div',
      classes: resolved.box.className,
      styles: resolved.box.inlineStyles,
      children: [innerIcon],
    );

    // Hidden input for form submission.
    final name = component.name;
    final hiddenInput = name != null
        ? Component.element(
            tag: 'input',
            attributes: {
              'type': 'checkbox',
              'name': name,
              if (isChecked) 'checked': '',
              if (isIndet) 'data-indeterminate': 'true',
              'class': 'sr-only',
              'tabindex': '-1',
              'aria-hidden': 'true',
            },
          )
        : null;

    final currentLabel = component.label;

    // Indicator↔label gap rendered as an explicit `Gap` child between
    // the checkbox square and the prefix / suffix / label siblings —
    // mirrors the Flutter widget (`Row` + `Gap`), so the gap slot
    // flows through a single nested-resolve path on both platforms.
    final indicatorLabelGap = Gap(
      gapStyle: resolved.indicatorLabelGapStyle,
    );
    final currentDescription = component.description;
    final hasTrailingContent =
        component.suffix != null ||
        currentLabel != null ||
        currentDescription != null;

    final currentOnChanged = component.onChanged;

    // Flutter twin: `Clickable(child: Row(prefix, box, label))` —
    // Clickable owns tap / keyboard activation / cursor / press-shrink
    // / disabled opacity; the content wrapper below is pure content.
    // The ring is NOT the Clickable's (`focusOutline: false`) — it hugs
    // the box through the scoped rules, the way the Flutter twin wraps
    // the box (not the row) in `FocusOutline`. The wrapper is a `<span>`,
    // not a `<label>`: a label would forward clicks to the hidden input
    // as a second click event that bubbles back through the Clickable
    // (double toggle), and the accessible name already comes from the
    // role="checkbox" root's contents.
    return Clickable(
      onPressed: component._effectiveEnabled && currentOnChanged != null
          ? () => currentOnChanged(_nextChecked())
          : null,
      onClick: component.onClick,
      attributes: component.componentAttributes,
      // The scope class rides the Clickable root — that is where
      // `:hover` / `:active` / `:focus-visible` land; the rules reach the
      // box with a descendant combinator.
      classes: [
        ?component.classes,
        if (rules.scopeClass.isNotEmpty) rules.scopeClass,
      ].join(' '),
      css: component.css,
      eventHandlers: component.eventHandlers,
      id: component.id,
      onChange: component.onChange,
      onInput: component.onInput,
      onKeyDown: component.onKeyDown,
      onKeyUp: component.onKeyUp,
      onMouseEnter: component.onMouseEnter,
      onMouseLeave: component.onMouseLeave,
      // Effective enabled drives the whole interaction surface —
      // not-allowed cursor, no focus, no activation. The generic
      // disabled fade stays off via the nested clickableStyle slot
      // (the checkbox paints its own disabled tokens).
      enabled: component._effectiveEnabled,
      enableFeedback: component._effectiveEnabled,
      focusOutline: false,
      clickableStyle: resolved.clickableStyle,
      child: Component.element(
        tag: 'span',
        classes: resolved.root.className,
        styles: resolved.root.inlineStyles,
        children: [
          // `<style>` is `display: none` — never joins the flex row.
          if (rules.css.isNotEmpty)
            Component.element(
              tag: 'style',
              children: [RawText(rules.css)],
            ),
          ?hiddenInput,
          ?component.prefix,
          if (component.prefix != null) indicatorLabelGap,
          checkboxSquare,
          if (hasTrailingContent) indicatorLabelGap,
          ?component.suffix,
          if (currentLabel != null || currentDescription != null)
            Component.element(
              tag: 'span',
              classes: resolved.labelWrapper.className,
              children: [
                if (currentLabel != null)
                  Text(
                    currentLabel,
                    maxLines: component.labelMaxLines,
                    overflow: component.labelOverflow,
                  ),
                // The label↔description gap is an explicit `Gap` child
                // rather than a `gap-*` class on the wrapper, matching
                // the Flutter twin's `Column` + `Gap` so the slot runs
                // one nested-resolve path on both platforms.
                if (currentLabel != null && currentDescription != null)
                  Gap(gapStyle: resolved.labelDescriptionGapStyle),
                if (currentDescription != null)
                  Component.element(
                    tag: 'span',
                    classes: resolved.description.className,
                    styles: resolved.description.inlineStyles,
                    children: [Text(currentDescription)],
                  ),
              ],
            ),
          if (component.trailing != null) ...[
            indicatorLabelGap,
            component.trailing!,
          ],
        ],
      ),
    );
  }
}
