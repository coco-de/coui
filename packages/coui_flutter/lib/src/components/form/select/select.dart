import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/semantics.dart' show SemanticsService;
import 'package:flutter/services.dart'
    show
        HardwareKeyboard,
        KeyDownEvent,
        KeyEvent,
        KeyRepeatEvent,
        LogicalKeyboardKey;

/// How long a typeahead run stays open — a pause longer than this starts
/// a new search rather than extending the last one (the WAI-ARIA listbox
/// convention, and the interval the desktop platforms use).
const _kTypeaheadWindow = Duration(milliseconds: CoreDuration.slow);

/// Unified cross-platform dropdown select.
///
/// A select is a **form field** whose value is chosen from a list, and it
/// is built that way: the trigger is a read-only [TextField] with a
/// chevron in its suffix seat, the panel is a [Popover] the width of that
/// field, and every option row is a [MenuItem]. Six of the seven systems
/// surveyed model a select as a field rather than a button (Select 코드
/// 인계 통합본 2026-09-08 §0), and the reason shows in the surface: a
/// button contract has nowhere to put [errorText], [label], [required] or
/// `role="combobox"`.
///
/// Stacking a `md` `Select` under a `md` `TextField` puts their text on the
/// same line — the field ladder's 12px inset, not the button ladder's 16.
///
/// Chrome flows through the single [selectStyle]; semantic enums
/// ([variant] / [size]) and behaviour ([popoverPlacement] /
/// [popoverCollision] / [closeOnScroll]) stay flat on the widget.
///
/// ```dart
/// Select<String>(
///   items: const [
///     CoreSelectItem(value: 'apple', label: 'Apple'),
///     CoreSelectItem(value: 'banana', label: 'Banana'),
///   ],
///   label: 'Fruit',
///   value: _value,
///   onChanged: (v) => setState(() => _value = v),
/// )
/// ```
///
/// Typing moves the cursor; it does not filter. A select whose list the
/// user narrows by typing is an `Autocomplete`, and that boundary is the
/// one every reference system draws.
///
/// surface:functional — the option list is a `Popover`, anchored over the
/// page.
class Select<T> extends StatefulWidget
    implements CoreSelectContract<Widget, T>, CoreSelectPopoverWidthContract {
  /// Creates a [Select].
  const Select({
    required this.items,
    super.key,
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

  /// Whether scrolling a trigger ancestor closes the menu. Defaults to true;
  /// scrolling the menu's own options or an unrelated list does not close it.
  @override
  final bool closeOnScroll;

  // === Style ===

  @override
  final CoreSelectStyle? selectStyle;

  @override
  final Widget? suffix;

  /// Returns a copy of this [Select] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Select<T> copyWith({
    Key? key,
    void Function(T value)? onChanged,
    List<CoreSelectItem<T>>? items,
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
    Widget? suffix,
    CoreSelectStyle? selectStyle,
  }) {
    return Select(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      items: items ?? this.items,
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

class _SelectState<T> extends State<Select<T>> {
  final _popover = PopoverController();
  final _focusNode = FocusNode();
  T? _value;
  CoreFormFieldScope? _formFieldScope;

  bool get _effectiveEnabled =>
      widget.enabled && _formFieldScope?.disabled != true;

  /// Which row the keyboard is on while the panel is open. `-1` before
  /// the first move — the selected row, if any, is where it starts.
  int _highlighted = -1;

  String _typeahead = '';
  DateTime? _typeaheadAt;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
    _popover.addListener(_handlePopoverChanged);
  }

  @override
  void didUpdateWidget(covariant Select<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _value = widget.value;
    _closeWhenDisabled();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _formFieldScope = FormFieldScope.maybeOf(context);
    _closeWhenDisabled();
  }

  void _closeWhenDisabled() {
    if (_effectiveEnabled || !_popover.isOpen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_effectiveEnabled) _popover.close();
    });
  }

  @override
  void dispose() {
    _popover
      ..removeListener(_handlePopoverChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handlePopoverChanged() {
    if (!_popover.isOpen) return;
    // Opening starts the keyboard on the current value, so the first
    // arrow press steps from what is selected rather than from the top.
    _highlight(_selectedIndex);
  }

  /// Puts the keyboard cursor on [index] and says which row it landed on.
  ///
  /// The Web twin points the trigger at that row with
  /// `aria-activedescendant`, and a screen reader follows the pointer and
  /// reads the row. Flutter has no relation that points one node at
  /// another, and the row's own `selected` flag is already spoken for —
  /// it is the *value*, as `aria-selected` is on Web. So the cursor
  /// travels the one way left to it: the row's label is announced. `-1`
  /// (no row yet) moves nothing and says nothing, the same as Web omitting
  /// the attribute.
  void _highlight(int index) {
    setState(() => _highlighted = index);
    final rows = _selectable;
    if (index < 0 || index >= rows.length) return;
    if (!MediaQuery.supportsAnnounceOf(context)) return;
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        rows[index].label,
        Directionality.of(context),
      ),
    );
  }

  List<CoreSelectItem<T>> get _selectable =>
      widget.items.where((item) => item.enabled).toList(growable: false);

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
    for (final o in widget.items) {
      if (o.value == v) return o.label;
    }
    return null;
  }

  void _handleSelect(CoreSelectItem<T> option) {
    if (!_effectiveEnabled || !option.enabled) return;
    setState(() => _value = option.value);
    widget.onChanged?.call(option.value);
    _popover.close();
    _focusNode.requestFocus();
  }

  void _handleToggle() {
    if (!_effectiveEnabled) return;
    if (_popover.isOpen) {
      _popover.close();
    } else {
      _popover.show();
    }
  }

  void _move(int delta) {
    final rows = _selectable;
    if (rows.isEmpty) return;
    if (!_popover.isOpen) {
      // Closed, the arrows change the value directly — the platform
      // behaviour a native select has, and the one WAI-ARIA describes.
      final next = (_selectedIndex < 0 ? 0 : _selectedIndex + delta).clamp(
        0,
        rows.length - 1,
      );
      _handleSelectClosed(rows[next]);
      return;
    }
    final from = _highlighted < 0 ? _selectedIndex : _highlighted;
    final next = (from + delta) % rows.length;
    _highlight(next < 0 ? next + rows.length : next);
  }

  void _jump(int index) {
    final rows = _selectable;
    if (rows.isEmpty) return;
    if (!_popover.isOpen) {
      _handleSelectClosed(rows[index.clamp(0, rows.length - 1)]);
      return;
    }
    _highlight(index.clamp(0, rows.length - 1));
  }

  /// Selecting while the panel is closed — the value moves, the panel
  /// stays shut.
  void _handleSelectClosed(CoreSelectItem<T> option) {
    if (!_effectiveEnabled) return;
    setState(() => _value = option.value);
    widget.onChanged?.call(option.value);
  }

  /// Typeahead moves the cursor to the next row whose label starts with
  /// what was typed. It does not filter — that is `Autocomplete`.
  void _typeaheadTo(String character) {
    final rows = _selectable;
    if (rows.isEmpty) return;
    final now = DateTime.now();
    final expired =
        _typeaheadAt == null ||
        now.difference(_typeaheadAt!) > _kTypeaheadWindow;
    _typeahead = (expired ? '' : _typeahead) + character.toLowerCase();
    _typeaheadAt = now;

    final from = _popover.isOpen
        ? (_highlighted < 0 ? _selectedIndex : _highlighted)
        : _selectedIndex;
    for (var offset = 1; offset <= rows.length; offset++) {
      final index = (from + offset) % rows.length;
      if (rows[index].label.toLowerCase().startsWith(_typeahead)) {
        if (_popover.isOpen) {
          _highlight(index);
        } else {
          _handleSelectClosed(rows[index]);
        }
        return;
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return .ignored;
    }
    if (!_effectiveEnabled) return .ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      // Alt+Down opens without moving the value — the WAI-ARIA select
      // pattern's second opener, and the one a closed select needs so an
      // arrow can open it without also changing it.
      if (!_popover.isOpen && HardwareKeyboard.instance.isAltPressed) {
        _popover.show();
      } else {
        _move(1);
      }
      return .handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _move(-1);
      return .handled;
    }
    if (key == LogicalKeyboardKey.home) {
      _jump(0);
      return .handled;
    }
    if (key == LogicalKeyboardKey.end) {
      _jump(_selectable.length - 1);
      return .handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      if (!_popover.isOpen) {
        _popover.show();
      } else if (_highlighted >= 0 && _highlighted < _selectable.length) {
        _handleSelect(_selectable[_highlighted]);
      }
      return .handled;
    }
    if (key == LogicalKeyboardKey.escape && _popover.isOpen) {
      // The value is left alone and focus stays on the trigger — the
      // field never lost it; only the panel goes.
      _popover.close();
      return .handled;
    }
    if (key == LogicalKeyboardKey.tab) {
      // Tab closes and moves on: the panel is not a focus stop, so the
      // event is left unhandled for the traversal to take.
      if (_popover.isOpen) _popover.close();
      return .ignored;
    }
    final character = event.character;
    if (character != null &&
        character.length == 1 &&
        character.trim().isNotEmpty) {
      _typeaheadTo(character);
      return .handled;
    }
    return .ignored;
  }

  Widget _buildPanel(ResolvedSelect resolved) {
    final rows = _selectable;
    final content = rows.isEmpty
        ? Padding(
            padding: resolved.emptyStateInsets,
            child: DefaultTextStyle.merge(
              style: resolved.emptyStateTextStyle,
              child: Text(CoUILocalizations.of(context).selectEmpty),
            ),
          )
        : Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            spacing: resolved.optionSpacing,
            children: [
              for (var i = 0; i < rows.length; i++)
                _optionRow(resolved, rows[i], i),
            ],
          );

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: resolved.optionsPanelMaxHeight),
      // The row announces its own selected state; the panel is the
      // listbox. Flutter has no `listBox` / `option` role to state (both
      // are `CoreSemanticRole`'s `absent` rung), so what reaches a screen
      // reader here is the selection, which is the part that was missing.
      child: SingleChildScrollView(child: content),
    );
  }

  Widget _optionRow(ResolvedSelect resolved, CoreSelectItem<T> option, int i) {
    final selected = option.value == _value;
    final custom = option.child;
    return MenuRowScope(
      // The row is an `option`, not a `menuItem` — the container states
      // what its rows are (Primer's model), and `MenuItem` supplies only
      // the visual contract.
      rowRole: CoreSemanticRole.option,
      child: MenuItem(
        label: custom is Widget ? custom : Text(option.label),
        size: widget.size.toMenuItemSize(),
        // The mark is drawn on the selected row and its column is
        // reserved on every row, so the labels of a list keep one start
        // line whether or not a row carries a check.
        mark: selected ? const Icon(LucideIcons.check) : null,
        reserveMark: true,
        selected: selected,
        enabled: option.enabled,
        onPressed: () => _handleSelect(option),
        menuItemStyle: i == _highlighted
            // The keyboard cursor is not the selection: it says where
            // Enter would land. Drawn as the row's own hover wash so it
            // reads the same as pointing at the row.
            ? resolved.optionStyle.merge(
                CoreMenuItemStyle(
                  backgroundColor: CoreMenuItemStyle
                      .defaultsByTone[CoreMenuItemTone.neutral]!
                      .foregroundColor!
                      .scaleAlpha(CoreOpacity.hover),
                ),
              )
            : resolved.optionStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveSelect(
      context,
      size: widget.size,
      variant: widget.variant,
      selectStyle: widget.selectStyle,
      // The trigger field folds the ambient scope into its own `enabled`
      // (an enclosing `Fieldset(enabled: false)` wins); the colours Select
      // hands it must follow the same answer, or a scope-disabled select
      // keeps the enabled placeholder tint.
      enabled: _effectiveEnabled,
    );
    final selectedLabel = _selectedLabel;

    // The trigger is the field. `readOnly` keeps the caret and the
    // keyboard away while leaving it focusable and tappable — a select's
    // value is chosen, not typed.
    // Part of this composite: walled off from the enclosing
    // `FormField`, which is shown the composite's own value.
    final trigger = Data<FormFieldHandle>.boundary(
      child: TextField(
        onTap: _handleToggle,
        value: selectedLabel ?? '',
        placeholder: widget.placeholder == null
            ? null
            : Text(widget.placeholder!),
        enabled: widget.enabled,
        readOnly: true,
        showCursor: false,
        size: widget.size.toComponentSize(),
        variant: widget.variant.toTextFieldVariant(),
        textFieldStyle: resolved.triggerStyle,
        label: widget.label,
        labelMaxLines: widget.labelMaxLines,
        labelOverflow: widget.labelOverflow,
        description: widget.description,
        errorText: widget.errorText,
        required: widget.required,
        focusNode: _focusNode,
        suffix:
            widget.suffix ??
            Icon(LucideIcons.chevronDown, iconStyle: resolved.chevronIconStyle),
      ),
    );

    // The key handler sits ABOVE the field rather than owning its node:
    // the field already holds `_focusNode`, and handing the same node to
    // two `Focus` widgets makes one the parent of itself. An ancestor
    // that takes no focus of its own still sees the field's key events on
    // the way up, which is all this needs.
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _handleKeyEvent,
      child: Popover(
        trigger: trigger,
        content: _buildPanel(resolved),
        placement: widget.popoverPlacement,
        controller: _popover,
        // Manual: the trigger toggles through its own `onTap`. Letting
        // `Popover` also detect the tap would double-toggle.
        openTrigger: .manual,
        collision: widget.popoverCollision,
        closeOnScroll: widget.closeOnScroll,
        widthConstraint: widget.popoverWidthConstraint,
        popoverStyle: resolved.popoverStyle,
      ),
    );
  }
}

/// Chain sugar for merging a [CoreSelectStyle] patch into
/// [Select.selectStyle] without hand-reconstructing every field. Mirrors
/// the Web `Select.withStyle` extension so both platforms read
/// identically.
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
