/// Unified cross-platform `Select` dropdown for CoUI Web.
///
/// Built on top of the unified [Popover] so placement, collision,
/// outside-tap dismissal, and scroll-close come from a single source
/// of truth shared with every other popover-backed component (Tooltip,
/// HoverCard, DatePicker, …). The parameter surface mirrors
/// `coui_flutter`'s `Select`.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/roving_focus.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/form/form/form_controller.dart';
import 'package:coui_web/src/components/form/form_field/form_field_scope.dart';
import 'package:coui_web/src/components/form/select/select_style.dart';
import 'package:coui_web/src/components/form/text_field/text_field.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/menu/menu_item/menu_item.dart';
import 'package:coui_web/src/components/overlay/popover/popover.dart';
import 'package:coui_web/src/components/overlay/popover/popover_controller.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:universal_web/web.dart' as web;

/// Unified cross-platform dropdown select.
///
/// Per Epic #1302 원칙 6/7, semantic enums (`size`) and behaviour
/// (`popoverPlacement` / `popoverCollision` / `closeOnScroll`) stay flat
/// on the component. All chrome / dimensional / nested-slot overrides
/// flow through the single [selectStyle] (a [CoreSelectStyle]) so the
/// nested-merge chain works uniformly:
///
/// ```text
/// design system default for select
///   → CoreSelectTheme.style
///   → parent component slot override
///   → component.selectStyle
/// ```
///
/// Example:
/// ```dart
/// Select(
///   items: [
///     CoreSelectItem(value: 'apple', label: 'Apple'),
///     CoreSelectItem(value: 'banana', label: 'Banana'),
///   ],
///   value: _value,
///   onChanged: (v) => setState(() => _value = v),
///   selectStyle: CoreSelectStyle(
///     optionsPanelMaxHeight: 320,
///     popoverStyle: CorePopoverStyle(
///       panelStyle: CorePopupStyle(
///         borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
///       ),
///     ),
///   ),
/// )
/// ```
///
/// surface:functional — the option list is a `Popover`, anchored over the
/// page.
class Select<T> extends UiStatefulComponent
    implements
        CoreSelectContract<Component, T>,
        CoreSelectPopoverWidthContract {
  /// Creates a [Select].
  const Select({
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
    this.value,
    this.placeholder,
    this.variant = CoreSelectVariant.defaultSelectVariant,
    this.size = CoreSelectSize.defaultSize,
    this.label,
    this.labelMaxLines,
    this.labelOverflow,
    this.description,
    this.errorText,
    this.required = false,
    this.enabled = true,
    this.onChanged,
    this.popoverPlacement = CorePopoverStyle.defaultDropdownPlacement,
    this.popoverCollision = CorePopoverStyle.defaultCollision,
    this.popoverWidthConstraint = CorePopoverConstraint.anchorFixedSize,
    this.closeOnScroll = CorePopoverStyle.defaultCloseOnScroll,
    this.suffix,
    this.selectStyle,
  });

  // === Data ===

  @override
  final List<CoreSelectItem<T>> items;

  @override
  final T? value;

  @override
  final String? placeholder;

  // === Field surface ===

  @override
  final CoreSelectVariant variant;

  @override
  final CoreSelectSize size;

  @override
  final String? label;

  @override
  final int? labelMaxLines;

  @override
  final CoreTextOverflow? labelOverflow;

  @override
  final String? description;

  @override
  final String? errorText;

  @override
  final bool required;

  // === Behaviour ===

  @override
  final bool enabled;

  @override
  final void Function(T value)? onChanged;

  // === Popover behaviour ===

  @override
  final CorePopoverPlacement popoverPlacement;

  @override
  final Set<CorePopoverCollision> popoverCollision;

  @override
  final CorePopoverConstraint popoverWidthConstraint;

  /// Whether scrolling a trigger ancestor or the viewport closes the menu.
  /// Defaults to true; menu and unrelated list scrolling do not close it.
  @override
  final bool closeOnScroll;

  // === Style ===

  @override
  final CoreSelectStyle? selectStyle;

  @override
  final Component? suffix;

  /// Returns a copy of this [Select] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Select<T> copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    void Function(T value)? onChanged,
    List<CoreSelectItem<T>>? items,
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
    T? value,
    String? placeholder,
    CoreSelectVariant? variant,
    CoreSelectSize? size,
    String? label,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    String? description,
    String? errorText,
    bool? required,
    bool? enabled,
    CorePopoverPlacement? popoverPlacement,
    Set<CorePopoverCollision>? popoverCollision,
    CorePopoverConstraint? popoverWidthConstraint,
    bool? closeOnScroll,
    Component? suffix,
    CoreSelectStyle? selectStyle,
  }) {
    return Select(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      onChanged: onChanged ?? this.onChanged,
      items: items ?? this.items,
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
      value: value ?? this.value,
      placeholder: placeholder ?? this.placeholder,
      variant: variant ?? this.variant,
      size: size ?? this.size,
      label: label ?? this.label,
      labelMaxLines: labelMaxLines ?? this.labelMaxLines,
      labelOverflow: labelOverflow ?? this.labelOverflow,
      description: description ?? this.description,
      errorText: errorText ?? this.errorText,
      required: required ?? this.required,
      enabled: enabled ?? this.enabled,
      popoverPlacement: popoverPlacement ?? this.popoverPlacement,
      popoverCollision: popoverCollision ?? this.popoverCollision,
      popoverWidthConstraint:
          popoverWidthConstraint ?? this.popoverWidthConstraint,
      closeOnScroll: closeOnScroll ?? this.closeOnScroll,
      suffix: suffix ?? this.suffix,
      selectStyle: selectStyle ?? this.selectStyle,
    );
  }

  @override
  State<Select<T>> createState() => _SelectState<T>();
}

/// Chain sugar mirroring the Flutter `Select.withStyle` extension —
/// merges a [CoreSelectStyle] patch into [Select.selectStyle] via the
/// existing [Select.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreSelectStyle.merge` right-side-wins semantics).
extension SelectStyleChain<T> on Select<T> {
  /// Returns a copy of this [Select] with [patch] merged into
  /// [selectStyle] (patch fields win on conflict).
  Select<T> withStyle(CoreSelectStyle patch) => copyWith(
    selectStyle: (selectStyle ?? const CoreSelectStyle()).merge(patch),
  );
}

class _SelectState<T> extends State<Select<T>> {
  final _popover = PopoverController();
  T? _value;

  /// Which row the keyboard is on while the panel is open. `-1` before
  /// the first move — the selected row, if any, is where it starts.
  int _highlighted = -1;

  final _typeahead = RovingTypeahead();

  late final String _scopeId =
      'co-select-${identityHashCode(this).toRadixString(36)}';

  @override
  void initState() {
    super.initState();
    _value = component.value;
    _popover.addListener(_handlePopoverChanged);
  }

  @override
  void didUpdateComponent(covariant Select<T> oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.value != component.value) _value = component.value;
  }

  @override
  void dispose() {
    _popover
      ..removeListener(_handlePopoverChanged)
      ..dispose();
    super.dispose();
  }

  void _handleToggle() {
    if (!component.enabled) return;
    if (_popover.isOpen) {
      _popover.close();
    } else {
      _popover.show();
    }
  }

  void _handlePopoverChanged() {
    // Opening starts the keyboard on the current value, so the first
    // arrow press steps from what is selected rather than from the top.
    // Closing re-renders too — however the panel closed (Escape, an
    // outside click, a pick): the trigger's `aria-expanded` and
    // `aria-activedescendant` are read at build time, and without a render
    // the combobox keeps announcing an open list and naming an option that
    // is no longer in the document.
    setState(() => _highlighted = _popover.isOpen ? _selectedIndex : -1);
  }

  List<CoreSelectItem<T>> get _selectable =>
      component.items.where((item) => item.enabled).toList(growable: false);

  int get _selectedIndex {
    final v = _value;
    if (v == null) return -1;
    final rows = _selectable;
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].value == v) return i;
    }
    return -1;
  }

  String? get _selectedLabel {
    final v = _value;
    if (v == null) return null;
    for (final o in component.items) {
      if (o.value == v) return o.label;
    }
    return null;
  }

  String _optionId(int index) => '$_scopeId-option-$index';

  void _handleSelect(CoreSelectItem<T> option) {
    if (!option.enabled) return;
    setState(() => _value = option.value);
    component.onChanged?.call(option.value);
    _popover.close();
  }

  /// Selecting while the panel is closed — the value moves, the panel
  /// stays shut. The platform behaviour a native select has.
  void _selectClosed(CoreSelectItem<T> option) {
    setState(() => _value = option.value);
    component.onChanged?.call(option.value);
  }

  void _move(int delta) {
    final rows = _selectable;
    if (rows.isEmpty) return;
    if (!_popover.isOpen) {
      final next = (_selectedIndex < 0 ? 0 : _selectedIndex + delta).clamp(
        0,
        rows.length - 1,
      );
      _selectClosed(rows[next]);
      return;
    }
    final from = _highlighted < 0 ? _selectedIndex : _highlighted;
    final next = (from + delta) % rows.length;
    setState(() => _highlighted = next < 0 ? next + rows.length : next);
  }

  void _jump(int index) {
    final rows = _selectable;
    if (rows.isEmpty) return;
    if (!_popover.isOpen) {
      _selectClosed(rows[index.clamp(0, rows.length - 1)]);
      return;
    }
    setState(() => _highlighted = index.clamp(0, rows.length - 1));
  }

  /// Typeahead moves the cursor to the next row whose label starts with
  /// what was typed. It does not filter — that is `Autocomplete`, and
  /// `aria-autocomplete="none"` on the trigger says so.
  void _typeaheadTo(String character) {
    final rows = _selectable;
    if (rows.isEmpty) return;
    final from = _popover.isOpen
        ? (_highlighted < 0 ? _selectedIndex : _highlighted)
        : _selectedIndex;
    final index = _typeahead.next(
      character,
      labels: [for (final row in rows) row.label],
      current: from,
    );
    if (index == null) return;
    if (_popover.isOpen) {
      setState(() => _highlighted = index);
    } else {
      _selectClosed(rows[index]);
    }
  }

  void _handleKeyDown(web.KeyboardEvent event) {
    if (!component.enabled) return;
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        if (!_popover.isOpen && event.altKey) {
          _popover.show();
        } else {
          _move(1);
        }
      case 'ArrowUp':
        event.preventDefault();
        _move(-1);
      case 'Home':
        event.preventDefault();
        _jump(0);
      case 'End':
        event.preventDefault();
        _jump(_selectable.length - 1);
      case 'Enter' || ' ':
        event.preventDefault();
        if (!_popover.isOpen) {
          _popover.show();
        } else if (_highlighted >= 0 && _highlighted < _selectable.length) {
          _handleSelect(_selectable[_highlighted]);
        }
      case 'Escape':
        // The value is left alone and focus stays on the trigger — the
        // input never lost it; only the panel goes.
        if (_popover.isOpen) {
          event.preventDefault();
          _popover.close();
        }
      case 'Tab':
        // Tab closes and moves on: the panel is not a focus stop, so the
        // default is kept for the browser's traversal.
        if (_popover.isOpen) _popover.close();
      default:
        // A single printable character starts or extends a typeahead run;
        // modifier chords are shortcuts and belong to the page.
        if (isRovingTypeaheadKey(
          event.key,
          ctrl: event.ctrlKey,
          meta: event.metaKey,
          alt: event.altKey,
        )) {
          event.preventDefault();
          _typeaheadTo(event.key);
        }
    }
  }

  Component _buildPanel(ResolvedSelect resolved) {
    final rows = _selectable;
    final children = <Component>[];

    if (rows.isEmpty) {
      children.add(
        div(
          [Text(CouiLocalizations.of(context).selectEmpty)],
          classes: resolved.emptyState.className,
          styles: resolved.emptyState.inlineStyles,
        ),
      );
    } else {
      for (var i = 0; i < rows.length; i++) {
        final option = rows[i];
        final isSelected = option.value == _value;
        final custom = option.child;
        children.add(
          // The wrapper carries the role and the selected state: the
          // container states what its rows are, and `MenuItem` supplies
          // only the visual contract (Primer's model).
          div(
            [
              MenuItem(
                label: custom is Component ? custom : Text(option.label),
                size: component.size.toMenuItemSize(),
                // The mark is drawn on the selected row and its column is
                // reserved on every row, so the labels of a list keep one
                // start line whether or not a row carries a check.
                mark: isSelected ? const Icon(LucideIcons.check) : null,
                reserveMark: true,
                selected: isSelected,
                enabled: option.enabled,
                onPressed: () => _handleSelect(option),
                menuItemStyle: resolved.optionStyle,
                attributes: const {'role': 'presentation', 'tabindex': '-1'},
              ),
            ],
            id: _optionId(i),
            classes: resolved.option.className,
            attributes: {
              'role': CoreSemanticRole.option.ariaRole,
              'aria-selected': '$isSelected',
              if (i == _highlighted) 'data-highlighted': 'true',
            },
          ),
        );
      }
    }

    return div(
      children,
      id: '$_scopeId-listbox',
      classes: resolved.panel.className,
      styles: resolved.panel.inlineStyles,
      attributes: {
        'role': CoreSemanticRole.listBox.ariaRole,
        if (component.label != null) 'aria-label': component.label!,
      },
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveSelect(
      context,
      size: component.size,
      variant: component.variant,
      selectStyle: component.selectStyle,
      // The trigger field folds the ambient scope into its own `enabled`
      // (an enclosing `Fieldset(enabled: false)` wins); the colours Select
      // hands it must follow the same answer.
      enabled:
          component.enabled &&
          FormFieldScope.maybeOf(context)?.disabled != true,
    );
    final selectedLabel = _selectedLabel;

    // The trigger is the field. `readOnly` keeps the caret and the
    // keyboard away while leaving it focusable — a select's value is
    // chosen, not typed, and `aria-autocomplete="none"` states that
    // boundary to a screen reader (Radix's way of drawing it).
    // Part of this composite: walled off from the enclosing
    // `FormField`, which is shown the composite's own value.
    final trigger = FormFieldHandleScope.boundary(
      child: TextField(
        onKeyDown: _handleKeyDown,
        onTap: _handleToggle,
        value: selectedLabel ?? '',
        placeholder: component.placeholder == null
            ? null
            : Text(component.placeholder!),
        enabled: component.enabled,
        readOnly: true,
        showCursor: false,
        size: component.size.toComponentSize(),
        variant: component.variant.toTextFieldVariant(),
        textFieldStyle: resolved.triggerStyle,
        label: component.label,
        labelMaxLines: component.labelMaxLines,
        labelOverflow: component.labelOverflow,
        description: component.description,
        errorText: component.errorText,
        required: component.required,
        attributes: {
          'role': CoreSemanticRole.comboBox.ariaRole,
          'aria-expanded': '${_popover.isOpen}',
          'aria-haspopup': CoreSemanticRole.listBox.ariaRole,
          'aria-autocomplete': 'none',
          'aria-controls': '$_scopeId-listbox',
          if (_popover.isOpen && _highlighted >= 0)
            'aria-activedescendant': _optionId(_highlighted),
        },
        // A custom suffix is part of the box: a press on it focuses the
        // field and toggles through the box's own click, as one on the
        // chevron does.
        suffix:
            component.suffix ??
            Icon(
              LucideIcons.chevronDown,
              iconStyle: resolved.chevronIconStyle,
            ),
      ),
    );

    return Popover(
      onClick: component.onClick,
      trigger: trigger,
      content: _buildPanel(resolved),
      attributes: component.userAttributes,
      classes: component.classes,
      css: component.css,
      eventHandlers: component.eventHandlers,
      id: component.id,
      onChange: component.onChange,
      onInput: component.onInput,
      onKeyDown: component.onKeyDown,
      onKeyUp: component.onKeyUp,
      onMouseEnter: component.onMouseEnter,
      onMouseLeave: component.onMouseLeave,
      placement: component.popoverPlacement,
      controller: _popover,
      // Manual: the trigger toggles through its own `onTap`. Letting
      // `Popover` also detect the tap would double-toggle.
      openTrigger: .manual,
      collision: component.popoverCollision,
      closeOnScroll: component.closeOnScroll,
      // The panel is exactly as wide as the field it drops from.
      widthConstraint: component.popoverWidthConstraint,
      popoverStyle: resolved.popoverStyle,
    );
  }
}
