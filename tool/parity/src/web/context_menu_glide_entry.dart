/// Client fixture for the `ContextMenu` glide probe.
///
/// The shipped `ContextMenu`, configured from page script, so a probe can put
/// real touch input through the shipped listeners. The glide, the preview and
/// the haptic cue are DOM work — a `touchmove` that has to exist before the
/// finger goes down, rows measured off the page at every event, a mark painted
/// by a browser's CSS, a panel placed by layout — which a VM does not have, so
/// they can only be judged here. Nothing in this file re-implements any of it:
/// the page reports what happened to the menu and nothing more.
///
/// The menu fills the viewport (a fixed region inside the `ContextMenu`) over a
/// tall document, so a finger that moves can scroll the page, which is the
/// browser behaviour a glide has to hold off.
///
/// Page API (all on `window`):
///
///   couiGlideConfigure(json)  rebuilds the menu from
///                             `{items, glide, haptics, preview, closeMs}` —
///                             `items` are `{kind, label, disabled}` (`action`,
///                             `checkbox`, `radio`, `divider`, `label`),
///                             `preview` is `{width, height}` or absent,
///                             `closeMs` is how long the panel takes to leave
///                             (the default when absent): long enough, a probe
///                             can act while the panel is still on the page
///   couiGlideActivated()      the rows activated since the last configure, as
///                             a JSON list of indices into the interactive rows
library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr/client.dart' as client show runApp;

@JS('couiGlideConfigure')
external set _configure(JSFunction value);
@JS('couiGlideActivated')
external set _activated(JSFunction value);

void main() => client.runApp(CoUIWeb(theme: .coui, child: const _Probe()));

class _Probe extends StatefulComponent {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  Map<String, Object?> _config = const {};

  /// The interactive rows activated, in order.
  final List<int> _chosen = [];

  /// The state of the toggle rows, by interactive index.
  final Map<int, bool> _on = {};

  @override
  void initState() {
    super.initState();
    _activated = (() => jsonEncode(_chosen)).toJS;
    _configure = ((String json) {
      setState(() {
        _config = jsonDecode(json) as Map<String, Object?>;
        _chosen.clear();
        _on.clear();
      });
    }).toJS;
  }

  CoreMenuItem<Component> _row(
    String kind,
    String label,
    int index, {
    required bool disabled,
    List<CoreMenuItem<Component>>? submenu,
  }) {
    return switch (kind) {
      'action' => CoreMenuItem.action(
        label,
        disabled: disabled,
        submenu: submenu,
        onPressed: () => _chosen.add(index),
      ),
      'checkbox' => CoreMenuItem.checkbox(
        label,
        disabled: disabled,
        checked: _on[index] ?? false,
        onChanged: (value) {
          _chosen.add(index);
          setState(() => _on[index] = value);
        },
      ),
      'radio' => CoreMenuItem.radio(
        label,
        disabled: disabled,
        selected: _on[index] ?? false,
        onChanged: (value) {
          _chosen.add(index);
          setState(() => _on[index] = value);
        },
      ),
      _ => throw StateError('unknown row kind $kind'),
    };
  }

  /// The items of [specs]. Interactive rows are numbered in document order —
  /// a row, then the rows of its inline submenu, then the next row — which is
  /// the order a glide measures them in. [next] is the number of the next one.
  List<CoreMenuItem<Component>> _build(
    List<Map<String, Object?>> specs,
    List<int> next,
  ) {
    return [
      for (final spec in specs)
        switch (spec['kind']! as String) {
          'divider' => const CoreMenuItem<Component>.divider(),
          'label' => CoreMenuItem<Component>.label(spec['label']! as String),
          final kind => _interactive(spec, kind, next),
        },
    ];
  }

  CoreMenuItem<Component> _interactive(
    Map<String, Object?> spec,
    String kind,
    List<int> next,
  ) {
    final index = next[0]++;
    final nested = (spec['submenu'] as List?)?.cast<Map<String, Object?>>();

    return _row(
      kind,
      spec['label']! as String,
      index,
      disabled: spec['disabled'] == true,
      submenu: nested == null ? null : _build(nested, next),
    );
  }

  List<CoreMenuItem<Component>> _items() {
    final specs = (_config['items'] as List?)?.cast<Map<String, Object?>>();

    return _build(specs ?? const [], [0]);
  }

  @override
  Component build(BuildContext context) {
    final preview = _config['preview'] as Map<String, Object?>?;
    final closeMs = (_config['closeMs'] as num?)?.toInt();

    return div([
      ContextMenu(
        id: 'cm',
        items: _items(),
        glideToSelect: _config['glide'] == true,
        haptics: _config['haptics'] == true,
        contextMenuStyle: closeMs == null
            ? null
            : CoreContextMenuStyle(
                menuStyle: CoreMenuStyle(
                  popupStyle: CorePopupStyle(
                    closeAnimationDuration: Duration(milliseconds: closeMs),
                  ),
                ),
              ),
        preview: preview == null
            ? null
            : div(
                const [Text('Preview')],
                id: 'pv',
                styles: Styles(
                  raw: {
                    'width': '${(preview['width']! as num).toInt()}px',
                    'height': '${(preview['height']! as num).toInt()}px',
                    'box-sizing': 'border-box',
                    'overflow': 'hidden',
                  },
                ),
              ),
        child: const div(
          [],
          id: 'cm-area',
          styles: Styles(
            raw: {
              'position': 'fixed',
              'left': '0px',
              'top': '0px',
              'width': '100%',
              'height': '100%',
            },
          ),
        ),
      ),
      // The document scrolls: a finger that pans takes the page with it.
      const div([], styles: Styles(raw: {'height': '3000px'})),
    ]);
  }
}
