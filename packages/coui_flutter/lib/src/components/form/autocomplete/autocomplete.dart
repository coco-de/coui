import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/services.dart'
    show KeyDownEvent, KeyEvent, KeyRepeatEvent;

/// Sentinel for "the keyboard is not pointing at any row".
///
/// Private: an internal cursor position, not something a caller sets.
const _kNoHighlight = -1;

/// Index of the first navigable row.
const _kFirstHighlight = 0;

/// Unified cross-platform autocomplete with token-based rendering.
///
/// `Autocomplete` is a self-contained text input that shows a filtered
/// suggestion dropdown. Typing filters the [suggestions] list
/// (case-insensitive `contains`); picking a suggestion applies it
/// according to [mode].
///
/// The suggestion dropdown is the composed unified `Popover`'s floating
/// panel (the [TextField] is the trigger), so it escapes ancestor
/// `overflow` / `transform` clipping and flips/shifts to stay inside the
/// viewport — identical to `Select`. All chrome / dimensional overrides
/// flow through the single [autocompleteStyle] (a
/// [CoreAutocompleteStyle]); the panel box chrome flows through
/// `autocompleteStyle.popoverStyle`.
///
/// Example:
/// ```dart
/// Autocomplete(
///   suggestions: ['Apple', 'Banana', 'Cherry'],
///   placeholder: 'Search fruits',
///   onSelected: (value) => print('Selected: $value'),
/// )
/// ```
///
/// surface:functional — the suggestion list is a `Popover`, anchored over
/// the field.
class Autocomplete extends StatefulWidget
    implements CoreAutocompleteContract<ValueChanged<String>?> {
  /// Creates a [Autocomplete].
  const Autocomplete({
    required this.suggestions,
    super.key,
    this.value,
    this.placeholder,
    this.enabled = true,
    this.required = false,
    this.name,
    this.mode = CoreAutocompleteMode.defaultMode,
    this.onChanged,
    this.onSelected,
    this.autocompleteStyle,
  });

  @override
  final List<String> suggestions;

  @override
  final String? value;

  @override
  final String? placeholder;

  @override
  final bool enabled;

  @override
  final bool required;

  @override
  final String? name;

  @override
  final CoreAutocompleteMode mode;

  @override
  final ValueChanged<String>? onChanged;

  @override
  final ValueChanged<String>? onSelected;

  @override
  final CoreAutocompleteStyle? autocompleteStyle;

  /// Returns a copy of this [Autocomplete] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Autocomplete copyWith({
    Key? key,
    ValueChanged<String>? onChanged,
    List<String>? suggestions,
    String? value,
    String? placeholder,
    bool? enabled,
    bool? required,
    String? name,
    CoreAutocompleteMode? mode,
    ValueChanged<String>? onSelected,
    CoreAutocompleteStyle? autocompleteStyle,
  }) {
    return Autocomplete(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      suggestions: suggestions ?? this.suggestions,
      value: value ?? this.value,
      placeholder: placeholder ?? this.placeholder,
      enabled: enabled ?? this.enabled,
      required: required ?? this.required,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      onSelected: onSelected ?? this.onSelected,
      autocompleteStyle: autocompleteStyle ?? this.autocompleteStyle,
    );
  }

  @override
  State<Autocomplete> createState() => _AutocompleteState();
}

class _AutocompleteState extends State<Autocomplete> {
  final _popover = PopoverController();
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  /// The suggestions the panel is currently showing.
  ///
  /// Recomputed from the live query *and* the live props, so the portaled
  /// panel tracks prop changes (async `suggestions` arriving late) rather
  /// than only text edits.
  late final ValueNotifier<List<String>> _visible;

  /// Blocks the *open* path of [_syncPopover] after a selection lands.
  ///
  /// Selecting fires `onChanged`, so a controlled parent recomputes props
  /// and we re-enter [didUpdateWidget] — with the field still focused and
  /// the completed text matching the chosen suggestion itself. Without
  /// this, the prop-driven re-sync would immediately reopen the panel the
  /// selection just closed. Cleared on the next keystroke or refocus,
  /// since both mean the user wants suggestions back.
  bool _suppressReopen = false;

  /// Index of the keyboard-highlighted row in [_visible], or `-1` for none.
  ///
  /// Separate from hover: a pointer and the keyboard can each point at a
  /// different row, and the keyboard's choice is the one Enter accepts.
  late final ValueNotifier<int> _highlight;

  String _currentValue = '';

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value ?? '';
    _controller = TextEditingController(text: _currentValue);
    _visible = ValueNotifier<List<String>>(_filteredFor(_query));
    _highlight = ValueNotifier<int>(_kNoHighlight);
    _focusNode.addListener(_handleFocusChanged);
  }

  List<String> _filteredFor(String raw) {
    final query = raw.trim().toLowerCase();
    if (query.isEmpty) return widget.suggestions;
    return widget.suggestions
        .where((s) => s.toLowerCase().contains(query))
        .toList();
  }

  /// The caret offset, always inside [_currentValue].
  ///
  /// A collapsed selection is the caret. A range selection, or the `-1`
  /// a controller reports before the field has been touched, falls back
  /// to the end of the text — where a fresh field's caret sits.
  int get _caret {
    final selection = _controller.selection;
    final offset = selection.isCollapsed ? selection.baseOffset : -1;
    if (offset < 0 || offset > _currentValue.length) {
      return _currentValue.length;
    }
    return offset;
  }

  /// The text the filter runs against.
  ///
  /// `replaceWord` completes the word under the caret, so that word is the
  /// query. Filtering on the whole field instead is what made the dropdown
  /// vanish the moment a second word was typed: `'I like App'` matched no
  /// suggestion, so nothing was offered.
  String get _query => widget.mode == CoreAutocompleteMode.replaceWord
      ? getWordAtCaret(_caret, _currentValue).$2
      : _currentValue;

  /// Refilters [_visible] from the live query and the live props.
  ///
  /// Every path that can change what the panel should list routes through
  /// here, so the open/close decision and the rendered rows always read
  /// the same list.
  void _recompute() {
    _visible.value = _filteredFor(_query);
    // A refilter invalidates the highlight: index 2 of the old list is a
    // different suggestion — or gone — in the new one, so Enter would
    // accept something the user never highlighted.
    _highlight.value = _kNoHighlight;
  }

  /// Moves the highlight by [delta] within a list of [count] rows, wrapping
  /// at both ends.
  void _moveHighlight(int delta, int count) {
    final current = _highlight.value;
    // From "nothing highlighted", down starts at the top and up at the
    // bottom — the same place a wrap would have landed.
    _highlight.value = current < _kFirstHighlight
        ? (delta > 0 ? _kFirstHighlight : count - 1)
        : (current + delta + count) % count;
  }

  /// Handles keyboard navigation for the suggestion list.
  ///
  /// Escape is deliberately handled here and *not* on Web: the Web twin's
  /// `Popover` already closes on Escape from a document listener, whereas
  /// this popover is non-modal, so the shared dismiss path never receives
  /// the key. Adding it on Web instead would fire twice.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return .ignored;
    }
    final key = event.logicalKey;

    if (key == .escape) {
      if (!_popover.isOpen) return .ignored;
      // Dismissing is a decision; a prop-driven re-sync must not undo it.
      _suppressReopen = true;
      _popover.close();
      return .handled;
    }

    if (!_popover.isOpen) return .ignored;
    final visible = _visible.value;
    if (visible.isEmpty) return .ignored;

    if (key == .arrowDown) {
      _moveHighlight(1, visible.length);
      return .handled;
    }
    if (key == .arrowUp) {
      _moveHighlight(-1, visible.length);
      return .handled;
    }
    if (key == .enter) {
      final index = _highlight.value;
      // Enter with nothing highlighted belongs to the field (form submit),
      // not to the list.
      if (index < _kFirstHighlight || index >= visible.length) {
        return .ignored;
      }
      _handleSelect(visible[index]);
      return .handled;
    }
    return .ignored;
  }

  /// Whether the suggestion panel should be open right now — focused,
  /// enabled, and at least one suggestion matches.
  bool get _shouldShow =>
      _focusNode.hasFocus && widget.enabled && _visible.value.isNotEmpty;

  /// Reconciles the [PopoverController] with [_shouldShow]. Driven from
  /// the focus / input / select handlers and from [didUpdateWidget]'s
  /// post-frame callback — never during build, since inserting an
  /// `OverlayEntry` mid-build is illegal.
  void _syncPopover() {
    if (_shouldShow && !_suppressReopen) {
      if (!_popover.isOpen) _popover.show();
    } else if (_popover.isOpen) {
      _popover.close();
    }
  }

  void _handleFocusChanged() {
    // Regaining focus is an explicit request for suggestions, so it lifts
    // the post-selection suppression.
    if (_focusNode.hasFocus) _suppressReopen = false;
    _syncPopover();
  }

  void _handleInput(String value) {
    // Keeps the trigger `Input.value` prop in sync; the portaled panel
    // reads the refreshed `_visible` via its own `ValueListenableBuilder`.
    _suppressReopen = false;
    setState(() => _currentValue = value);
    _recompute();
    widget.onChanged?.call(value);
    _syncPopover();
  }

  /// Applies [suggestion] per [Autocomplete.mode], returning the resulting
  /// text together with where the caret belongs in it.
  (String, int) _applySelection(String suggestion) => switch (widget.mode) {
    .replaceAll => (suggestion, suggestion.length),
    .append => (
      '$_currentValue$suggestion',
      _currentValue.length + suggestion.length,
    ),
    .replaceWord => _spliceWordAtCaret(suggestion),
  };

  /// Swaps [suggestion] in for the word under the caret, leaving the caret
  /// just past what was inserted so typing continues from there.
  (String, int) _spliceWordAtCaret(String suggestion) {
    final (start, next) = replaceWordAtCaret(_caret, suggestion, _currentValue);
    return (next, start + suggestion.length);
  }

  void _handleSelect(String suggestion) {
    final (next, caret) = _applySelection(suggestion);
    // Set before `onChanged` fires: a controlled parent reacts to that
    // callback synchronously, and the resulting `didUpdateWidget` must
    // already see the suppression or it reopens the panel we close below.
    _suppressReopen = true;
    setState(() => _currentValue = next);
    // Assigning `.text` would discard the caret; `replaceWord` needs it to
    // land mid-string, not at the end.
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: caret),
    );
    _recompute();
    widget.onChanged?.call(next);
    widget.onSelected?.call(suggestion);
    _popover.close();
  }

  Widget _buildOption(
    String suggestion,
    ResolvedAutocomplete resolved, {
    required bool highlighted,
  }) {
    return _AutocompleteOption(
      onSelected: () => _handleSelect(suggestion),
      suggestion: suggestion,
      query: _query,
      highlighted: highlighted,
      hoverColor: resolved.optionHoverColor,
      hoverTextStyle: resolved.optionHoverTextStyle,
      textStyle: resolved.dropdownTextStyle,
      matchTextStyle: resolved.matchTextStyle,
      padding: resolved.optionPadding,
      borderRadius: resolved.optionBorderRadius,
    );
  }

  /// Builds the floating panel content — the scrollable suggestion list.
  /// Listens to [_visible] so the portaled panel tracks both text edits
  /// *and* prop changes without re-pushing content to the [Popover]. No
  /// box chrome here: `Popover` → `Popup` paints the panel surface.
  Widget _buildPanel(ResolvedAutocomplete resolved) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: resolved.dropdownMaxHeight),
      child: SingleChildScrollView(
        child: ValueListenableBuilder<List<String>>(
          valueListenable: _visible,
          builder: (context, filtered, _) {
            if (filtered.isEmpty) return const SizedBox.shrink();
            return ValueListenableBuilder<int>(
              valueListenable: _highlight,
              builder: (context, highlight, _) => Column(
                mainAxisSize: .min,
                crossAxisAlignment: .stretch,
                children: [
                  for (var index = 0; index < filtered.length; index += 1)
                    _buildOption(
                      filtered[index],
                      resolved,
                      highlighted: index == highlight,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant Autocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextValue = widget.value;
    if (nextValue != null &&
        nextValue != oldWidget.value &&
        nextValue != _currentValue) {
      _currentValue = nextValue;
      _controller.text = nextValue;
    }

    // The panel's contents and its open/closed state are functions of the
    // props, not just of the text edits that used to be their only
    // trigger. Async `suggestions` arriving after the user typed is the
    // case that was permanently stuck closed without this.
    final changed =
        !listEquals(widget.suggestions, oldWidget.suggestions) ||
        widget.enabled != oldWidget.enabled ||
        widget.value != oldWidget.value;
    if (!changed) return;

    // `didUpdateWidget` runs during build, and both halves of the update
    // are illegal there: notifying `_visible` would `setState` the panel's
    // builder mid-build, and opening the popover would insert an
    // `OverlayEntry` mid-build. Defer the pair by one frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _recompute();
      _syncPopover();
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _popover.dispose();
    _controller.dispose();
    _focusNode.dispose();
    _visible.dispose();
    _highlight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveAutocomplete(
      context,
      autocompleteStyle: widget.autocompleteStyle,
    );

    // The field keeps focus while the list is navigated, so the key
    // handler sits on an ancestor and receives what the focused field does
    // not consume. `skipTraversal` keeps this listener out of the tab
    // order — it exists to hear keys, not to be reached by them.
    final input = Focus(
      skipTraversal: true,
      onKeyEvent: _handleKeyEvent,
      // Part of this composite: walled off from the enclosing
      // `FormField`, which is shown the composite's own value.
      child: Data<FormFieldHandle>.boundary(
        child: TextField(
          onChanged: _handleInput,
          placeholder: widget.placeholder != null
              ? Text(widget.placeholder!)
              : null,
          value: _currentValue,
          enabled: widget.enabled,
          required: widget.required,
          name: widget.name,
          controller: _controller,
          focusNode: _focusNode,
        ),
      ),
    );

    // The Web twin states this as a `role="combobox"` input over a
    // `role="listbox"` panel. Flutter has no combobox / listbox / option
    // role (`CoreSemanticRole`'s absent rung), so the meaning travels as
    // flags instead: whether the list is showing is `expanded` on the
    // trigger node `Popover` builds, and the keyboard-highlighted row is
    // `selected` on that row.
    return Semantics(
      container: true,
      child: Popover(
        trigger: input,
        content: _buildPanel(resolved),
        placement: CorePopoverStyle.defaultDropdownPlacement,
        controller: _popover,
        // Manual: the input drives open/close via its own focus / input
        // listeners. Letting `Popover` detect the trigger tap would fight
        // the focus model (the input must keep focus while typing).
        openTrigger: .manual,
        // Floor the panel at the input width so it lines up under the
        // field; long suggestions can still grow it wider.
        widthConstraint: .anchorMinSize,
        popoverStyle: resolved.popoverStyle,
      ),
    );
  }
}

/// A single hoverable option row inside the [Autocomplete] dropdown.
class _AutocompleteOption extends StatefulWidget {
  const _AutocompleteOption({
    required this.onSelected,
    required this.suggestion,
    required this.query,
    required this.highlighted,
    required this.hoverColor,
    required this.hoverTextStyle,
    required this.textStyle,
    required this.matchTextStyle,
    required this.padding,
    required this.borderRadius,
  });

  final String suggestion;

  /// The text the list was filtered on; its first occurrence in
  /// [suggestion] is drawn with [matchTextStyle].
  final String query;

  /// Whether the keyboard highlight is on this row.
  final bool highlighted;

  final Color hoverColor;
  final TextStyle hoverTextStyle;
  final TextStyle textStyle;
  final TextStyle matchTextStyle;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final VoidCallback onSelected;

  @override
  State<_AutocompleteOption> createState() => _AutocompleteOptionState();
}

class _AutocompleteOptionState extends State<_AutocompleteOption> {
  bool _hovered = false;

  @override
  void didUpdateWidget(covariant _AutocompleteOption oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A highlight that moves past the bottom of a scrolling list is a
    // highlight the user cannot see.
    if (widget.highlighted && !oldWidget.highlighted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(Scrollable.ensureVisible(context, alignment: 0.5));
      });
    }
  }

  /// The label with the query's first occurrence emphasised, wherever it
  /// sits (start, middle or end). The split is `CoreAutocompleteMatch`, the
  /// same one the Web label uses.
  Widget _label(TextStyle base) {
    final split = CoreAutocompleteMatch.of(widget.suggestion, widget.query);
    if (!split.hasMatch) return Text(widget.suggestion, style: base);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          if (split.before.isNotEmpty) TextSpan(text: split.before),
          TextSpan(text: split.match, style: widget.matchTextStyle),
          if (split.after.isNotEmpty) TextSpan(text: split.after),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keyboard highlight and pointer hover share one chrome: they mean the
    // same thing to the reader — "this is the row in play" — so a second
    // visual treatment would be noise, not information.
    final accented = _hovered || widget.highlighted;
    return Semantics(
      selected: widget.highlighted,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onSelected,
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: accented ? widget.hoverColor : null,
              borderRadius: widget.borderRadius,
            ),
            child: _label(accented ? widget.hoverTextStyle : widget.textStyle),
          ),
        ),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreAutocompleteStyle] patch into
/// [Autocomplete.autocompleteStyle] without hand-reconstructing every
/// field. Mirrors the Web `Autocomplete.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreAutocompleteStyle.merge` right-side-wins semantics).
extension AutocompleteStyleChain on Autocomplete {
  /// Returns a copy of this [Autocomplete] with [patch] merged into
  /// [autocompleteStyle] (patch fields win on conflict).
  Autocomplete withStyle(CoreAutocompleteStyle patch) => copyWith(
    autocompleteStyle: (autocompleteStyle ?? const CoreAutocompleteStyle())
        .merge(patch),
  );
}
