/// Plays a [KeyboardProbeSpec] against the hydrated docs site (#4154).
///
/// The page is the real one — `jaspr build` output served over HTTP, so the
/// `WebPreview` island hydrates and its key handlers are the compiled
/// client's, the ones a user gets. Each step presses one key through the
/// DevTools input domain (a trusted event, like a real keyboard) and then
/// reads where focus is: `document.activeElement`, its roving marker, or
/// the option its `aria-activedescendant` names. What is asserted is the
/// focus **result**; whether a handler is attached is only used to know
/// the island has hydrated before the first key.
library;

import 'dart:async';
import 'dart:convert';

import 'package:puppeteer/puppeteer.dart' as pptr;

import 'docs_page.dart';
import 'keyboard_probe_spec.dart';

/// How long one step may take to settle. A key's effect can land a frame
/// or two late — a panel mounts post-frame and only then takes focus — so
/// the probe polls for the expected state and reports the last one it saw.
const _kStepTimeout = Duration(seconds: 2);

/// How long the island may take to hydrate once the page has loaded.
const _kHydrationTimeout = Duration(seconds: 30);

/// Interval between polls while waiting for a step to settle.
const _kPollInterval = Duration(milliseconds: 50);

/// Interval between hydration checks.
const _kHydrationPollInterval = Duration(milliseconds: 200);

/// Where focus was observed after a step.
class KeyboardProbeObservation {
  /// Creates a [KeyboardProbeObservation].
  const KeyboardProbeObservation({
    required this.description,
    this.index,
    this.itemCount,
    this.itemText,
    this.collectionLabelOk = true,
    this.expanded,
    this.problem,
  });

  /// Parses the page-side JSON.
  factory KeyboardProbeObservation.fromJson(Map<String, Object?> json) =>
      KeyboardProbeObservation(
        description: json['description']! as String,
        index: json['index'] as int?,
        itemCount: json['itemCount'] as int?,
        itemText: json['itemText'] as String?,
        collectionLabelOk: json['collectionLabelOk'] as bool? ?? true,
        expanded: switch (json['expanded']) {
          'true' => true,
          'false' => false,
          _ => null,
        },
        problem: json['problem'] as String?,
      );

  /// Human-readable summary of the focused element.
  final String description;

  /// The active item's index, or `null` when there is none.
  final int? index;

  /// How many items the active item's collection holds — resolves
  /// negative indices and wraps relative ones.
  final int? itemCount;

  /// The active item's text, whitespace-collapsed.
  final String? itemText;

  /// Whether focus is in the collection the step's label is bound to (and
  /// no other label is bound to that collection).
  final bool collectionLabelOk;

  /// `aria-expanded` on the focused element.
  final bool? expanded;

  /// A structural defect found while reading (a dangling
  /// `aria-activedescendant`, a collection with more than one tab stop).
  final String? problem;
}

/// One step that did not land where the spec says.
class KeyboardProbeFailure {
  /// Creates a [KeyboardProbeFailure].
  const KeyboardProbeFailure({
    required this.component,
    required this.step,
    required this.message,
  });

  /// The spec's component slug.
  final String component;

  /// 0 for the entry, then 1-based step position.
  final int step;

  /// What was expected and what was seen.
  final String message;

  @override
  String toString() => '$component · step $step · $message';
}

/// The outcome of one spec.
class KeyboardProbeResult {
  /// Creates a [KeyboardProbeResult].
  const KeyboardProbeResult({required this.spec, required this.failures});

  /// The spec played.
  final KeyboardProbeSpec spec;

  /// Every mismatch, in order — empty when every step landed.
  final List<KeyboardProbeFailure> failures;

  /// Whether every step landed.
  bool get passed => failures.isEmpty;
}

/// Opens `/embed/<component>/` under [baseUrl] in [page] and plays
/// [spec] against it.
Future<KeyboardProbeResult> runKeyboardProbe(
  pptr.Page page, {
  required Uri baseUrl,
  required KeyboardProbeSpec spec,
}) async {
  await loadDocsEmbedPage(
    page,
    baseUrl: baseUrl,
    component: spec.component,
  );
  final deliveryFailure = await _awaitKeyDelivery(page);
  if (deliveryFailure != null) {
    return KeyboardProbeResult(
      spec: spec,
      failures: [
        KeyboardProbeFailure(
          component: spec.component,
          step: 0,
          message: deliveryFailure,
        ),
      ],
    );
  }

  final entryFailure = await _focusEntry(page, spec);
  if (entryFailure != null) {
    return KeyboardProbeResult(
      spec: spec,
      failures: [
        KeyboardProbeFailure(
          component: spec.component,
          step: 0,
          message: entryFailure,
        ),
      ],
    );
  }

  final failures = <KeyboardProbeFailure>[];
  final entry = await _observe(page, spec, kKeyboardProbeMainCollection);
  final entryMismatch = _mismatch(
    spec,
    entry,
    _Expectation(index: spec.startIndex, expanded: spec.startExpanded),
  );
  if (entryMismatch != null) {
    failures.add(
      KeyboardProbeFailure(
        component: spec.component,
        step: 0,
        message: 'entry: $entryMismatch',
      ),
    );
  }

  var previous = entry.index;
  for (final (position, step) in spec.steps.indexed) {
    await _press(page, step.key);
    final expectation = _Expectation.of(step, previous: previous);
    final deadline = DateTime.now().add(_kStepTimeout);
    KeyboardProbeObservation seen;
    String? mismatch;
    do {
      await Future<void>.delayed(_kPollInterval);
      seen = await _observe(page, spec, step.collection);
      mismatch = _mismatch(spec, seen, expectation);
    } while (mismatch != null && DateTime.now().isBefore(deadline));
    if (mismatch != null) {
      failures.add(
        KeyboardProbeFailure(
          component: spec.component,
          step: position + 1,
          message: '${_keyLabel(step.key)} → $mismatch',
        ),
      );
      // Every later step starts from where this one should have left
      // focus; once it did not, what follows measures the wrong thing.
      break;
    }
    previous = seen.index;
  }

  return KeyboardProbeResult(spec: spec, failures: failures);
}

/// What one step expects, with its relative part bound to the index the
/// step before it observed.
class _Expectation {
  const _Expectation({
    this.index,
    this.offset,
    this.previous,
    this.label,
    this.expanded,
  });

  factory _Expectation.of(KeyboardProbeStep step, {required int? previous}) =>
      _Expectation(
        index: step.index,
        offset: step.offset,
        previous: previous,
        label: step.label,
        expanded: step.expanded,
      );

  final int? index;
  final int? offset;
  final int? previous;
  final String? label;
  final bool? expanded;

  bool get expectsItem => index != null || offset != null || label != null;

  /// The index this expectation names once the collection's length is
  /// known, or `null` when it names none (a label-only step).
  int? resolve(int? count) {
    final by = offset;
    if (by != null) {
      final from = previous;
      if (from == null || count == null || count == 0) return null;
      return ((from + by) % count + count) % count;
    }
    final at = index;
    if (at == null) return null;
    if (at >= 0) return at;
    return count == null ? null : count + at;
  }
}

/// Proves the page receives key events before the sequence's first key.
///
/// A page that is not the browser's foreground target can drop a key the
/// DevTools input domain sends it, and the first press of a fresh browser
/// was lost that way — the step then failed as if the component had
/// ignored the key. `Shift` is the handshake because no collection acts on
/// it (it is not a navigation key and not a printable character).
Future<String?> _awaitKeyDelivery(pptr.Page page) async {
  await page.bringToFront();
  await page.evaluate<void>(
    '() => { window.__couiKeyboardProbeKeys = 0; '
    'window.addEventListener("keydown", '
    '() => window.__couiKeyboardProbeKeys++, true); }',
  );
  final deadline = DateTime.now().add(_kHydrationTimeout);
  while (DateTime.now().isBefore(deadline)) {
    await page.keyboard.press(pptr.Key.shift);
    await Future<void>.delayed(_kHydrationPollInterval);
    final seen = await page.evaluate<int>(
      '() => window.__couiKeyboardProbeKeys',
    );
    if (seen > 0) return null;
  }
  return 'the page never received a key event '
      '(${_kHydrationTimeout.inSeconds}s)';
}

/// Focuses the sequence's entry once the island has hydrated — pressing
/// the opener first when the spec has one. Returns a failure message, or
/// `null` once the entry has focus.
Future<String?> _focusEntry(pptr.Page page, KeyboardProbeSpec spec) async {
  final opener = spec.opener;
  if (opener != null) {
    final failure = await _focusWhenHydrated(
      page,
      spec,
      scope: null,
      selector: opener.selector,
    );
    if (failure != null) return 'opener: $failure';
    await _press(page, opener.key);
  }
  return await _focusWhenHydrated(
    page,
    spec,
    scope: spec.entryScope,
    selector: spec.effectiveEntrySelector,
  );
}

/// Waits until [selector] inside [scope] — a selector inside the Web pane,
/// or the pane itself when `null` — exists and has hydrated, then focuses
/// it. Returns a failure message, or `null` once it has focus.
///
/// Hydration is read off the listeners: `getEventListeners` (a DevTools
/// console API, hence `includeCommandLineAPI`) finds a key or click
/// listener on the element or an ancestor only once the client build has
/// attached its handlers — the SSR markup has none.
Future<String?> _focusWhenHydrated(
  pptr.Page page,
  KeyboardProbeSpec spec, {
  required String? scope,
  required String selector,
}) async {
  final where = scope == null ? '#${spec.paneId}' : '#${spec.paneId} $scope';
  final deadline = DateTime.now().add(_kHydrationTimeout);
  final runtime = page.devTools.runtime;
  var state = 'missing-scope';
  while (DateTime.now().isBefore(deadline)) {
    final result = await runtime.evaluate(
      '''
(() => {
  const pane = document.getElementById(${jsonEncode(spec.paneId)});
  const scopeSelector = ${jsonEncode(scope)};
  const scope = pane && (scopeSelector ? pane.querySelector(scopeSelector) : pane);
  if (!scope) return 'missing-scope';
  const target = scope.querySelector(${jsonEncode(selector)});
  if (!target) return 'missing';
  for (let el = target; el; el = el.parentElement) {
    const listeners = getEventListeners(el);
    if ((listeners.keydown || []).length || (listeners.click || []).length) {
      target.scrollIntoView({block: 'center'});
      target.focus();
      return document.activeElement === target ? 'ok' : 'not-focusable';
    }
    if (el === scope) break;
  }
  return 'not-hydrated';
})()
''',
      includeCommandLineAPI: true,
      returnByValue: true,
    );
    state = result.result.value as String? ?? 'missing';
    if (state == 'ok') return null;
    if (state == 'not-focusable') {
      return '`$selector` in `$where` did not take focus';
    }
    await Future<void>.delayed(_kHydrationPollInterval);
  }
  return switch (state) {
    'missing-scope' => 'no `$where` on /embed/${spec.component}/',
    'missing' => 'no `$selector` in `$where`',
    _ =>
      '`$selector` in `$where` never hydrated (no key or click listener '
          'within ${_kHydrationTimeout.inSeconds}s)',
  };
}

Future<void> _press(pptr.Page page, String key) async {
  if (key.length == 1) {
    await page.keyboard.type(key);
    return;
  }
  final named = pptr.Key.allKeys[key];
  if (named == null) throw ArgumentError.value(key, 'key', 'no such key');
  await page.keyboard.press(named);
}

String _keyLabel(String key) => key == ' ' ? 'Space' : key;

/// Compares [seen] to [expectation], returning what differs or `null`.
String? _mismatch(
  KeyboardProbeSpec spec,
  KeyboardProbeObservation seen,
  _Expectation expectation,
) {
  final focus = '(focus: ${seen.description})';
  if (seen.problem != null) return '${seen.problem} $focus';
  if (!seen.collectionLabelOk) {
    return 'focus is in the wrong collection $focus';
  }
  final noun = spec.mode == .roving ? 'focused item' : 'active option';
  if (!expectation.expectsItem) {
    if (seen.index != null) {
      return 'expected no $noun, saw ${seen.index} $focus';
    }
  } else {
    if (seen.index == null) return 'expected an $noun, saw none $focus';
    final wanted = expectation.resolve(seen.itemCount);
    final label = expectation.label;
    if (label == null && wanted == null) {
      return 'could not resolve the expected $noun — no item count $focus';
    }
    if (wanted != null && seen.index != wanted) {
      return 'expected $noun $wanted, saw ${seen.index} $focus';
    }
    if (label != null && !(seen.itemText ?? '').contains(label)) {
      return 'expected the $noun to read "$label", saw "${seen.itemText}" '
          '$focus';
    }
  }
  final expanded = expectation.expanded;
  if (expanded != null && seen.expanded != expanded) {
    return 'expected aria-expanded=$expanded, saw ${seen.expanded} $focus';
  }
  return null;
}

/// Reads where focus is. [label] binds the step's collection label to the
/// collection element focus is in (see [KeyboardProbeStep.collection]).
Future<KeyboardProbeObservation> _observe(
  pptr.Page page,
  KeyboardProbeSpec spec,
  String label,
) async {
  final json = await page.evaluate<String>(
    r'''
(mode, label) => {
  const a = document.activeElement;
  const out = {};
  const text = (el) => (el.textContent || '').trim().replace(/\s+/g, ' ');
  const describe = (el) => {
    if (!el || el === document.body) return '<body>';
    const role = el.getAttribute('role');
    return `<${el.tagName.toLowerCase()}${role ? ` role=${role}` : ''}` +
      `${el.id ? ` id=${el.id}` : ''}> "${text(el).slice(0, 32)}"`;
  };
  out.description = describe(a);
  if (!a || a === document.body) return JSON.stringify(out);
  out.expanded = a.getAttribute('aria-expanded');

  if (mode === 'roving') {
    const marker = a.getAttribute('data-roving-item');
    if (!marker) return JSON.stringify(out);
    const cut = marker.lastIndexOf(':');
    const host = marker.slice(0, cut);
    out.index = Number(marker.slice(cut + 1));
    out.itemText = text(a);
    const collection = a.closest(
      '[role=tree],[role=tablist],[role=listbox],[role=menu],' +
      '[role=menubar],[role=radiogroup],[role=grid]');
    const bound = (window.__couiKeyboardProbe ??= {});
    if (bound[label] === undefined) bound[label] = collection;
    out.collectionLabelOk = collection !== null &&
      bound[label] === collection &&
      Object.entries(bound).every(([k, v]) => k === label || v !== collection);
    const items = document.querySelectorAll(
      `[data-roving-item^="${CSS.escape(host)}:"]`);
    out.itemCount = items.length;
    // The collection is one tab stop from outside, whatever the arrows did.
    const stops = [...items].filter(
      (el) => el.getAttribute('tabindex') === '0').length;
    if (stops !== 1) out.problem = `${stops} tab stops in the collection`;
    return JSON.stringify(out);
  }

  const id = a.getAttribute('aria-activedescendant');
  if (!id) return JSON.stringify(out);
  const option = document.getElementById(id);
  if (!option) {
    out.problem = `aria-activedescendant="${id}" names no element`;
    return JSON.stringify(out);
  }
  const listbox = option.closest('[role=listbox]');
  if (!listbox) {
    out.problem = `#${id} is not inside a role=listbox`;
    return JSON.stringify(out);
  }
  const controls = a.getAttribute('aria-controls');
  if (controls) {
    const controlled = document.getElementById(controls);
    if (!controlled || !controlled.contains(option)) {
      out.problem = `aria-controls="${controls}" does not contain #${id}`;
      return JSON.stringify(out);
    }
  }
  const options = [...listbox.querySelectorAll('[role=option]')];
  out.index = options.indexOf(option);
  out.itemCount = options.length;
  out.itemText = text(option);
  if (out.index < 0) out.problem = `#${id} is not a role=option`;
  return JSON.stringify(out);
}
''',
    args: [spec.mode.name, label],
  );
  return KeyboardProbeObservation.fromJson(
    jsonDecode(json) as Map<String, Object?>,
  );
}
