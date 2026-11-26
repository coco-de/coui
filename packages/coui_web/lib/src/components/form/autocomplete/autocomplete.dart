import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/form/autocomplete/autocomplete_style.dart';
import 'package:coui_web/src/components/form/form/form_controller.dart';
import 'package:coui_web/src/components/form/text_field/text_field.dart';
import 'package:coui_web/src/components/overlay/popover/popover.dart';
import 'package:coui_web/src/components/overlay/popover/popover_controller.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:universal_web/web.dart' as web;

/// Sentinel for "the keyboard is not pointing at any row".
///
/// Private: an internal cursor position, not something a caller sets.
const _kNoHighlight = -1;

/// Index of the first navigable row.
const _kFirstHighlight = 0;

/// Per-instance id source, so each panel's options carry stable ids that
/// `aria-activedescendant` can point at.
int _coAutocompleteScopeCounter = 0;

/// Unified cross-platform autocomplete for CoUI Web.
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
/// flow through the single [autocompleteStyle] (a [CoreAutocompleteStyle]);
/// the panel box chrome flows through `autocompleteStyle.popoverStyle`.
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
class Autocomplete extends UiStatefulComponent
    implements CoreAutocompleteContract<CoreValueChanged<String>?> {
  /// Creates a [Autocomplete].
  const Autocomplete({
    required this.suggestions,
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
  final CoreValueChanged<String>? onChanged;

  @override
  final CoreValueChanged<String>? onSelected;

  @override
  final CoreAutocompleteStyle? autocompleteStyle;

  /// Returns a copy of this [Autocomplete] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Autocomplete copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    CoreValueChanged<String>? onChanged,
    List<String>? suggestions,
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
    String? value,
    String? placeholder,
    bool? enabled,
    bool? required,
    String? name,
    CoreAutocompleteMode? mode,
    CoreValueChanged<String>? onSelected,
    CoreAutocompleteStyle? autocompleteStyle,
  }) {
    return Autocomplete(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      onChanged: onChanged ?? this.onChanged,
      suggestions: suggestions ?? this.suggestions,
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
  bool _focused = false;
  int _hoverIndex = -1;
  String _currentValue = '';

  /// Guards the deferred [didUpdateComponent] sync — the microtask can
  /// outlive the component.
  bool _isMounted = false;

  /// Blocks the *open* path of [_syncPopover] after a selection lands.
  ///
  /// Selecting fires `onChanged`, so a controlled parent recomputes props
  /// and we re-enter [didUpdateComponent] — with the input still focused
  /// (the option's `mousedown` called `preventDefault`) and the completed
  /// text matching the chosen suggestion itself. Without this, the
  /// prop-driven re-sync would immediately reopen the panel the selection
  /// just closed. Cleared on the next keystroke or refocus, since both
  /// mean the user wants suggestions back.
  bool _suppressReopen = false;

  /// Last caret offset reported by the field, used to locate the word a
  /// `replaceWord` completion applies to.
  int _caret = 0;

  /// Index of the keyboard-highlighted row in [_filtered], or `-1` for none.
  ///
  /// Separate from [_hoverIndex]: a pointer and the keyboard can each point
  /// at a different row, and the keyboard's choice is the one Enter takes.
  int _highlight = _kNoHighlight;

  /// This component's own mirror of the popover's open state, kept by
  /// [_handlePopoverChanged].
  ///
  /// A render that read `_popover.isOpen` directly would be a render from
  /// before the transition — `aria-expanded` would announce the opposite of
  /// what is on screen.
  bool _open = false;

  late final String _scopeId;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _currentValue = component.value ?? '';
    _caret = _currentValue.length;
    _scopeId =
        component.id ?? 'co-autocomplete-${_coAutocompleteScopeCounter++}';
    _popover.addListener(_handlePopoverChanged);
  }

  /// Mirrors every open / close transition, whoever caused it.
  ///
  /// The panel does not only close from this component's own handlers —
  /// `Popover` dismisses it on Escape and on an outside click. The input's
  /// `aria-expanded` and `aria-activedescendant` are read at build time, so
  /// a close this component did not render would leave the combobox
  /// announcing an open list and naming an option that is no longer in the
  /// document. A closed list also has nothing highlighted: reopening starts
  /// from the top again, as it does after a refilter.
  void _handlePopoverChanged() {
    if (!_isMounted) return;
    setState(() {
      _open = _popover.isOpen;
      if (!_open) _highlight = _kNoHighlight;
    });
  }

  /// Id of the listbox panel, for the input's `aria-controls`.
  String get _panelId => '$_scopeId-panel';

  /// Id of the option at [index], for `aria-activedescendant`.
  String _optionId(int index) => '$_scopeId-option-$index';

  /// The caret offset, always inside [_currentValue].
  ///
  /// Web has no `TextEditingController`; the field reports its caret
  /// through `TextField.onCaretChanged` and it is cached in [_caret]. A
  /// value left over from longer text falls back to the end.
  int get _caretOffset => _caret < 0 || _caret > _currentValue.length
      ? _currentValue.length
      : _caret;

  /// The text the filter runs against.
  ///
  /// `replaceWord` completes the word under the caret, so that word is the
  /// query. Filtering on the whole field instead is what made the dropdown
  /// vanish the moment a second word was typed: `'I like App'` matched no
  /// suggestion, so nothing was offered.
  String get _query => component.mode == CoreAutocompleteMode.replaceWord
      ? getWordAtCaret(_caretOffset, _currentValue).$2
      : _currentValue;

  List<String> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return component.suggestions;
    return component.suggestions
        .where((s) => s.toLowerCase().contains(query))
        .toList();
  }

  /// Whether the suggestion panel should be open — focused, enabled, and
  /// at least one suggestion matches.
  bool get _shouldShow => _focused && component.enabled && _filtered.isNotEmpty;

  /// Reconciles the [PopoverController] with [_shouldShow]. Driven from
  /// the focus / input / select handlers (event-time) so the floating
  /// panel mirrors the live focus + query state.
  void _syncPopover() {
    if (_shouldShow && !_suppressReopen) {
      if (!_popover.isOpen) _popover.show();
    } else if (_popover.isOpen) {
      _popover.close();
    }
  }

  void handleFocus() {
    _focused = true;
    // Regaining focus is an explicit request for suggestions, so it lifts
    // the post-selection suppression.
    _suppressReopen = false;
    _syncPopover();
  }

  void handleBlur() {
    // Real blur only — a suggestion `mousedown` calls `preventDefault`, so
    // selecting an option does NOT blur the input and never reaches here.
    _focused = false;
    _syncPopover();
  }

  void handleInput(String value) {
    _suppressReopen = false;
    setState(() {
      _currentValue = value;
      // A refilter invalidates the highlight: index 2 of the old list is a
      // different suggestion — or gone — in the new one, so Enter would
      // take something the user never highlighted.
      _highlight = _kNoHighlight;
    });
    component.onChanged?.call(value);
    _syncPopover();
  }

  /// Moves the highlight by [delta] within a list of [count] rows, wrapping
  /// at both ends.
  void _moveHighlight(int delta, int count) {
    setState(() {
      // From "nothing highlighted", down starts at the top and up at the
      // bottom — the same place a wrap would have landed.
      _highlight = _highlight < _kFirstHighlight
          ? (delta > 0 ? _kFirstHighlight : count - 1)
          : (_highlight + delta + count) % count;
    });
  }

  /// Handles keyboard navigation for the suggestion list.
  ///
  /// Escape is deliberately absent: `Popover` already closes on Escape from
  /// a document listener (`dismissOnEscape`, on by default), so handling it
  /// here too would fire the dismissal twice. The Flutter twin is the side
  /// that needs its own Escape — its popover is non-modal and never
  /// receives the key.
  void handleKeyDown(web.KeyboardEvent event) {
    if (!_popover.isOpen) return;
    final visible = _filtered;
    if (visible.isEmpty) return;

    switch (event.key) {
      case 'ArrowDown':
        // Without this the caret jumps to the end of the field instead.
        event.preventDefault();
        _moveHighlight(1, visible.length);
      case 'ArrowUp':
        event.preventDefault();
        _moveHighlight(-1, visible.length);
      case 'Enter':
        // Enter with nothing highlighted belongs to the field (form
        // submit), not to the list.
        if (_highlight < _kFirstHighlight || _highlight >= visible.length) {
          return;
        }
        event.preventDefault();
        handleSelect(visible[_highlight]);
    }
  }

  /// Applies [suggestion] per [Autocomplete.mode], returning the resulting
  /// text together with where the caret belongs in it.
  (String, int) _applySelection(String suggestion) => switch (component.mode) {
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
    final (start, next) = replaceWordAtCaret(
      _caretOffset,
      suggestion,
      _currentValue,
    );
    return (next, start + suggestion.length);
  }

  void handleSelect(String suggestion) {
    final (next, caret) = _applySelection(suggestion);
    // Set before `onChanged` fires: a controlled parent reacts to that
    // callback synchronously, and the resulting `didUpdateComponent` must
    // already see the suppression or it reopens the panel we close below.
    _suppressReopen = true;
    setState(() {
      _currentValue = next;
      _highlight = _kNoHighlight;
      // Tracked, not pushed: re-rendering `value` leaves the browser to
      // place the DOM caret. The next input event reports the real offset
      // and overwrites this, so the two cannot stay out of step.
      _caret = caret;
    });
    component.onChanged?.call(next);
    component.onSelected?.call(suggestion);
    _popover.close();
  }

  Component _buildOption({
    required BuildContext context,
    required int index,
    required String label,
  }) {
    // Keyboard highlight and pointer hover share one chrome: they mean the
    // same thing to the reader — "this is the row in play" — so a second
    // visual treatment would be noise, not information.
    final accented = _hoverIndex == index || _highlight == index;
    final optionResolved = resolveAutocompleteOption(
      context,
      hovered: accented,
      autocompleteStyle: component.autocompleteStyle,
    );
    return Component.element(
      tag: 'button',
      id: _optionId(index),
      classes: optionResolved.root.className,
      styles: optionResolved.root.inlineStyles,
      attributes: {
        'type': 'button',
        'role': 'option',
        'aria-selected': '${_highlight == index}',
        'data-value': label,
      },
      events: {
        // mousedown fires before the input loses focus; preventDefault
        // keeps the input focused so the panel does not blur-close before
        // the selection lands.
        'mousedown': EventHandlers.createMouseEventHandler((event) {
          event.preventDefault();
          handleSelect(label);
        }),
        'mouseenter': (_) => setState(() => _hoverIndex = index),
        'mouseleave': (_) => setState(() => _hoverIndex = -1),
      },
      children: _labelChildren(label, optionResolved),
    );
  }

  /// The label split around the query's first occurrence, wherever it sits
  /// (start, middle or end). The split is `CoreAutocompleteMatch`, the same
  /// one the Flutter label uses; the unmatched parts inherit the option's
  /// typography, the matched part carries the match typography.
  List<Component> _labelChildren(
    String label,
    ResolvedAutocompleteOption resolved,
  ) {
    final split = CoreAutocompleteMatch.of(label, _query);
    if (!split.hasMatch) return [Text(label)];
    // One inline wrapper keeps the pieces in a single text flow: as direct
    // children of the option's flex row each piece would be its own flex
    // item and a space at a split edge would collapse.
    return [
      Component.element(
        tag: 'span',
        children: [
          if (split.before.isNotEmpty) Text(split.before),
          Component.element(
            tag: 'span',
            classes: resolved.match.className,
            styles: resolved.match.inlineStyles,
            children: [Text(split.match)],
          ),
          if (split.after.isNotEmpty) Text(split.after),
        ],
      ),
    ];
  }

  /// Builds the floating panel content — the `<div role="listbox">`
  /// scroll region holding one `<button>` per filtered suggestion. No box
  /// chrome here: the composed `Popover` → `Popup` paints the surface.
  Component _buildPanel(BuildContext context, ResolvedAutocomplete resolved) {
    final filtered = _filtered;
    return Component.element(
      tag: 'div',
      id: _panelId,
      classes: resolved.panel.className,
      styles: resolved.panel.inlineStyles,
      attributes: const {'role': 'listbox'},
      children: [
        for (int i = 0; i < filtered.length; i += 1)
          _buildOption(context: context, index: i, label: filtered[i]),
      ],
    );
  }

  @override
  void didUpdateComponent(Autocomplete oldComponent) {
    super.didUpdateComponent(oldComponent);
    final nextValue = component.value;
    if (nextValue != null && nextValue != oldComponent.value) {
      _currentValue = nextValue;
    }

    // The panel's open/closed state is a function of the props, not just
    // of the focus / input events that used to be its only trigger. Async
    // `suggestions` arriving after the user typed is the case that was
    // permanently stuck closed without this. (`_filtered` already reads
    // live props, so the rendered rows need no separate notifier here.)
    final changed =
        !_listEquals(component.suggestions, oldComponent.suggestions) ||
        component.enabled != oldComponent.enabled ||
        component.value != oldComponent.value;
    if (!changed) return;

    // Same idiom as `Popover._schedulePortalSync`: mutating the overlay
    // controller inline would re-enter the portal host's `setState` while
    // it is still building.
    Future<void>.microtask(() {
      if (_isMounted) _syncPopover();
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    _popover
      ..removeListener(_handlePopoverChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveAutocomplete(
      context,
      autocompleteStyle: component.autocompleteStyle,
    );

    final visibleCount = _filtered.length;
    // Only an open list has an active option — a closed one has no option
    // in the document for `aria-activedescendant` to name.
    final hasHighlight =
        _open && _highlight >= _kFirstHighlight && _highlight < visibleCount;
    // Part of this composite: walled off from the enclosing
    // `FormField`, which is shown the composite's own value.
    final input = FormFieldHandleScope.boundary(
      child: TextField(
        // `TextField` routes `role` / `aria-*` onto its `<input>`, which is
        // the element a screen reader lands on. Keeping DOM focus there is
        // what makes a portaled panel reachable at all — the reader follows
        // `aria-activedescendant` rather than the focus ring.
        attributes: {
          'role': 'combobox',
          'aria-expanded': '$_open',
          'aria-controls': _panelId,
          'aria-autocomplete': 'list',
          if (hasHighlight) 'aria-activedescendant': _optionId(_highlight),
        },
        onChanged: handleInput,
        // Fires just before `onChanged`, so `handleInput` filters against a
        // caret that belongs to the value it is handed.
        onCaretChanged: (caret) => _caret = caret,
        placeholder: component.placeholder != null
            ? Text(component.placeholder!)
            : null,
        value: _currentValue,
        enabled: component.enabled,
        required: component.required,
        name: component.name,
      ),
    );

    // The input is the popover trigger. `focusin` / `focusout` bubble
    // from the inner `<input>` to this wrapper (unlike `focus` / `blur`),
    // so the wrapper drives open-on-focus / close-on-blur while the
    // popover runs in `manual` mode.
    final trigger = Component.element(
      tag: 'div',
      classes: WebLayout.wFull,
      events: {
        'focusin': EventHandlers.createEventHandler((_) => handleFocus()),
        'focusout': EventHandlers.createEventHandler((_) => handleBlur()),
        // Typed handler, never a `dynamic` cast — dart2js mangles those in
        // release and the listener dies silently.
        'keydown': EventHandlers.createKeyboardEventHandler(handleKeyDown),
      },
      children: [input],
    );

    // The root of `Autocomplete` is the `Popover` host, so caller chrome
    // passes through onto it (the popover wrapper is the outermost
    // element — not the portal panel), exactly like Web `Select`.
    return Popover(
      onClick: component.onClick,
      trigger: trigger,
      content: _buildPanel(context, resolved),
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
      placement: CorePopoverStyle.defaultDropdownPlacement,
      controller: _popover,
      // Manual: the input wrapper drives open/close via `focusin` /
      // `focusout`. Letting `Popover` detect the trigger interaction would
      // fight the focus model (the input must keep focus while typing).
      openTrigger: .manual,
      widthConstraint: .anchorMinSize,
      popoverStyle: resolved.popoverStyle,
    );
  }
}

/// Element-wise `List<String>` equality.
///
/// Local because the shared Style classes keep their own file-private
/// copies and none is exported; `package:flutter/foundation.dart` (which
/// supplies `listEquals` on the Flutter side) is not on Web's import path.
bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i += 1) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Chain sugar mirroring the Flutter `Autocomplete.withStyle` extension —
/// merges a [CoreAutocompleteStyle] patch into
/// [Autocomplete.autocompleteStyle] via the existing
/// [Autocomplete.copyWith].
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
