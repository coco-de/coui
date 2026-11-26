/// What each Web collection promises the keyboard, as data (#4154).
///
/// A composite ARIA role — `tree` · `listbox` · `tablist` · `menu` ·
/// `menubar` · `radiogroup` · `combobox` — is a promise that the arrow keys
/// move through the collection. The shared helper that keeps that promise
/// (`coui_web`'s `roving_focus.dart`) is pinned by VM tests, but those tests
/// cannot press a key: `universal_web`'s `KeyboardEvent.key` throws outside
/// a browser. So they prove the arithmetic and never the result a user
/// feels — whether DOM focus actually moved after the page hydrated.
///
/// This file is the other half: for every collection, a sequence of keys
/// and where focus has to be after each one. `keyboard_probe.dart` plays
/// the sequence in a real browser against the hydrated docs site and reads
/// `document.activeElement` — the focus **result**, never whether a
/// handler is registered. The page it opens is `/embed/<component>`, which
/// mounts the component's default registry example and does not depend on
/// what the component's docs page renders. The table itself is pure data so
/// the VM suite can hold it to the same arithmetic the helper uses
/// ([keyboardProbeModelMismatches]); a spec that disagrees with the helper
/// would otherwise make the browser run fail for a reason that is not a
/// defect.
library;

// The roving arithmetic is deliberately not exported from the barrel — it
// is how the Web collections are built, not an API for callers. The spec
// reaches for the one function it replays rather than widening the public
// surface to make a check easier.
import 'package:coui_web/src/base/roving_focus.dart' show rovingTargetIndex;
import 'package:docs_core/shared/preview_panel_id.dart'
    show webPreviewElementId;

/// How a collection reports which item is active.
enum KeyboardProbeMode {
  /// DOM focus itself moves: the focused element carries
  /// `data-roving-item="<host>:<index>"` (tree, tablist, menu, listbox,
  /// radio group). The probe reads the index off `document.activeElement`.
  roving,

  /// DOM focus stays in a combobox's text field and the field's
  /// `aria-activedescendant` names the active `role="option"` (Select,
  /// Autocomplete, Command, PhoneInput's country search). The probe
  /// resolves that id to its position among the options of its listbox.
  activeDescendant,
}

/// The layout a collection's arrow keys walk — the same parameters
/// `rovingTargetIndex` takes, so the VM suite can replay a spec against it.
class KeyboardProbeModel {
  /// Creates a [KeyboardProbeModel].
  const KeyboardProbeModel({
    required this.count,
    required this.vertical,
    this.wrap = true,
  });

  /// Items in the rotation when the sequence starts.
  final int count;

  /// Whether Up/Down (rather than Left/Right) walk the collection.
  final bool vertical;

  /// Whether the ends join.
  final bool wrap;
}

/// One key press and where focus must be afterwards.
class KeyboardProbeStep {
  /// Creates a [KeyboardProbeStep].
  const KeyboardProbeStep(
    this.key, {
    this.index,
    this.offset,
    this.label,
    this.collection = kKeyboardProbeMainCollection,
    this.expanded,
    this.structural = false,
    this.count,
  });

  /// The `KeyboardEvent.key` pressed — a named key (`ArrowDown`, `Home`,
  /// `Enter`, `Escape`) or one printable character (typeahead).
  final String key;

  /// The active item after the press. Negative counts from the end
  /// (`-1` is the last item), for collections whose length the page
  /// decides (a country list). `null` in [KeyboardProbeMode.activeDescendant]
  /// means "no active option" — the combobox is closed, or open with
  /// nothing highlighted.
  final int? index;

  /// The active item after the press, relative to the one before it —
  /// `1` is "the next item", wrapping over the observed option count. For
  /// sequences that start from a position the page decides (the current
  /// country), where an absolute index would pin the fixture's data.
  final int? offset;

  /// Text the active item's label must contain — for the one step that
  /// fixes a page-decided starting point, so the relative steps after it
  /// measure from something the spec actually states.
  final String? label;

  /// Whether the step states any active item at all. A step with none of
  /// [index], [offset] and [label] asserts that nothing is active (in
  /// [KeyboardProbeMode.activeDescendant]: a closed combobox).
  bool get expectsItem => index != null || offset != null || label != null;

  /// Which collection focus must be in, by label. The first time a label
  /// is seen the probe binds it to the collection element focus is in;
  /// every later step with that label must be in the **same element**, and
  /// two labels must never share one. A menubar's bar and its open panel
  /// are two collections; a tablist stays one even when its host re-renders
  /// under a new id.
  final String collection;

  /// `aria-expanded` expected on the focused element, when stated —
  /// a tree row's open state, or a combobox's popup state.
  final bool? expanded;

  /// Whether this key does something the one-dimensional arithmetic does
  /// not describe (open a panel, expand a tree row, step out to a parent),
  /// so the VM replay skips it rather than disagreeing with it.
  final bool structural;

  /// Items in the rotation after this step, when the step changed it
  /// (a tree row expanding adds its children). Used by the VM replay.
  final int? count;
}

/// A key pressed on [selector] (inside the Web pane) before a sequence
/// starts, to open the panel its collection lives in.
class KeyboardProbeOpener {
  /// Creates a [KeyboardProbeOpener].
  const KeyboardProbeOpener(this.selector, this.key);

  /// The element focused and pressed.
  final String selector;

  /// The `KeyboardEvent.key` pressed on it.
  final String key;
}

/// Label of the collection a sequence starts in.
const String kKeyboardProbeMainCollection = 'main';

/// A collection, the page it is shown on, and the keys it must honour.
class KeyboardProbeSpec {
  /// Creates a [KeyboardProbeSpec].
  const KeyboardProbeSpec({
    required this.component,
    required this.mode,
    required this.steps,
    this.opener,
    this.entryScope,
    this.entrySelector,
    this.startIndex,
    this.startExpanded,
    this.model,
  });

  /// docs_site component slug — the page is `/embed/<component>/`.
  final String component;

  /// How the active item is read.
  final KeyboardProbeMode mode;

  /// A key pressed on another element before the sequence starts — for a
  /// collection that only exists once a panel is open.
  final KeyboardProbeOpener? opener;

  /// CSS selector, inside the Web pane, of the element the entry is
  /// searched in — the pane itself when `null`. A collection rendered into a
  /// portaled panel lives in one of the pane's overlay layers
  /// (`#coui-overlay-<layer>`). Every `CoUIWeb` root mounts its own layers
  /// under the same ids, so the lookup never leaves the pane: a
  /// document-wide query would land on another preview's layer.
  final String? entryScope;

  /// CSS selector, inside the Web pane, of the element the sequence starts
  /// on. Defaults to the collection's tab stop in [KeyboardProbeMode.roving]
  /// and the combobox in [KeyboardProbeMode.activeDescendant].
  final String? entrySelector;

  /// Active item once the entry has focus, before any key — `null` in
  /// [KeyboardProbeMode.activeDescendant] means nothing is active yet.
  final int? startIndex;

  /// `aria-expanded` on the entry once it has focus, when stated.
  final bool? startExpanded;

  /// The arithmetic the arrow keys follow, when the collection has one
  /// fixed length the spec can state.
  final KeyboardProbeModel? model;

  /// The presses, in order.
  final List<KeyboardProbeStep> steps;

  /// The Web pane's id on the embed page. The route is generated statically,
  /// so the pane it serves is always the default variant's.
  String get paneId => webPreviewElementId(component: component);

  /// [entrySelector], or the default for [mode].
  String get effectiveEntrySelector =>
      entrySelector ??
      switch (mode) {
        .roving => '[data-roving-item][tabindex="0"]',
        .activeDescendant => '[role="combobox"]',
      };
}

/// Replays every non-structural step of [spec] against `rovingTargetIndex`
/// and returns one line per step the spec and the helper disagree on.
///
/// Only steps that stay in the collection the sequence is walking can be
/// replayed — a step into another collection (a menubar's panel) or a
/// structural step breaks the chain, and the next replayable step starts
/// from whatever that step stated.
List<String> keyboardProbeModelMismatches(KeyboardProbeSpec spec) {
  final model = spec.model;
  if (model == null) return const [];
  final mismatches = <String>[];
  var count = model.count;
  var current = spec.startIndex;
  var collection = kKeyboardProbeMainCollection;
  for (final (position, step) in spec.steps.indexed) {
    final replayable =
        !step.structural &&
        current != null &&
        step.index != null &&
        step.offset == null &&
        step.collection == kKeyboardProbeMainCollection &&
        collection == kKeyboardProbeMainCollection;
    if (replayable) {
      final expected = rovingTargetIndex(
        step.key,
        current: current,
        count: count,
        vertical: model.vertical,
        wrap: model.wrap,
      );
      final stated = step.index! < 0 ? count + step.index! : step.index!;
      if (expected != null && expected != stated) {
        mismatches.add(
          '${spec.component} step ${position + 1} (${step.key} from '
          '$current): spec says $stated, rovingTargetIndex says $expected',
        );
      }
    }
    count = step.count ?? count;
    final index = step.index;
    current = index == null ? null : (index < 0 ? count + index : index);
    collection = step.collection;
  }
  return mismatches;
}

/// The collections the probe walks — every Web component that emits a
/// composite role with a roving tab stop or an `aria-activedescendant`.
///
/// Each sequence is written against the component's **default docs
/// example** (`docs_core/lib/previews/examples/web/<component>/`), which is
/// why the indices are concrete: a changed example is a changed fixture,
/// and the probe says so rather than passing on a different list.
const List<KeyboardProbeSpec> kKeyboardProbeSpecs = [
  // Documents (open) · Resume.pdf · Cover Letter.pdf · Images · README.md.
  // A tree is scanned, not cycled: the ends are walls. Right opens a
  // closed parent then steps into it; Left closes an open one, or steps
  // out to the parent.
  KeyboardProbeSpec(
    component: 'tree',
    mode: .roving,
    startIndex: 0,
    startExpanded: true,
    model: KeyboardProbeModel(count: 5, vertical: true, wrap: false),
    steps: [
      KeyboardProbeStep('ArrowDown', index: 1),
      KeyboardProbeStep('ArrowDown', index: 2),
      KeyboardProbeStep('End', index: 4),
      KeyboardProbeStep('ArrowDown', index: 4),
      KeyboardProbeStep('Home', index: 0, expanded: true),
      KeyboardProbeStep('ArrowUp', index: 0),
      // Documents · Images · README.md
      KeyboardProbeStep(
        'ArrowLeft',
        index: 0,
        expanded: false,
        structural: true,
        count: 3,
      ),
      KeyboardProbeStep('ArrowDown', index: 1, expanded: false),
      // Documents · Images · photo.png · banner.jpg · README.md
      KeyboardProbeStep(
        'ArrowRight',
        index: 1,
        expanded: true,
        structural: true,
        count: 5,
      ),
      KeyboardProbeStep('ArrowRight', index: 2, structural: true),
      KeyboardProbeStep('ArrowLeft', index: 1, structural: true),
      // Typeahead: the next row whose label starts with "r".
      KeyboardProbeStep('r', index: 4, structural: true),
    ],
  ),
  // Account · Password. A tablist's stop stays on the selected tab; the
  // arrows move focus between tabs (and wrap) without selecting.
  KeyboardProbeSpec(
    component: 'tabs',
    mode: .roving,
    startIndex: 0,
    model: KeyboardProbeModel(count: 2, vertical: false),
    steps: [
      KeyboardProbeStep('ArrowRight', index: 1),
      KeyboardProbeStep('ArrowRight', index: 0),
      KeyboardProbeStep('ArrowLeft', index: 1),
      KeyboardProbeStep('Home', index: 0),
      KeyboardProbeStep('End', index: 1),
    ],
  ),
  // Account · Password, the same tablist inside a pane.
  KeyboardProbeSpec(
    component: 'tab-pane',
    mode: .roving,
    startIndex: 0,
    model: KeyboardProbeModel(count: 2, vertical: false),
    steps: [
      KeyboardProbeStep('ArrowRight', index: 1),
      KeyboardProbeStep('ArrowRight', index: 0),
      KeyboardProbeStep('ArrowLeft', index: 1),
      KeyboardProbeStep('Home', index: 0),
      KeyboardProbeStep('End', index: 1),
    ],
  ),
  // Apple (selected) · Banana · Cherry · Mango · Orange. A listbox is
  // scanned, not cycled.
  KeyboardProbeSpec(
    component: 'item-picker',
    mode: .roving,
    startIndex: 0,
    model: KeyboardProbeModel(count: 5, vertical: true, wrap: false),
    steps: [
      KeyboardProbeStep('ArrowDown', index: 1),
      KeyboardProbeStep('ArrowDown', index: 2),
      KeyboardProbeStep('End', index: 4),
      KeyboardProbeStep('ArrowDown', index: 4),
      KeyboardProbeStep('Home', index: 0),
      KeyboardProbeStep('ArrowUp', index: 0),
      KeyboardProbeStep('m', index: 3, structural: true),
    ],
  ),
  // Home · Profile · Show grid · Settings (disabled — still a stop, per
  // the menu pattern: a row a keyboard cannot land on cannot say why it
  // does nothing). The label and the divider are structure, not stops.
  KeyboardProbeSpec(
    component: 'menu',
    mode: .roving,
    startIndex: 0,
    model: KeyboardProbeModel(count: 4, vertical: true),
    steps: [
      KeyboardProbeStep('ArrowDown', index: 1),
      KeyboardProbeStep('ArrowDown', index: 2),
      KeyboardProbeStep('ArrowDown', index: 3),
      KeyboardProbeStep('ArrowDown', index: 0),
      KeyboardProbeStep('ArrowUp', index: 3),
      KeyboardProbeStep('Home', index: 0),
      KeyboardProbeStep('End', index: 3),
      KeyboardProbeStep('p', index: 1, structural: true),
    ],
  ),
  // File · Edit · View on the bar; the open panel is a second collection.
  KeyboardProbeSpec(
    component: 'menubar',
    mode: .roving,
    startIndex: 0,
    model: KeyboardProbeModel(count: 3, vertical: false),
    steps: [
      KeyboardProbeStep('ArrowRight', index: 1),
      KeyboardProbeStep('ArrowRight', index: 2),
      KeyboardProbeStep('ArrowRight', index: 0),
      KeyboardProbeStep('ArrowLeft', index: 2),
      KeyboardProbeStep('Home', index: 0),
      // Down opens File on its first row: New · Open · Exit.
      KeyboardProbeStep(
        'ArrowDown',
        index: 0,
        collection: 'panel',
        structural: true,
      ),
      KeyboardProbeStep('ArrowDown', index: 1, collection: 'panel'),
      KeyboardProbeStep('End', index: 2, collection: 'panel'),
      KeyboardProbeStep('ArrowDown', index: 0, collection: 'panel'),
      // Right steps to the next menu — Edit — on its first row. The open
      // menu is a new panel, so it is a third collection.
      KeyboardProbeStep(
        'ArrowRight',
        index: 0,
        collection: 'edit',
        structural: true,
      ),
      // Cut · Copy · Paste, wrapping.
      KeyboardProbeStep('ArrowUp', index: 2, collection: 'edit'),
      // Escape closes the panel and gives focus back to its trigger.
      KeyboardProbeStep('Escape', index: 1, structural: true),
    ],
  ),
  // Svelte (checked) · Vue · React — a radio group: either arrow axis
  // walks it, the ends join, and the radio landed on is checked.
  KeyboardProbeSpec(
    component: 'filter',
    mode: .roving,
    startIndex: 0,
    model: KeyboardProbeModel(count: 3, vertical: false),
    steps: [
      KeyboardProbeStep('ArrowRight', index: 1),
      KeyboardProbeStep('ArrowRight', index: 2),
      KeyboardProbeStep('ArrowRight', index: 0),
      KeyboardProbeStep('ArrowLeft', index: 2),
      KeyboardProbeStep('ArrowDown', index: 0, structural: true),
      KeyboardProbeStep('ArrowUp', index: 2, structural: true),
    ],
  ),
  // AM (checked) · PM — the same radio-group pattern as Filter: either
  // arrow axis walks it, the ends join, and the radio landed on is checked.
  KeyboardProbeSpec(
    component: 'toggle-group',
    mode: .roving,
    startIndex: 0,
    model: KeyboardProbeModel(count: 2, vertical: false),
    steps: [
      KeyboardProbeStep('ArrowRight', index: 1),
      KeyboardProbeStep('ArrowRight', index: 0),
      KeyboardProbeStep('ArrowLeft', index: 1),
      KeyboardProbeStep('ArrowDown', index: 0, structural: true),
      KeyboardProbeStep('ArrowUp', index: 1, structural: true),
    ],
  ),
  // The picker's mode tabs — a tablist of three inside the popover the
  // swatch opens.
  KeyboardProbeSpec(
    component: 'color-picker',
    mode: .roving,
    opener: KeyboardProbeOpener('button[aria-label]', 'Enter'),
    entryScope: '#coui-overlay-popover',
    entrySelector: '[role="tablist"] [data-roving-item][tabindex="0"]',
    startIndex: 0,
    model: KeyboardProbeModel(count: 3, vertical: false),
    steps: [
      KeyboardProbeStep('ArrowRight', index: 1),
      KeyboardProbeStep('ArrowRight', index: 2),
      KeyboardProbeStep('ArrowRight', index: 0),
      KeyboardProbeStep('ArrowLeft', index: 2),
      KeyboardProbeStep('Home', index: 0),
      KeyboardProbeStep('End', index: 2),
    ],
  ),
  // Apple (selected) · Banana · Orange. Focus never leaves the trigger;
  // the highlight is announced through `aria-activedescendant`.
  KeyboardProbeSpec(
    component: 'select',
    mode: .activeDescendant,
    startExpanded: false,
    steps: [
      KeyboardProbeStep('Enter', index: 0, expanded: true),
      KeyboardProbeStep('ArrowDown', index: 1, expanded: true),
      KeyboardProbeStep('ArrowDown', index: 2),
      KeyboardProbeStep('Home', index: 0),
      KeyboardProbeStep('End', index: 2),
      KeyboardProbeStep('ArrowUp', index: 1),
      KeyboardProbeStep('Escape', expanded: false),
    ],
  ),
  // Apple · Banana · Cherry · Date · Elderberry. The list opens on focus
  // with nothing highlighted; Down starts at the top, Up at the bottom,
  // and the ends join.
  KeyboardProbeSpec(
    component: 'autocomplete',
    mode: .activeDescendant,
    startExpanded: true,
    steps: [
      KeyboardProbeStep('ArrowDown', index: 0, expanded: true),
      KeyboardProbeStep('ArrowDown', index: 1),
      KeyboardProbeStep('ArrowUp', index: 0),
      KeyboardProbeStep('ArrowUp', index: 4),
      KeyboardProbeStep('ArrowDown', index: 0),
      KeyboardProbeStep('Escape', expanded: false),
    ],
  ),
  // Every item of every group, highlight on the first; the search field
  // keeps focus.
  KeyboardProbeSpec(
    component: 'command',
    mode: .activeDescendant,
    entrySelector: 'input',
    startIndex: 0,
    steps: [
      KeyboardProbeStep('ArrowDown', index: 1),
      KeyboardProbeStep('ArrowDown', index: 2),
      KeyboardProbeStep('ArrowUp', index: 1),
      KeyboardProbeStep('Home', index: 0),
      KeyboardProbeStep('End', index: -1),
    ],
  ),
  // The country selector opens a searchable list; focus goes to its
  // search field and the highlight is announced from there. It opens on the
  // current country; typing re-filters and starts again from the top, and
  // the ends join.
  KeyboardProbeSpec(
    component: 'phone-input',
    mode: .activeDescendant,
    entrySelector: 'button[aria-haspopup]',
    startExpanded: false,
    steps: [
      KeyboardProbeStep('Enter', label: 'United States', structural: true),
      KeyboardProbeStep('ArrowDown', offset: 1),
      KeyboardProbeStep('ArrowUp', offset: -1),
      KeyboardProbeStep('k', index: 0, structural: true),
      KeyboardProbeStep('o', index: 0, structural: true),
      KeyboardProbeStep('ArrowUp', index: -1),
      KeyboardProbeStep('ArrowDown', index: 0),
    ],
  ),
];
