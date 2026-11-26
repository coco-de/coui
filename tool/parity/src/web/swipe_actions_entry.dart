/// Client fixture: the shipped `SwipeActions`, mounted from page script, so a
/// probe can put real pointer, keyboard and focus input through the shipped
/// handlers.
///
/// The Web row's pointer path needs real `PointerEvent`s, a real layout to
/// measure and a real pointer capture — none of which the VM has — so its DOM
/// half (the listeners, the measured strips, the settle transition, focus
/// opening a side) can only be judged here. Nothing in this file re-implements
/// it: the rows are the shipped component and the page only reports what
/// happened to them.
///
/// Every row sits in a 400 × 72 slot at a known place on the page, the box the
/// shared vector table (`swipe_actions_vectors.json`) is stated for, and its
/// pointer coordinates can be read straight off the table.
///
/// Page API (all on `window`):
///
///   couiSwipeMount(specs)   replaces the rows. `specs` is a JSON list of
///                           `{id, leading, trailing, fullSwipe, enabled,
///                           firstDisabled, link, input, button, nested, rtl,
///                           scope, remount}`:
///                           how many actions each side has, whether a full
///                           swipe is allowed, whether the row is enabled,
///                           whether the first action of each side is
///                           disabled, whether the row's content is a link, a
///                           text field or a button (`button-<id>`, the one
///                           thing in the content a key can click), whether
///                           it is another `SwipeActions` (`nested`, see
///                           below), whether it reads right to left, whether
///                           it shares the one scope (default yes) and a key:
///                           a row given another one is not updated but
///                           replaced by a new row.
///                           The DOM id of a row is `row-<id>`.
///                           `nested` is `{leading, trailing}`: the row's
///                           content is a second row, `row-<id>-inner`, with
///                           that many actions on each side (labelled apart
///                           from the outer row's, so a focus or a press says
///                           whose it was), in the same scope
///   couiSwipeLog()          JSON list of what happened, in order:
///                           `<id>:<action label>` for a pressed or full-swiped
///                           action, `<id>:content` and `<id>:root-click` for a
///                           click that reached the row's content / the
///                           caller's own `onClick`; the actions of a nested
///                           row log `<id>:inner:<action label>`
///   couiSwipeClear()        empties that list
///   couiSwipeDuringUpdate   a function the page may replace (it starts as a
///                           no-op). The entry calls it in the middle of
///                           every `couiSwipeMount`'s rebuild, once the rows
///                           have been updated — a host that moves focus as
///                           part of the update that rebuilds a row
///   couiSwipePressed        a function the page may replace (it starts as a
///                           no-op). Every action calls it, with the entry
///                           that goes to the log, before it logs — a host
///                           whose handler moves focus
library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr/client.dart' as client show runApp;

@JS('couiSwipeMount')
external set _mount(JSFunction value);
@JS('couiSwipeLog')
external set _log(JSFunction value);
@JS('couiSwipeClear')
external set _clear(JSFunction value);
@JS('couiSwipeDuringUpdate')
external set _setDuringUpdate(JSFunction value);
@JS('couiSwipeDuringUpdate')
external void _duringUpdate();
@JS('couiSwipePressed')
external set _setPressed(JSFunction value);
@JS('couiSwipePressed')
external void _pressed(String entry);

const List<String> _kLeadingLabels = ['Pin', 'Mute', 'Flag'];
const List<String> _kTrailingLabels = ['Archive', 'Delete', 'Mark'];
const List<String> _kInnerLeadingLabels = ['Reply', 'Like', 'Share'];
const List<String> _kInnerTrailingLabels = ['Hide', 'Report', 'Block'];

void main() => client.runApp(CoUIWeb(theme: .coui, child: const _Probe()));

class _Probe extends StatefulComponent {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  List<Map<String, Object?>> _rows = const [];
  final List<String> _entries = [];

  /// Counts the mounts, so that every one is a different component for
  /// [_DuringUpdate] and reaches its update.
  int _epoch = 0;

  @override
  void initState() {
    super.initState();
    _log = (() => jsonEncode(_entries)).toJS;
    _clear = _entries.clear.toJS;
    _setDuringUpdate = (() {}).toJS;
    _setPressed = ((String _) {}).toJS;
    _mount = ((String specs) {
      final rows = (jsonDecode(specs) as List<Object?>)
          .cast<Map<String, Object?>>();
      _entries.clear();
      setState(() {
        _rows = rows;
        _epoch++;
      });
    }).toJS;
  }

  List<CoreSwipeAction<Component>> _actions(
    String id,
    List<String> labels,
    Object? count, {
    required bool firstDisabled,
  }) => [
    for (var i = 0; i < ((count as int?) ?? 0); i++)
      CoreSwipeAction<Component>(
        label: labels[i],
        icon: const Icon(LucideIcons.house),
        variant: labels[i] == 'Delete'
            ? CoreSwipeActionVariant.destructive
            : CoreSwipeActionVariant.defaultVariant,
        enabled: !(firstDisabled && i == 0),
        onPressed: () {
          _pressed('$id:${labels[i]}');
          _entries.add('$id:${labels[i]}');
        },
      ),
  ];

  /// The row nested in the content of [id]'s: its own actions, in the same
  /// scope.
  Component _innerRow(String id, Map<String, Object?> nested) {
    return SwipeActions(
      id: 'row-$id-inner',
      leadingActions: _actions(
        '$id:inner',
        _kInnerLeadingLabels,
        nested['leading'],
        firstDisabled: false,
      ),
      trailingActions: _actions(
        '$id:inner',
        _kInnerTrailingLabels,
        nested['trailing'],
        firstDisabled: false,
      ),
      // The outer content is a flex row: the nested row takes all of it.
      css: const Styles(raw: {'flex': '1 1 auto', 'min-width': '0'}),
      child: div(
        const [Text('Inner')],
        id: 'content-$id-inner',
        styles: const Styles(
          raw: {
            'height': '72px',
            'display': 'flex',
            'align-items': 'center',
            'padding': '0 16px',
            'background-color': '#d4d4d4',
          },
        ),
      ),
    );
  }

  Component _row(Map<String, Object?> spec) {
    final id = spec['id']! as String;
    final nested = spec['nested'] as Map<String, Object?>?;

    return SwipeActions(
      key: spec['remount'] == null ? null : ValueKey<Object>(spec['remount']!),
      id: 'row-$id',
      leadingActions: _actions(
        id,
        _kLeadingLabels,
        spec['leading'],
        firstDisabled: spec['firstDisabled'] == true,
      ),
      trailingActions: _actions(
        id,
        _kTrailingLabels,
        spec['trailing'],
        firstDisabled: spec['firstDisabled'] == true,
      ),
      allowsFullSwipe: spec['fullSwipe'] != false,
      enabled: spec['enabled'] == false ? false : null,
      onClick: (_) => _entries.add('$id:root-click'),
      child: div(
        [
          if (nested != null)
            _innerRow(id, nested)
          else if (spec['link'] == true)
            a(
              const [Text('Link')],
              href: '#link',
              id: 'link-$id',
            )
          else if (spec['input'] == true)
            Component.element(
              tag: 'input',
              id: 'input-$id',
              attributes: const {
                'type': 'text',
                'value': 'a field with enough text to select',
              },
            )
          else if (spec['button'] == true)
            Component.element(
              tag: 'button',
              id: 'button-$id',
              attributes: const {'type': 'button'},
              children: const [Text('Press')],
            )
          else
            const Text('Row'),
        ],
        id: 'content-$id',
        events: {'click': (_) => _entries.add('$id:content')},
        styles: Styles(
          raw: {
            'height': '72px',
            'display': 'flex',
            'align-items': 'center',
            // A nested row is laid out against the whole content.
            'padding': nested == null ? '0 16px' : '0',
            'background-color': '#ececec',
          },
        ),
      ),
    );
  }

  Component _slot(int index, Map<String, Object?> spec) {
    final id = spec['id']! as String;

    return div(
      [_row(spec)],
      id: 'slot-$id',
      attributes: {'dir': spec['rtl'] == true ? 'rtl' : 'ltr'},
      styles: Styles(
        raw: {
          'position': 'absolute',
          'left': '100px',
          'top': '${100 + index * 120}px',
          'width': '400px',
          'height': '72px',
        },
      ),
    );
  }

  @override
  Component build(BuildContext context) {
    final scoped = <Component>[];
    final free = <Component>[];
    for (var i = 0; i < _rows.length; i++) {
      (_rows[i]['scope'] == false ? free : scoped).add(_slot(i, _rows[i]));
    }

    // Right after the scope, so that it is updated once the scoped rows have
    // been and its place does not move with the number of free rows.
    return div([
      SwipeActionScope(child: div(scoped)),
      _DuringUpdate(_epoch),
      ...free,
    ], id: 'probe-root');
  }
}

/// Calls the page's `couiSwipeDuringUpdate` each time the rows are rebuilt, in
/// the same pass as the rows and after them.
class _DuringUpdate extends StatefulComponent {
  const _DuringUpdate(this.epoch);

  final int epoch;

  @override
  State<_DuringUpdate> createState() => _DuringUpdateState();
}

class _DuringUpdateState extends State<_DuringUpdate> {
  @override
  void didUpdateComponent(covariant _DuringUpdate oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (component.epoch != oldComponent.epoch) _duringUpdate();
  }

  @override
  Component build(BuildContext context) => const Component.fragment([]);
}
