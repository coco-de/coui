// Browser `RichEditor` DOM bridge — edits the `contenteditable` surface
// through `package:web`. Kept behind the conditional export in
// `rich_editor_dom.dart` so the component stays SSR-safe; the signatures
// mirror `rich_editor_dom_stub.dart` exactly.

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/form/rich_editor/rich_editor_file.dart';
import 'package:coui_web/src/components/form/rich_editor/rich_editor_markdown.dart';
import 'package:coui_web/src/overlay/positioning/rect.dart';
import 'package:web/web.dart' as web;

/// A decoded key press on the editing surface.
typedef RichEditorKey = ({
  /// The unshifted key of a Mod shortcut (`B`, `8`, `.`, `1`), else null —
  /// always null while AltGr is held, which types characters on layouts
  /// that have it.
  String? shortcutKey,

  /// Whether Shift was held.
  bool shift,

  /// Whether Alt (Option on Apple platforms) was held.
  bool alt,

  /// Whether the platform modifier (⌘ / Ctrl) was held.
  bool mod,

  /// Whether the key was Enter.
  bool enter,

  /// Whether the key was Escape — it closes the toolbar over the selection.
  bool escape,

  /// Whether the press was Alt+F10 — it moves the focus into the toolbar
  /// over the selection.
  bool toolbarFocus,

  /// Whether the press grows the selection — Shift with an arrow, Home,
  /// End, PageUp or PageDown — so the toolbar over it waits for the
  /// selection to hold still.
  bool selects,
});

/// What the toolbar over a selection measures to fold its buttons: the
/// widths of its units in fold order, the width of what never folds, the
/// width of the "more" button with its separator, and how much wider the
/// panel is than the bar (its inset and line).
typedef RichEditorFoldMeasure = ({
  List<double> units,
  double pinned,
  double more,
  double chrome,
});

const int _kElementNode = 1;
const int _kTextNode = 3;

/// Holds the caret outside a mark the editor just closed — stripped from
/// the value by the codec.
const String _kCaretHolder = '​';

/// Selections remembered while focus is elsewhere, by surface id.
final Map<String, web.Range> _savedRanges = {};

/// Whether the browser runs on an Apple platform (⌘ rather than Ctrl).
bool richEditorIsApple() {
  final navigator = web.window.navigator;
  final probe = '${navigator.platform} ${navigator.userAgent}';
  return RegExp('Mac|iPhone|iPad|iPod').hasMatch(probe);
}

web.HTMLElement? _surface(String id) =>
    web.document.getElementById(id) as web.HTMLElement?;

/// Replaces the surface's document with [html].
void richEditorSeed(String id, String html) {
  final surface = _surface(id);
  if (surface != null) {
    _watchImages(surface);
    surface.innerHTML = html.toJS;
  }
  // Firefox draws resize handles on a selected image; the editor sizes
  // images itself. Browsers that lack the command ignore the call.
  web.document.execCommand('enableObjectResizing', false, 'false');
}

/// Marks an image that fails to load. A load error does not bubble, so the
/// surface listens for it on the way down; the same function added again is
/// the same listener. The mark is an attribute and a tooltip taken from the
/// surface's `data-unavailable-label`; the Markdown reads neither, so the
/// document is not changed by it.
final JSFunction _onImageError = ((web.Event event) {
  final image = event.target as web.Node?;
  final surface = event.currentTarget as web.Element?;
  if (image == null || surface == null) return;
  if (image.nodeName.toLowerCase() != 'img') return;
  final element = image as web.HTMLElement
    ..setAttribute('data-unavailable', '');
  final label = surface.getAttribute('data-unavailable-label');
  if (label != null && label.isNotEmpty) element.title = label;
}).toJS;

void _watchImages(web.HTMLElement surface) =>
    surface.addEventListener('error', _onImageError, true.toJS);

/// Reads the surface's document.
List<RichEditorNode> richEditorRead(String id) {
  final surface = _surface(id);
  if (surface == null) return const [];
  return _readChildren(surface);
}

List<RichEditorNode> _readChildren(web.Node parent) {
  final nodes = <RichEditorNode>[];
  final children = parent.childNodes;
  for (var i = 0; i < children.length; i++) {
    final node = _readNode(children.item(i)!);
    if (node != null) nodes.add(node);
  }
  return nodes;
}

RichEditorNode? _readNode(web.Node node) {
  if (node.nodeType == _kTextNode) {
    final text = node.textContent ?? '';
    return text.isEmpty ? null : RichEditorNode.text(text);
  }
  if (node.nodeType != _kElementNode) return null;
  final element = node as web.Element;
  final tag = element.localName.toLowerCase();
  switch (tag) {
    case 'input':
      final input = element as web.HTMLInputElement;
      if (input.type != 'checkbox') return null;
      return RichEditorNode(
        'input',
        attributes: {'type': 'checkbox', if (input.checked) 'checked': ''},
      );
    case 'script' || 'style' || 'template':
      return null;
  }
  final attributes = <String, String>{
    if (tag == 'a') 'href': ?element.getAttribute('href'),
    if (tag == 'ol') 'start': ?element.getAttribute('start'),
    if (tag == 'code') 'class': ?element.getAttribute('class'),
    // The attribute as written, not the resolved `img.src`: a path on the
    // page's own server stays a path.
    if (tag == 'img') ...{
      'src': element.getAttribute('src') ?? '',
      'alt': element.getAttribute('alt') ?? '',
    },
  };
  return RichEditorNode(
    tag,
    attributes: attributes,
    children: _readChildren(element),
  );
}

/// Moves focus to the surface.
void richEditorFocus(String id) => _surface(id)?.focus();

/// Calls [onChange] whenever the selection moves inside the surface; returns
/// the disposer.
void Function() richEditorListenSelection(
  String id,
  void Function() onChange,
) {
  final listener = ((web.Event _) {
    if (_rangeIn(id) != null) onChange();
  }).toJS;
  web.document.addEventListener('selectionchange', listener);
  return () => web.document.removeEventListener('selectionchange', listener);
}

/// The selection's first range when it lies inside the surface.
web.Range? _rangeIn(String id) {
  final surface = _surface(id);
  final selection = web.window.getSelection();
  if (surface == null || selection == null || selection.rangeCount == 0) {
    return null;
  }
  final range = selection.getRangeAt(0);
  if (!surface.contains(range.commonAncestorContainer)) return null;
  return range;
}

// ─── The selection, for the toolbar that floats over it ─────────────

/// The selected run of text: the selection's range when it lies inside the
/// surface, is not a caret and covers at least one character.
///
/// While the focus is outside the surface — on a button of the toolbar —
/// the browser may have let the selection go; the range remembered when the
/// surface lost the focus stands in for it.
web.Range? _selectedText(String id) {
  final surface = _surface(id);
  if (surface == null) return null;
  var range = _rangeIn(id);
  if (range == null && !identical(web.document.activeElement, surface)) {
    final saved = _savedRanges[id];
    if (saved != null && surface.contains(saved.commonAncestorContainer)) {
      range = saved;
    }
  }
  if (range == null || range.collapsed) return null;
  return range.toString().isEmpty ? null : range;
}

/// The box of the selected text that is in view, in viewport coordinates —
/// the selection's bounding box, cut to the surface's own box, which is what
/// shows of a document that scrolls. Null when no text is selected, or when
/// the selected text has been scrolled out of the surface.
OverlayRect? richEditorSelectionRect(String id) {
  final surface = _surface(id);
  final range = _selectedText(id);
  if (surface == null || range == null) return null;
  final selected = range.getBoundingClientRect();
  final view = surface.getBoundingClientRect();
  final left = selected.left > view.left ? selected.left : view.left;
  final top = selected.top > view.top ? selected.top : view.top;
  final right = selected.right < view.right ? selected.right : view.right;
  final bottom = selected.bottom < view.bottom ? selected.bottom : view.bottom;
  if (right < left || bottom <= top) return null;
  return OverlayRect(
    left: left,
    top: top,
    width: right - left,
    height: bottom - top,
  );
}

/// Where the editing surface begins, from the top of the viewport — the
/// top edge of the room the toolbar over a selection may take while the
/// toolbar in the box shows.
double? richEditorSurfaceTop(String id) =>
    _surface(id)?.getBoundingClientRect().top;

/// Measures the units of the toolbar over a selection — the elements
/// marked `data-fold` inside the panel [panelId] names — so the editor can
/// ask Core how many to fold: `data-fold="u<i>"` is the unit at `i` of the
/// fold order, `pinned` what never folds, `more` the "more" button with its
/// separator. A folded unit is still in the DOM (out of sight), so its width
/// reads too. `chrome` is how much wider the panel (`[role=toolbar]`) is than
/// the bar (`data-fold="bar"`): its inset and line. Null before the panel
/// is in the DOM.
RichEditorFoldMeasure? richEditorMeasureFold(String panelId) {
  final panel = web.document.getElementById(panelId);
  if (panel == null) return null;
  final toolbar = panel.querySelector('[role=toolbar]');
  final bar = panel.querySelector('[data-fold=bar]');
  if (toolbar == null || bar == null) return null;
  final units = <int, double>{};
  var pinned = 0.0;
  var more = 0.0;
  final marked = panel.querySelectorAll('[data-fold]');
  for (var i = 0; i < marked.length; i++) {
    final element = marked.item(i)! as web.Element;
    final tag = element.getAttribute('data-fold')!;
    final width = element.getBoundingClientRect().width;
    if (tag == 'pinned') {
      pinned += width;
    } else if (tag == 'more') {
      more += width;
    } else if (tag.startsWith('u')) {
      final index = int.tryParse(tag.substring(1));
      if (index != null) units[index] = (units[index] ?? 0) + width;
    }
  }
  final count = units.isEmpty
      ? 0
      : units.keys.reduce((a, b) => a > b ? a : b) + 1;
  return (
    units: [for (var i = 0; i < count; i++) units[i] ?? 0],
    pinned: pinned,
    more: more,
    chrome:
        toolbar.getBoundingClientRect().width -
        bar.getBoundingClientRect().width,
  );
}

/// The width of the viewport — the room a panel held inside it may take.
double richEditorViewportWidth() => web.window.innerWidth.toDouble();

/// The child indexes that lead from the surface down to [node].
String _pathOf(web.Node node, web.Element surface) {
  final path = <int>[];
  web.Node? current = node;
  while (current != null && !identical(current, surface)) {
    var index = 0;
    for (
      var sibling = current.previousSibling;
      sibling != null;
      sibling = sibling.previousSibling
    ) {
      index++;
    }
    path.add(index);
    current = current.parentNode;
  }
  return path.reversed.join('.');
}

/// Names the selected run of text, so that the same selection reads the same
/// and another one differently; null when no text is selected. What Escape
/// remembers: the toolbar it closed stays closed on that selection.
String? richEditorSelectionSignature(String id) {
  final surface = _surface(id);
  final range = _selectedText(id);
  if (surface == null || range == null) return null;
  return '${_pathOf(range.startContainer, surface)}:${range.startOffset}'
      '-${_pathOf(range.endContainer, surface)}:${range.endOffset}';
}

/// Whether the keyboard's focus is on, or inside, one of the elements [ids]
/// name.
bool richEditorHasFocusIn(List<String> ids) {
  final active = web.document.activeElement;
  if (active == null) return false;
  for (final id in ids) {
    final element = web.document.getElementById(id);
    if (element != null && element.contains(active)) return true;
  }
  return false;
}

/// Moves the focus to the first button in the element [id] names that can
/// take it; false when there is none.
bool richEditorFocusFirstButton(String id) {
  final first = web.document
      .getElementById(id)
      ?.querySelector('button:not([disabled])');
  if (first == null) return false;
  (first as web.HTMLElement).focus();
  return true;
}

/// How many frames [richEditorWhenInteractive] waits for the page to come
/// back before it runs anyway — about two seconds. Not a design token.
const int _kInteractiveWaitFrames = 120;

/// Runs [run] once the surface can take the focus and be edited: at once,
/// unless the page around it is `inert` — which it is while a modal overlay
/// (a menu opened from the toolbar) is still mounted, its exit animation
/// included. An inert surface refuses the focus, and an edit made then
/// changes nothing, so a format picked from a menu is applied when the menu
/// has gone.
void richEditorWhenInteractive(String id, void Function() run) {
  var frames = 0;
  void attempt() {
    final surface = _surface(id);
    if (surface == null) return;
    if (surface.closest('[inert]') == null ||
        frames >= _kInteractiveWaitFrames) {
      run();
      return;
    }
    frames++;
    final _ = web.window.requestAnimationFrame(
      ((double _) => attempt()).toJS,
    );
  }

  attempt();
}

/// The direction the surface's text runs in (`ltr` / `rtl`), as the browser
/// computed it, or null before the surface is in the page.
String? richEditorDirectionOf(String id) {
  final surface = _surface(id);
  if (surface == null) return null;
  return web.window.getComputedStyle(surface).direction;
}

/// Calls [onChange] when what the toolbar over the selection depends on may
/// have changed without the selection changing: a pointer released anywhere
/// (`pointer: true` — a drag that selects ends wherever the pointer is), the
/// page or the surface scrolled, the window resized. Returns the disposer.
void Function() richEditorListenViewport(
  void Function({required bool pointer}) onChange,
) {
  final onPointer = ((web.Event _) => onChange(pointer: true)).toJS;
  final onMove = ((web.Event _) => onChange(pointer: false)).toJS;
  final capture = web.AddEventListenerOptions(capture: true, passive: true);
  web.document.addEventListener('pointerup', onPointer);
  web.document.addEventListener('pointercancel', onPointer);
  web.window.addEventListener('scroll', onMove, capture);
  web.window.addEventListener('resize', onMove);
  return () {
    web.document.removeEventListener('pointerup', onPointer);
    web.document.removeEventListener('pointercancel', onPointer);
    web.window.removeEventListener('scroll', onMove, capture);
    web.window.removeEventListener('resize', onMove);
  };
}

/// The element ancestors of [node] up to (not including) the surface,
/// innermost first.
List<web.Element> _ancestors(web.Node? node, web.Element surface) {
  final result = <web.Element>[];
  var current = node;
  while (current != null && current != surface) {
    if (current.nodeType == _kElementNode) result.add(current as web.Element);
    current = current.parentNode;
  }
  return result;
}

String _tagOf(web.Element element) => element.localName.toLowerCase();

web.Element? _closest(String id, Set<String> tags) {
  final surface = _surface(id);
  final range = _rangeIn(id);
  if (surface == null || range == null) return null;
  for (final element in _ancestors(range.startContainer, surface)) {
    if (tags.contains(_tagOf(element))) return element;
  }
  return null;
}

bool _isTaskItem(web.Element item) {
  final first = item.firstElementChild;
  return first != null &&
      _tagOf(first) == 'input' &&
      (first as web.HTMLInputElement).type == 'checkbox';
}

/// The formats on at the caret.
Set<CoreRichEditorFormat> richEditorActiveFormats(String id) {
  final surface = _surface(id);
  final range = _rangeIn(id);
  if (surface == null || range == null) return const {};
  final formats = <CoreRichEditorFormat>{};
  var listSeen = false;
  for (final element in _ancestors(range.startContainer, surface)) {
    switch (_tagOf(element)) {
      case 'strong' || 'b':
        formats.add(.bold);
      case 'em' || 'i':
        formats.add(.italic);
      case 'del' || 's' || 'strike':
        formats.add(.strikethrough);
      case 'code':
        formats.add(.code);
      case 'a':
        formats.add(.link);
      case 'blockquote':
        formats.add(.quote);
      case 'h1':
        formats.add(.heading1);
      case 'h2':
        formats.add(.heading2);
      // `h4`–`h6` read as the smallest heading, the way the Flutter editor
      // does.
      case 'h3' || 'h4' || 'h5' || 'h6':
        formats.add(.heading3);
      case 'li' when !listSeen:
        listSeen = true;
        final list = element.parentElement;
        if (_isTaskItem(element)) {
          formats.add(.taskList);
        } else if (list != null && _tagOf(list) == 'ol') {
          formats.add(.numberedList);
        } else {
          formats.add(.bulletedList);
        }
    }
  }
  return formats;
}

/// Remembers the surface's selection (a toolbar press or a dialog takes
/// focus away from it).
void richEditorSaveSelection(String id) {
  final range = _rangeIn(id);
  if (range != null) _savedRanges[id] = range.cloneRange();
}

/// Focuses the surface and puts the remembered selection back.
void richEditorRestoreSelection(String id) {
  final surface = _surface(id);
  if (surface == null) return;
  surface.focus();
  final saved = _savedRanges[id];
  final selection = web.window.getSelection();
  if (saved == null || selection == null) return;
  if (!surface.contains(saved.commonAncestorContainer)) return;
  selection
    ..removeAllRanges()
    ..addRange(saved);
}

bool _exec(String command, [String? value]) {
  web.document.execCommand('styleWithCSS', false, 'false');
  return value == null
      ? web.document.execCommand(command)
      : web.document.execCommand(command, false, value);
}

/// Toggles [format] at the selection — every format but the link.
void richEditorApply(String id, CoreRichEditorFormat format) {
  switch (format) {
    case .bold:
      _exec('bold');
    case .italic:
      _exec('italic');
    case .strikethrough:
      _exec('strikeThrough');
    case .code:
      _toggleCode(id);
    case .link:
      break;
    case .bulletedList:
      _toggleList(id, ordered: false, task: false);
    case .numberedList:
      _toggleList(id, ordered: true, task: false);
    case .taskList:
      _toggleList(id, ordered: false, task: true);
    case .quote:
      _toggleQuote(id);
    case .heading1:
      _toggleHeading(id, 1);
    case .heading2:
      _toggleHeading(id, 2);
    case .heading3:
      _toggleHeading(id, 3);
    case .image:
      break;
    // The block-type menu applies the heading a row stands for, never
    // itself.
    case .blockType:
      break;
  }
}

void _placeCaret(web.Node node, int offset) {
  final selection = web.window.getSelection();
  if (selection == null) return;
  final range = web.document.createRange()
    ..setStart(node, offset)
    ..collapse(true);
  selection
    ..removeAllRanges()
    ..addRange(range);
}

void _selectContents(web.Node node) {
  final selection = web.window.getSelection();
  if (selection == null) return;
  final range = web.document.createRange()..selectNodeContents(node);
  selection
    ..removeAllRanges()
    ..addRange(range);
}

/// Replaces [element] with its children.
void _unwrap(web.Element element) {
  final parent = element.parentNode;
  if (parent == null) return;
  while (element.firstChild != null) {
    parent.insertBefore(element.firstChild!, element);
  }
  parent.removeChild(element);
}

void _toggleCode(String id) {
  final existing = _closest(id, const {'code'});
  if (existing != null) {
    if (existing.parentElement != null &&
        _tagOf(existing.parentElement!) == 'pre') {
      return;
    }
    _unwrap(existing);
    return;
  }
  final range = _rangeIn(id);
  if (range == null) return;
  final code = web.document.createElement('code');
  if (range.collapsed) {
    code.textContent = _kCaretHolder;
    range.insertNode(code);
    _placeCaret(code.firstChild!, 1);
    return;
  }
  // Literal code holds text only — the selection's marks are dropped.
  code.textContent = range.toString();
  range
    ..deleteContents()
    ..insertNode(code);
  _selectContents(code);
}

void _toggleList(String id, {required bool ordered, required bool task}) {
  final item = _closest(id, const {'li'});
  final list = item?.parentElement;
  final inOrdered = list != null && _tagOf(list) == 'ol';
  final inTask = item != null && _isTaskItem(item);
  if (item != null && list != null) {
    final sameKind = task
        ? inTask
        : ordered
        ? inOrdered && !inTask
        : !inOrdered && !inTask;
    if (sameKind) {
      // Toggle off: the items return to paragraphs.
      _removeCheckboxes(id, list);
      _exec(inOrdered ? 'insertOrderedList' : 'insertUnorderedList');
      return;
    }
    if (task) {
      if (inOrdered) _exec('insertUnorderedList');
      _addCheckboxes(id);
      return;
    }
    _removeCheckboxes(id, list);
    if (ordered != inOrdered) {
      _exec(ordered ? 'insertOrderedList' : 'insertUnorderedList');
    }
    return;
  }
  _exec(ordered ? 'insertOrderedList' : 'insertUnorderedList');
  _liftListOutOfParagraph(id);
  if (task) _addCheckboxes(id);
}

/// Chrome may build the new list inside the paragraph it came from
/// (`<p><ul>…</ul></p>`), where the next line typed after it would land in
/// that paragraph; the list replaces a paragraph that holds nothing else.
void _liftListOutOfParagraph(String id) {
  final list = _closest(id, const {'ul', 'ol'});
  final paragraph = list?.parentElement;
  if (list == null || paragraph == null) return;
  if (_tagOf(paragraph) != 'p' && _tagOf(paragraph) != 'div') return;
  if (paragraph == _surface(id)) return;
  final children = paragraph.childNodes;
  for (var i = 0; i < children.length; i++) {
    final child = children.item(i)!;
    if (child == list) continue;
    final isBreak =
        child.nodeType == _kElementNode && _tagOf(child as web.Element) == 'br';
    final isBlank =
        child.nodeType == _kTextNode &&
        (child.textContent ?? '').replaceAll(_kCaretHolder, '').trim().isEmpty;
    if (!isBreak && !isBlank) return;
  }
  // A moved node takes the live selection's boundary with it to its old
  // place, so the caret is noted as a node and offset and put back.
  final range = _rangeIn(id);
  final caretNode = range?.startContainer;
  final caretOffset = range?.startOffset ?? 0;
  paragraph.parentNode?.replaceChild(list, paragraph);
  if (caretNode != null) _placeCaret(caretNode, caretOffset);
}

web.HTMLInputElement _checkbox() =>
    (web.document.createElement('input') as web.HTMLInputElement)
      ..type = 'checkbox'
      ..setAttribute('contenteditable', 'false')
      ..tabIndex = -1;

void _addCheckboxes(String id) {
  final item = _closest(id, const {'li'});
  final list = item?.parentElement;
  if (list == null) return;
  final range = _rangeIn(id);
  final items = list.children;
  for (var i = 0; i < items.length; i++) {
    final li = items.item(i)!;
    if (_tagOf(li) != 'li' || _isTaskItem(li)) continue;
    // Only the selected items become tasks.
    if (range != null && !range.intersectsNode(li)) continue;
    final box = _checkbox();
    li.insertBefore(box, li.firstChild);
    if (li == item && (range?.collapsed ?? true)) _caretAfterCheckbox(box);
  }
}

/// Puts the caret at the start of the text after a task's [box] — a
/// browser would otherwise leave it in front of the checkbox.
void _caretAfterCheckbox(web.Element box) {
  final next = box.nextSibling;
  if (next != null && next.nodeType == _kTextNode) {
    final text = next as web.Text;
    final holder = text.data.startsWith(_kCaretHolder);
    _placeCaret(text, holder ? 1 : 0);
    return;
  }
  final holder = web.document.createTextNode(_kCaretHolder);
  box.parentNode?.insertBefore(holder, next);
  _placeCaret(holder, 1);
}

/// Removes the checkboxes of the selected items of [list] — the ones a
/// list toggle applies to.
void _removeCheckboxes(String id, web.Element list) {
  final range = _rangeIn(id);
  final items = list.children;
  for (var i = 0; i < items.length; i++) {
    final li = items.item(i)!;
    if (!_isTaskItem(li)) continue;
    if (range != null && !range.intersectsNode(li)) continue;
    li.removeChild(li.firstElementChild!);
  }
}

void _toggleQuote(String id) {
  final quote = _closest(id, const {'blockquote'});
  if (quote != null) {
    _unwrap(quote);
    return;
  }
  _exec('formatBlock', '<blockquote>');
}

/// Runs [change], then puts the selection back on the same nodes — a node
/// that is moved takes the selection's boundary with it to its old place.
void _keepingSelection(void Function() change) {
  final selection = web.window.getSelection();
  if (selection == null || selection.rangeCount == 0) {
    change();
    return;
  }
  final range = selection.getRangeAt(0);
  final startNode = range.startContainer;
  final startOffset = range.startOffset;
  final endNode = range.endContainer;
  final endOffset = range.endOffset;
  change();
  final restored = web.document.createRange()
    ..setStart(startNode, startOffset)
    ..setEnd(endNode, endOffset);
  selection
    ..removeAllRanges()
    ..addRange(restored);
}

/// The level of the heading the caret is in; `h3`–`h6` count as 3, the way
/// the Flutter editor reads them.
int? _headingLevelAtCaret(String id) {
  final heading = _closest(id, const {'h1', 'h2', 'h3', 'h4', 'h5', 'h6'});
  if (heading == null) return null;
  return switch (_tagOf(heading)) {
    'h1' => 1,
    'h2' => 2,
    _ => 3,
  };
}

/// Takes the caret's list item out of its list — the toggle-off path of
/// [_toggleList] — so the line is a plain block.
void _leaveList(String id) {
  final item = _closest(id, const {'li'});
  final list = item?.parentElement;
  if (item == null || list == null) return;
  _removeCheckboxes(id, list);
  _exec(
    _tagOf(list) == 'ol' ? 'insertOrderedList' : 'insertUnorderedList',
  );
}

/// Takes the caret's line out of its quote; the quote's other lines stay
/// quoted (a quote in the middle is split in two).
void _leaveQuote(String id) {
  final quote = _closest(id, const {'blockquote'});
  final range = _rangeIn(id);
  final parent = quote?.parentNode;
  if (quote == null || range == null || parent == null) return;
  web.Node? line = range.startContainer;
  while (line != null && line.parentNode != quote) {
    line = line.parentNode;
  }
  final held = line;
  _keepingSelection(() {
    if (held == null ||
        (held.previousSibling == null && held.nextSibling == null)) {
      _unwrap(quote);
      return;
    }
    final tail = quote.cloneNode(false);
    var next = held.nextSibling;
    while (next != null) {
      final following = next.nextSibling;
      tail.appendChild(next);
      next = following;
    }
    parent.insertBefore(held, quote.nextSibling);
    if (tail.hasChildNodes()) parent.insertBefore(tail, held.nextSibling);
    if (!quote.hasChildNodes()) parent.removeChild(quote);
  });
}

/// Turns the caret's block into a level-[level] heading, or back into a
/// paragraph when it already is one. A block is exactly one kind, so a list
/// item or a quoted line becomes the heading instead of holding it.
void _toggleHeading(String id, int level) {
  if (_rangeIn(id) == null) return;
  if (_headingLevelAtCaret(id) == level) {
    _exec('formatBlock', '<p>');
    return;
  }
  _leaveList(id);
  _leaveQuote(id);
  _exec('formatBlock', '<h$level>');
  _dropStyleSpans(_closest(id, const {'h1', 'h2', 'h3'}));
}

/// Unwraps the `<span style="…">`s inside [block]. Chrome adds them around a
/// line's text when the line leaves a list, to keep the look the list item
/// had; the editor's own marks are never spans, and the heading's look comes
/// from the surface's rules.
void _dropStyleSpans(web.Element? block) {
  if (block == null) return;
  final spans = block.querySelectorAll('span[style]');
  if (spans.length == 0) return;
  _keepingSelection(() {
    for (var i = 0; i < spans.length; i++) {
      _unwrap(spans.item(i)! as web.Element);
    }
  });
}

/// The target of the link at the caret, or null.
String? richEditorLinkAtCaret(String id) =>
    _closest(id, const {'a'})?.getAttribute('href');

/// Links the selection to [href], or unlinks it when [href] is null.
void richEditorSetLink(String id, String? href) {
  final existing = _closest(id, const {'a'});
  if (existing != null) {
    if (href == null) {
      _unwrap(existing);
    } else {
      existing.setAttribute('href', href);
    }
    return;
  }
  if (href == null) return;
  final range = _rangeIn(id);
  if (range == null) return;
  final anchor = web.document.createElement('a')..setAttribute('href', href);
  if (range.collapsed) {
    anchor.textContent = href;
    range.insertNode(anchor);
    _caretAfter(anchor);
    return;
  }
  anchor.append(range.extractContents());
  range.insertNode(anchor);
  _selectContents(anchor);
}

/// Puts the caret just after [element], outside its mark.
void _caretAfter(web.Element element) {
  final holder = web.document.createTextNode(_kCaretHolder);
  element.parentNode?.insertBefore(holder, element.nextSibling);
  _placeCaret(holder, 1);
}

/// `KeyboardEvent.code` → the unshifted key a shortcut names.
String? _keyOfCode(String code) {
  if (code.startsWith('Key') && code.length == 4) return code.substring(3);
  if (code.startsWith('Digit') && code.length == 6) return code.substring(5);
  return switch (code) {
    'Period' => '.',
    _ => null,
  };
}

/// Decodes a `keydown` event.
RichEditorKey richEditorKeyOf(Object event, {required bool apple}) {
  final key = event as web.KeyboardEvent;
  final mod = apple ? key.metaKey && !key.ctrlKey : key.ctrlKey && !key.metaKey;
  // AltGr reaches the page as Ctrl+Alt on Windows, and what it types (² on a
  // German 2) is text, not a shortcut.
  final altGraph = key.getModifierState('AltGraph');
  return (
    shortcutKey: mod && !altGraph ? _keyOfCode(key.code) : null,
    shift: key.shiftKey,
    alt: key.altKey,
    mod: mod,
    enter: key.key == 'Enter',
    escape: key.key == 'Escape',
    toolbarFocus:
        key.key == 'F10' &&
        key.altKey &&
        !key.ctrlKey &&
        !key.metaKey &&
        !key.shiftKey,
    selects: key.shiftKey && !key.altKey && _kSelectionKeys.contains(key.key),
  );
}

/// The keys that move the caret — with Shift, they grow the selection.
const Set<String> _kSelectionKeys = {
  'ArrowLeft',
  'ArrowRight',
  'ArrowUp',
  'ArrowDown',
  'Home',
  'End',
  'PageUp',
  'PageDown',
};

/// Cancels the browser's default action for [event].
void richEditorPreventDefault(Object event) =>
    (event as web.Event).preventDefault();

/// The block element holding the caret (or null at the top level).
web.Element? _block(String id) => _closest(id, const {
  'p',
  'div',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'li',
  'blockquote',
});

/// Handles Enter where the editor, not the browser, decides: a `---` line
/// becomes a rule, and Enter on an empty list item or quote line leaves
/// it. Returns whether
/// it did either (the caller then cancels the browser's Enter).
bool richEditorEnterRule(String id) {
  final surface = _surface(id);
  final range = _rangeIn(id);
  if (surface == null || range == null || !range.collapsed) return false;
  final block = _block(id);
  final text = (block?.textContent ?? range.startContainer.textContent ?? '')
      .replaceAll(_kCaretHolder, '')
      .trim();
  // Enter on an empty item leaves the list (a nested one steps out a
  // level). The browser does not do it reliably — and never for a task,
  // whose checkbox makes the item look filled — so the editor does.
  if (text.isEmpty && block != null && _tagOf(block) == 'li') {
    if (_isTaskItem(block)) block.removeChild(block.firstElementChild!);
    final list = block.parentElement;
    final nested = list?.parentElement;
    if (nested != null && _tagOf(nested) == 'li') {
      _exec('outdent');
    } else {
      _exec(
        list != null && _tagOf(list) == 'ol'
            ? 'insertOrderedList'
            : 'insertUnorderedList',
      );
    }
    return true;
  }
  // Enter on an empty quote line leaves the quote.
  if (text.isEmpty && _closest(id, const {'blockquote'}) != null) {
    _exec('formatBlock', '<p>');
    return true;
  }
  if (text != '---') return false;
  if (block != null && _tagOf(block) == 'li') return false;
  final rule = web.document.createElement('hr');
  final paragraph = web.document.createElement('p')
    ..append(web.document.createElement('br'));
  if (block != null && block.parentNode != null) {
    block.parentNode!
      ..insertBefore(rule, block)
      ..insertBefore(paragraph, block)
      ..removeChild(block);
  } else {
    final textNode = range.startContainer;
    textNode.parentNode?.insertBefore(rule, textNode);
    textNode.parentNode?.insertBefore(paragraph, textNode);
    textNode.parentNode?.removeChild(textNode);
  }
  _placeCaret(paragraph, 0);
  return true;
}

/// Block markers recognised at a line's start, with the format each turns
/// the line into (a heading level is spelled `h1`–`h3`).
const Map<String, String> _kBlockMarkers = {
  '#': 'h1',
  '##': 'h2',
  '###': 'h3',
  '-': 'ul',
  '*': 'ul',
  '1.': 'ol',
  '[]': 'task',
  '[ ]': 'task',
  '- [ ]': 'task',
  '>': 'quote',
};

/// Inline Markdown recognised as it is closed, innermost group the text.
final List<(RegExp, String)> _kInlineMarks = [
  (RegExp(r'\*\*([^*\s](?:[^*]*[^*\s])?)\*\*$'), 'strong'),
  (RegExp(r'~~([^~\s](?:[^~]*[^~\s])?)~~$'), 'del'),
  (RegExp(r'`([^`]+)`$'), 'code'),
  (RegExp(r'(?:^|[^*])\*([^*\s](?:[^*]*[^*\s])?)\*$'), 'em'),
  (RegExp(r'\[([^\]]+)\]\(([^)\s]+)\)$'), 'a'),
];

/// Formats Markdown typed into the surface (`**x**`, `# `, `- ` …) after an
/// `input` event; returns whether it changed the document.
bool richEditorAutoformat(String id, Object event) {
  final input = event as web.InputEvent;
  if (input.inputType == 'insertParagraph') return _continueTask(id);
  if (input.inputType != 'insertText') return false;
  final data = input.data;
  if (data == null || data.isEmpty) return false;
  final range = _rangeIn(id);
  if (range == null || !range.collapsed) return false;
  final node = range.startContainer;
  if (node.nodeType != _kTextNode) return false;
  final textNode = node as web.Text;
  // Nothing formats inside literal code.
  if (_closest(id, const {'code', 'pre'}) != null) return false;
  final before = textNode.data.substring(0, range.startOffset);
  if (data == ' ' && _blockAutoformat(id, textNode, before)) return true;
  return _inlineAutoformat(textNode, before, range.startOffset);
}

/// A new item split off a task is a task too, the way a new bullet
/// follows a bullet.
bool _continueTask(String id) {
  final item = _closest(id, const {'li'});
  final previous = item?.previousElementSibling;
  if (item == null || previous == null || _isTaskItem(item)) return false;
  if (!_isTaskItem(previous)) return false;
  final box = _checkbox();
  item.insertBefore(box, item.firstChild);
  _caretAfterCheckbox(box);
  return true;
}

bool _blockAutoformat(String id, web.Text textNode, String before) {
  final marker = before
      .substring(0, before.length - 1)
      .replaceAll(
        _kCaretHolder,
        '',
      );
  final kind = _kBlockMarkers[marker];
  if (kind == null) return false;
  // The marker must be the very start of its block.
  final block = _block(id);
  final blockText = (block?.textContent ?? textNode.data).replaceAll(
    _kCaretHolder,
    '',
  );
  if (!blockText.startsWith(before.replaceAll(_kCaretHolder, ''))) {
    return false;
  }
  if (block != null && block.firstChild != textNode) {
    final first = block.firstChild;
    final isTaskBox =
        first != null &&
        first.nodeType == _kElementNode &&
        _tagOf(first as web.Element) == 'input';
    if (!isTaskBox || first.nextSibling != textNode) return false;
  }
  // An emptied line keeps a caret holder: the browser will not turn a
  // block with no text into another kind.
  final rest = textNode.data.substring(before.length);
  textNode.data = rest.isEmpty ? _kCaretHolder : rest;
  _placeCaret(textNode, rest.isEmpty ? 1 : 0);
  final inItem = block != null && _tagOf(block) == 'li';
  switch (kind) {
    case 'h1' || 'h2' || 'h3':
      if (inItem) return false;
      _exec('formatBlock', '<$kind>');
    case 'ul':
      if (inItem) return false;
      _toggleList(id, ordered: false, task: false);
    case 'ol':
      if (inItem) return false;
      _toggleList(id, ordered: true, task: false);
    case 'task':
      if (block != null && _isTaskItem(block)) return true;
      _toggleList(id, ordered: false, task: true);
    case 'quote':
      _toggleQuote(id);
  }
  return true;
}

bool _inlineAutoformat(web.Text textNode, String before, int caret) {
  for (final (pattern, tag) in _kInlineMarks) {
    final match = pattern.firstMatch(before);
    if (match == null) continue;
    // `(?:^|[^*])` may have eaten one leading character.
    var start = match.start;
    final whole = match.group(0)!;
    if (tag == 'em' && !whole.startsWith('*')) start += 1;
    String? href;
    if (tag == 'a') {
      href = CoreRichEditorContract.normalizeLink(match.group(2)!);
      if (href == null) continue;
    }
    final inner = match.group(1)!;
    final after = textNode.data.substring(caret);
    textNode.data = textNode.data.substring(0, start);
    final element = web.document.createElement(tag)..textContent = inner;
    if (href != null) element.setAttribute('href', href);
    final rest = web.document.createTextNode('$_kCaretHolder$after');
    textNode.parentNode!
      ..insertBefore(element, textNode.nextSibling)
      ..insertBefore(rest, element.nextSibling);
    _placeCaret(rest, 1);
    return true;
  }
  return false;
}

/// Whether a `beforeinput` [event] adds text.
bool richEditorInsertsText(Object event) {
  final type = (event as web.InputEvent).inputType;
  return type.startsWith('insert') && type != 'insertParagraph';
}

/// Pastes the clipboard as plain text, cut to [limit] characters when one
/// is given.
void richEditorPastePlainText(Object event, {int? limit}) {
  final paste = event as web.ClipboardEvent..preventDefault();
  var text = paste.clipboardData?.getData('text/plain') ?? '';
  if (limit != null && text.length > limit) {
    text = text.substring(0, limit < 0 ? 0 : limit);
  }
  if (text.isEmpty) return;
  web.document.execCommand('insertText', false, text);
}

// ═══════════════════════════════════════════════════
// Images
// ═══════════════════════════════════════════════════

/// A file the browser's picker handed over.
class _BrowserFile implements RichEditorPickedFile {
  _BrowserFile(this._file);

  final web.File _file;

  @override
  String get name => _file.name;

  @override
  String get mimeType => _file.type.toLowerCase();

  @override
  int get size => _file.size;

  @override
  Future<Uint8List> readBytes() async {
    final buffer = await _file.arrayBuffer().toDart;
    return buffer.toDart.asUint8List();
  }
}

/// A picker that is open: its hidden input and the answer it owes.
class _OpenPicker {
  _OpenPicker(this.input) : answer = Completer<RichEditorPickedFile?>();

  final web.HTMLInputElement input;
  final Completer<RichEditorPickedFile?> answer;

  void finish(RichEditorPickedFile? file) {
    input.remove();
    if (!answer.isCompleted) answer.complete(file);
  }
}

_OpenPicker? _openPicker;

/// Opens the browser's file picker for [accept] (MIME types and
/// `.extensions`) and completes with the chosen file, or null when the user
/// cancels. Must be called inside the click that asked for it: browsers
/// open the picker only for a user gesture.
Future<RichEditorPickedFile?> richEditorPickImage({
  required List<String> accept,
}) {
  // A browser that never says "cancelled" would leave the last input behind.
  _openPicker?.finish(null);
  final input = (web.document.createElement('input') as web.HTMLInputElement)
    ..type = 'file'
    ..accept = accept.join(',')
    ..setAttribute('hidden', '');
  final picker = _OpenPicker(input);
  _openPicker = picker;
  void done(RichEditorPickedFile? file) {
    picker.finish(file);
    if (identical(_openPicker, picker)) _openPicker = null;
  }

  input.addEventListener(
    'change',
    ((web.Event _) {
      final files = input.files;
      final file = files == null || files.length == 0 ? null : files.item(0);
      done(file == null ? null : _BrowserFile(file));
    }).toJS,
  );
  input.addEventListener('cancel', ((web.Event _) => done(null)).toJS);
  web.document.body?.append(input);
  input.click();
  return picker.answer.future;
}

/// Keeps a file dragged onto the surface out of it. Left alone, the browser
/// would put its own `<img>` there — a `blob:` or `file:` address the value
/// cannot keep, shown in the editor but missing from the Markdown. Images come
/// in through the button. Text and other drags are untouched. Returns whether
/// the drag carried files.
bool richEditorBlockFileDrop(Object event) {
  final drag = event as web.DragEvent;
  final transfer = drag.dataTransfer;
  if (transfer == null) return false;
  final types = transfer.types.toDart;
  var carriesFiles = false;
  for (final type in types) {
    if (type.toDart == 'Files') carriesFiles = true;
  }
  if (!carriesFiles) return false;
  drag.preventDefault();
  // The pointer shows that nothing will land.
  transfer.dropEffect = 'none';
  return true;
}

/// Selects the image a click landed on, so it shows as selected and one
/// Backspace or Delete removes it — a browser would only put the caret beside
/// it. Returns whether the click was on an image.
bool richEditorSelectImage(Object event) {
  final target = (event as web.Event).target;
  if (target == null || !target.isA<web.Element>()) return false;
  final element = target as web.Element;
  if (_tagOf(element) != 'img') return false;
  final selection = web.window.getSelection();
  if (selection == null) return false;
  final range = web.document.createRange()..selectNode(element);
  selection
    ..removeAllRanges()
    ..addRange(range);
  return true;
}

/// Where each image being added goes: a live clone of the selection at the
/// moment its button was pressed, by anchor id. A live range follows the
/// document as the user keeps typing while the file uploads.
final Map<String, web.Range> _anchors = {};
var _anchorSeq = 0;

/// Remembers where the caret is and returns the id an image is inserted at
/// later with [richEditorInsertImage], or null when there is no surface.
String? richEditorMarkAnchor(String id) {
  if (_surface(id) == null) return null;
  final range = _rangeIn(id) ?? _savedRanges[id];
  final anchor = 'anchor-${_anchorSeq++}';
  if (range != null) _anchors[anchor] = range.cloneRange();
  return anchor;
}

/// Forgets the anchor [anchor] — the image it was kept for was not added.
void richEditorDropAnchor(String anchor) => _anchors.remove(anchor);

/// The child of [surface] that holds [node], or null when [node] is not
/// inside it.
web.Node? _topLevelBlock(web.Element surface, web.Node node) {
  web.Node? current = node;
  while (current != null && current.parentNode != surface) {
    current = current.parentNode;
  }
  return current;
}

/// Whether [node] is a paragraph with nothing in it.
bool _isEmptyParagraph(web.Node node) {
  if (node.nodeType != _kElementNode) return false;
  final element = node as web.Element;
  final tag = _tagOf(element);
  if (tag != 'p' && tag != 'div') return false;
  if (element.querySelector(
        'img,input,hr,pre,ul,ol,blockquote,h1,h2,h3,h4,h5,h6',
      ) !=
      null) {
    return false;
  }
  return (element.textContent ?? '')
      .replaceAll(_kCaretHolder, '')
      .trim()
      .isEmpty;
}

/// Inserts the image [src] as a block of its own after the top-level block
/// that holds the anchor [anchor] — in front of it when that block is an
/// empty paragraph, which then stays as the line to continue on — with an
/// empty paragraph after the image, and puts the caret there. An anchor that
/// is gone appends at the end. Returns whether it inserted.
bool richEditorInsertImage(String id, String anchor, String src, String alt) {
  final surface = _surface(id);
  final range = _anchors.remove(anchor);
  final address = CoreRichEditorImage.normalizeSource(src);
  if (surface == null || address == null) return false;

  web.Node? before;
  if (range != null && surface.contains(range.startContainer)) {
    if (range.startContainer == surface) {
      before = surface.childNodes.item(range.startOffset);
    } else {
      final block = _topLevelBlock(surface, range.startContainer);
      if (block != null) {
        before = _isEmptyParagraph(block) ? block : block.nextSibling;
      }
    }
  }

  final image = web.document.createElement('img')
    ..setAttribute('src', address)
    ..setAttribute('alt', alt);
  final block = web.document.createElement('p')..append(image);
  surface.insertBefore(block, before);

  var next = block.nextSibling;
  if (next == null || !_isEmptyParagraph(next)) {
    next = web.document.createElement('p')
      ..append(web.document.createElement('br'));
    surface.insertBefore(next, block.nextSibling);
  }
  surface.focus();
  _placeCaret(next, 0);
  return true;
}
