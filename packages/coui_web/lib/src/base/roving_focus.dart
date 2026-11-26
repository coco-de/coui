// Roving-focus keyboard support shared by every Web collection that
// exports a composite ARIA role (`menu` · `menubar` · `tree` · `listbox` ·
// `tablist`).
//
// A composite role is a promise: the WAI-ARIA Authoring Practices say the
// collection is **one** tab stop from the outside and the arrow keys move
// within it. Emitting the role without that is worse than emitting no role
// at all — a screen-reader user hears "tree" and presses an arrow that does
// nothing. Each collection answers the same three questions (which item
// holds the tab stop, where does a key move it, and how does DOM focus
// follow), so the answers live here once instead of drifting per component.
//
// The key → index arithmetic is pure Dart so the VM test suite can pin it
// — `universal_web`'s `KeyboardEvent.key` getter throws outside a browser,
// which is why the live dispatch itself is not what the tests exercise.

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:jaspr/jaspr.dart' show EventCallback;
import 'package:universal_web/web.dart' as web;

/// Attribute every roving item carries so DOM focus can find it.
///
/// The value is `<hostId>:<index>` rather than the bare index: collections
/// nest (a menu row expands an inline submenu, a tree renders inside a
/// panel), and a bare index would let the outer host's query land on the
/// inner collection's row with the same number.
const String kRovingItemAttribute = 'data-roving-item';

/// How long a typeahead run stays open — a pause longer than this starts a
/// new search rather than extending the last one (the WAI-ARIA convention,
/// and the interval Windows and macOS menus use).
const Duration kRovingTypeaheadWindow = Duration(
  milliseconds: CoreDuration.slow,
);

/// The attributes that put item [index] of the collection hosted by
/// [hostId] into the roving rotation.
///
/// Exactly one item — the [active] one — is a tab stop (`tabindex="0"`);
/// every other item is `tabindex="-1"`: focusable by script, skipped by
/// Tab. That is what makes the whole collection one stop from outside.
Map<String, String> rovingItemAttributes(
  String hostId,
  int index, {
  required bool active,
}) => {
  'tabindex': active ? '0' : '-1',
  kRovingItemAttribute: '$hostId:$index',
};

/// Moves DOM focus to item [index] of the collection hosted by [hostId].
///
/// The tab stop and the focused element must move together — a `tabindex`
/// that moves without the focus moving leaves the ring on the item the
/// user just left. No-op on the server.
void focusRovingItem(String hostId, int index) =>
    focusElementBySelector('[$kRovingItemAttribute="$hostId:$index"]');

/// Index of the roving item of [hostId] that [event] came from — the item
/// holding DOM focus when a key was pressed — or `null` outside one.
///
/// Lets a collection with no focus state of its own (a tablist whose tab
/// stop is simply its selected tab) find where an arrow key starts from.
int? rovingIndexOfEvent(Object event, String hostId) {
  final prefix = '$hostId:';
  final value = closestAttributeWithPrefix(
    event,
    kRovingItemAttribute,
    prefix,
  );
  return value == null ? null : int.tryParse(value.substring(prefix.length));
}

/// Where an arrow / `Home` / `End` key moves the active item of a
/// one-dimensional collection of [count] items, or `null` when [key] is not
/// a navigation key for that collection.
///
/// [vertical] picks the arrow pair the collection walks — pressing "down"
/// in a horizontal tablist would otherwise move along nothing, and the
/// cross-axis pair is left to the page (or, in a tree, to expand/collapse).
/// With [wrap] the ends join (menus, tablists); without it the ends are
/// walls (listboxes, trees), which is what the pattern specifies for
/// collections a user scans rather than cycles.
///
/// With [columns] above one the items are laid out row-major in a grid and
/// both arrow pairs apply — Left/Right step one item, Up/Down step one row
/// (a whole row is [columns] items) — without wrapping: a key that would
/// leave the grid leaves focus where it is. [vertical] and [wrap] are then
/// ignored.
int? rovingTargetIndex(
  String key, {
  required int current,
  required int count,
  required bool vertical,
  bool wrap = true,
  int columns = 1,
}) {
  if (count <= 0) return null;
  if (columns > 1) {
    final target = switch (key) {
      'ArrowRight' => current + 1,
      'ArrowLeft' => current - 1,
      'ArrowDown' => current + columns,
      'ArrowUp' => current - columns,
      'Home' => 0,
      'End' => count - 1,
      _ => null,
    };
    if (target == null) return null;
    return target < 0 || target >= count ? current : target;
  }
  final forward = vertical ? 'ArrowDown' : 'ArrowRight';
  final backward = vertical ? 'ArrowUp' : 'ArrowLeft';
  final int target;
  if (key == forward) {
    target = current + 1;
  } else if (key == backward) {
    target = current - 1;
  } else if (key == 'Home') {
    return 0;
  } else if (key == 'End') {
    return count - 1;
  } else {
    return null;
  }
  if (wrap) return (target % count + count) % count;
  return target.clamp(0, count - 1);
}

/// Whether a keypress is a typeahead character — one printable character
/// with no command modifier. Modifier chords are shortcuts and belong to
/// the page; Shift is allowed because it only picks the character's case.
bool isRovingTypeaheadKey(
  String key, {
  bool ctrl = false,
  bool meta = false,
  bool alt = false,
}) => key.length == 1 && !ctrl && !meta && !alt;

/// Type-to-jump for a roving collection: typed characters accumulate while
/// they arrive within [kRovingTypeaheadWindow] and move to the first item
/// whose label starts with the run.
class RovingTypeahead {
  /// Creates a [RovingTypeahead]. [clock] is injectable so the window can
  /// be tested without sleeping.
  RovingTypeahead({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  /// Letters typed inside the current window.
  String _buffer = '';

  /// When the current run started.
  DateTime? _startedAt;

  /// Extends (or restarts) the run with [character] and returns the index
  /// of the first label, searching from the item after [current], that
  /// starts with it — or `null` when nothing matches.
  ///
  /// Searching from the *next* item makes repeated presses of one letter
  /// cycle through the items that share it. A space that would *start* a
  /// run is not a search: it is the activation key of the item the user
  /// is on.
  int? next(
    String character, {
    required List<String> labels,
    required int current,
  }) {
    final now = _clock();
    final expired =
        _startedAt == null ||
        now.difference(_startedAt!) > kRovingTypeaheadWindow;
    if (expired && character == ' ') return null;
    _buffer = (expired ? '' : _buffer) + character.toLowerCase();
    _startedAt = now;

    if (labels.isEmpty) return null;
    // A run of one repeated letter ("sss") means "the next item with that
    // letter", not "an item starting with sss".
    final repeated = _buffer.split('').toSet().length == 1;
    final query = repeated ? _buffer[0] : _buffer;
    // Nothing active yet (`current < 0`) searches from the top.
    final start = current < 0 ? 0 : (repeated ? current + 1 : current);
    for (var offset = 0; offset < labels.length; offset++) {
      final index = (start + offset) % labels.length;
      if (labels[index].toLowerCase().startsWith(query)) return index;
    }
    return null;
  }
}

/// Resolves a live keydown on a roving collection to the index focus should
/// move to, calling `preventDefault` when the key was consumed.
///
/// Returns `null` for keys the collection does not own, and for a key an
/// inner collection already consumed — collections nest, and the keydown
/// bubbles through the outer host after the inner one moved its own focus.
/// [labels] enables typeahead; leave it `null` for collections the pattern
/// does not give one (tablists).
int? rovingKeyTarget(
  web.KeyboardEvent event, {
  required int current,
  required int count,
  required bool vertical,
  bool wrap = true,
  int columns = 1,
  List<String>? labels,
  RovingTypeahead? typeahead,
}) {
  if (event.defaultPrevented) return null;
  final key = event.key;
  var target = rovingTargetIndex(
    key,
    current: current,
    count: count,
    vertical: vertical,
    wrap: wrap,
    columns: columns,
  );
  if (target == null &&
      labels != null &&
      typeahead != null &&
      isRovingTypeaheadKey(
        key,
        ctrl: event.ctrlKey,
        meta: event.metaKey,
        alt: event.altKey,
      )) {
    target = typeahead.next(key, labels: labels, current: current);
  }
  if (target != null) event.preventDefault();
  return target;
}

/// Adds roving arrow keys to [base] for a collection whose tab stop does
/// not move with focus — a tablist, where the stop stays on the selected
/// tab and the arrows only move focus between tabs until one is picked.
///
/// The arrow starts from the item that holds DOM focus (read off the event,
/// so the collection needs no focus state), falling back to [tabStop]. A
/// caller's own `keydown` in [base] is kept and runs first.
///
/// With [bothAxes] every arrow walks the collection — Right/Down forward,
/// Left/Up back — which is what a radio group does. [onMove] runs after
/// focus has moved, for a collection whose selection follows focus (a radio
/// group checks the radio an arrow lands on).
Map<String, EventCallback> withRovingKeys(
  Map<String, EventCallback> base, {
  required String hostId,
  required int count,
  required int tabStop,
  required bool vertical,
  bool wrap = true,
  bool bothAxes = false,
  void Function(int index)? onMove,
}) => {
  ...base,
  'keydown': EventHandlers.chain(
    base['keydown'],
    EventHandlers.createKeyboardEventHandler((event) {
      final current = rovingIndexOfEvent(event, hostId) ?? tabStop;
      var target = rovingKeyTarget(
        event,
        current: current,
        count: count,
        vertical: vertical,
        wrap: wrap,
      );
      if (target == null && bothAxes) {
        target = rovingKeyTarget(
          event,
          current: current,
          count: count,
          vertical: !vertical,
          wrap: wrap,
        );
      }
      if (target == null) return;
      focusRovingItem(hostId, target);
      onMove?.call(target);
    }),
  ),
};
