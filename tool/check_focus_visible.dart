// Gate: an interactive component shows where keyboard focus is (WCAG 2.4.7).
//
// Losing a focus indicator does not break the mouse, so it survives review
// and screenshots easily. The only person it fails is the one navigating by
// Tab, who simply cannot tell where they are.
//
// On measurement. The report that prompted this put coverage at 20/179 on
// Web and 28/189 on Flutter. Both numbers came from grepping one mechanism
// across every component, including ones that are not focus targets at all.
// Counting only *interactive pairs*, and accepting every mechanism the
// library actually uses plus composition, the real figure was 63 of 77 —
// and the remainder turned out to be non-targets or separate defects
// (sliders, for instance, cannot be focused at all, which no amount of ring
// wiring fixes). A guard that overstates gets muted, so this one is
// deliberately generous about *how* a component indicates focus.
//
// Accepted:
//   - a focus ring (FocusOutline / focusOutlineStyle / focusRing)
//   - focus-visible: / focus-within: / focus: utilities (Web only — on
//     Flutter `focus:` is an ordinary named argument and means nothing)
//   - focus-driven chrome (_focused, onFocusChange, onShowFocusHighlight,
//     focusBorder, focusColor)
//   - composing a primitive that already does one of the above
//
// Composition counts for the same reason as in the a11y-parity guard: a
// component wrapping TextField inherits its ring, and demanding a second one
// asks for a double ring, not for accessibility. Self-references are dropped
// first — otherwise `TextField(` inside text_field/ lets it vouch for itself.
//
// Usage:
//   dart run tool/check_focus_visible.dart          # report
//   dart run tool/check_focus_visible.dart --ci     # fail on any gap

import 'dart:io';

/// Below this many pairs, discovery is broken rather than the library
/// having shrunk — fail instead of reporting a clean sweep.
const int _kMinimumPairs = 40;

const _kFlutterRoot = 'packages/coui_flutter/lib/src/components';
const _kWebRoot = 'packages/coui_web/lib/src/components';

/// Components that are not keyboard focus targets.
///
/// Containers, layout wrappers and display surfaces — a ring here would land
/// on something the user never tabs to. `range` / `slider` are keyboard focus
/// targets now (tabindex + focus-visible outline landed in #3454) and no
/// longer belong on this list.
const _kNotFocusTargets = {
  'card_image',
  'chip_group',
  'context_menu',
  'diff',
  'drag_item',
  'draggable_panel',
  'focus_outline',
  'form',
  'frame',
  'hover_gallery',
  'sortable',
  'table',
  'text',
  'tooltip',
};

final _kInteractive = RegExp(
  'onPressed|onChanged|onTap|onSelected|focusNode',
);
final _kFocusFlutter = RegExp(
  r'FocusOutline\(|focusOutlineStyle|focusRing|_focused|'
  'onShowFocusHighlight|onFocusChange|focusBorder|focusColor',
);
final _kFocusWeb = RegExp(
  // `FocusOutline(` counts here for the same reason it counts on Flutter:
  // composing the primitive that draws the ring *is* indicating focus,
  // and the note above already lists it as accepted. It was missing from
  // this pattern, so a Web component that stopped hand-rolling a ring and
  // composed `FocusOutline` instead read as having lost its focus
  // indication — the guard flagging the fix rather than the defect.
  r'FocusOutline\(|'
  'focus-visible:|focus-within:|focus:|focusRingScopedRule|focusRing|'
  // `_minFocused` / `_maxFocused` (a control with more than one focus
  // target) are focus-driven chrome exactly like `_focused`.
  '_[A-Za-z]*[Ff]ocused|focusBorder',
);
final _kFocusInfra = RegExp(
  // `MenuItem` composes `Clickable` and draws the row's ring itself, so a
  // container that composes rows (`Menu`) has its focus indication there.
  // `Chip` likewise composes `Clickable` (Flutter) and emits its own
  // focus-visible ring (Web), so a component whose only focus targets are
  // chips (`TrendChart`'s period row) inherits that ring.
  r'\bClickable\(|\bButton\(|\bTextField\(|\bTextArea\(|\bCheckbox\(|'
  // `SidebarItem` composes `Clickable` and lays its own state layer on
  // focus, so a group that composes one as its header row has its focus
  // indication there — the same reason as `MenuItem`.
  r'\bToggle\(|\bMenuItem\(|\bChip\(|\bSidebarItem\(',
);

/// Component directories keyed by name — a directory qualifies when it holds
/// its own `<name>.dart` entry file.
Map<String, Directory> _components(String root) {
  final out = <String, Directory>{};
  final dir = Directory(root);
  if (!dir.existsSync()) return out;
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! Directory) continue;
    final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (File('${entity.path}/$name.dart').existsSync()) {
      out[name] = entity;
    }
  }
  return out;
}

/// Concatenated Dart sources directly inside [dir] (entry + style + state).
String _source(Directory dir) => dir
    .listSync()
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .map((f) => f.readAsStringSync())
    .join('\n');

/// [source] without comment lines — what decides whether a component is
/// interactive. A doc comment's usage example (`OptionItem(onPressed: …)`)
/// is not the component's code: counted, it makes a layout container that
/// only holds focusable children read as an interactive component with no
/// focus indication of its own. Focus evidence still reads the whole source.
String _code(String source) => source
    .split('\n')
    .where((line) => !line.trimLeft().startsWith('//'))
    .join('\n');

/// `text_field` → `TextField(`, the self-reference to discount.
RegExp _selfReference(String name) {
  final camel = name
      .split('_')
      .map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1))
      .join();
  return RegExp('\\b$camel\\(');
}

bool _indicatesFocus(String source, RegExp own, String name) {
  if (own.hasMatch(source)) return true;
  final self = _selfReference(name);
  return _kFocusInfra
      .allMatches(source)
      .map((m) => m[0]!)
      .any((hit) => !self.hasMatch(hit));
}

void main(List<String> args) {
  final ci = args.contains('--ci');
  final flutter = _components(_kFlutterRoot);
  final web = _components(_kWebRoot);

  final gaps = <String>[];
  var checked = 0;

  for (final name
      in (flutter.keys.toSet()..retainAll(web.keys)).toList()..sort()) {
    if (_kNotFocusTargets.contains(name)) continue;
    final fs = _source(flutter[name]!);
    final ws = _source(web[name]!);
    if (!_kInteractive.hasMatch(_code(fs)) &&
        !_kInteractive.hasMatch(_code(ws))) {
      continue;
    }
    checked++;
    if (!_indicatesFocus(fs, _kFocusFlutter, name)) gaps.add('$name (Flutter)');
    if (!_indicatesFocus(ws, _kFocusWeb, name)) gaps.add('$name (Web)');
  }

  stdout.writeln('Checked $checked interactive component pairs.');

  if (gaps.isNotEmpty) {
    stdout.writeln('❌ No visible focus indication:');
    for (final g in gaps) {
      stdout.writeln('     $g');
    }
    stdout
      ..writeln('   Wire focusOutlineStyle / a focus-visible utility, or')
      ..writeln('   compose a primitive that already draws one. If it is')
      ..writeln('   genuinely not a focus target, add it to')
      ..writeln('   _kNotFocusTargets with the reason.');
    if (ci) exit(1);
    return;
  }

  // A guard that pairs nothing would pass forever.
  if (checked < _kMinimumPairs) {
    stderr.writeln(
      '❌ Only $checked interactive pairs found — discovery is probably '
      'broken rather than the library having shrunk.',
    );
    exit(2);
  }

  stdout.writeln('✅ Focus is visible on every interactive component pair.');
}
