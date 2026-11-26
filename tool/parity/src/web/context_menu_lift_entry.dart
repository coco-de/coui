/// Client fixture for the `ContextMenu` lift probe.
///
/// The shipped `ContextMenu` with `liftChild`, configured from page script, so
/// a probe can put real touch, pointer and key input through the shipped
/// listeners. The lift is DOM work - the source measured off layout, the copy
/// promoted into the top layer under the panel, `requestAnimationFrame` frames,
/// `inert`, a panel folded by a keyframes animation, a page that scrolls under
/// the open menu - which a VM does not have, so it can only be judged here.
/// Nothing in this file re-implements any of it: the page reports what
/// happened to the menu and nothing more.
///
/// The child is a counter, so a probe can tell the original (which keeps its
/// state) from the copy (a second build, which starts from nothing). It sits at
/// a known place in a tall document, so the page can be scrolled under an open
/// menu.
///
/// Page API (all on `window`):
///
///   couiLiftConfigure(json)  rebuilds the menu from
///                            `{lift, haptics, glide, rows, closeMs, preview,
///                            style}` - `rows` is how many action rows it has,
///                            `closeMs` how long the panel takes to leave (the
///                            default when absent), `preview` is
///                            `{width, height}` or absent, `style` is the look
///                            of the lift the menu states -
///                            `{liftScale, liftMs, dim, radius, retractScale,
///                            cast}` with `cast` a list of layers
///                            `{offsetX, offsetY, blurRadius, spreadRadius,
///                            opacity}` - or absent (the design defaults)
///   couiLiftIncrement()      counts the original up by one
///   couiLiftBuilds()         `{builds, created}` as JSON: how many times each
///                            counter alive has built - the original first, its
///                            copy after it - and how many counters have ever
///                            been created
///   couiLiftActivated()      the rows activated since the last configure, as a
///                            JSON list of row numbers
///   couiLiftOpen()           opens the menu through its controller
///   couiLiftClose()          closes it through its controller
library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr/client.dart' as client show runApp;

@JS('couiLiftConfigure')
external set _configure(JSFunction value);
@JS('couiLiftIncrement')
external set _increment(JSFunction value);
@JS('couiLiftActivated')
external set _activated(JSFunction value);
@JS('couiLiftBuilds')
external set _builds(JSFunction value);
@JS('couiLiftOpen')
external set _open(JSFunction value);
@JS('couiLiftClose')
external set _close(JSFunction value);

void main() => client.runApp(CoUIWeb(theme: .coui, child: const _Probe()));

/// The states of the counters on the page, in the order they were built: the
/// original first, the copy (while there is one) after it.
final List<_CounterState> _counters = [];

/// How many counters have ever been created: a copy built afresh on every
/// frame would make this grow, one that is drawn from frame to frame would not.
int _created = 0;

class _Counter extends StatefulComponent {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  /// How many times this state has built: a probe tells a child that is built
  /// once from one that is built on every frame of the lift.
  int builds = 0;

  @override
  void initState() {
    super.initState();
    _counters.add(this);
    _created++;
  }

  @override
  void dispose() {
    _counters.remove(this);
    super.dispose();
  }

  void increment() => setState(() => count++);

  @override
  Component build(BuildContext context) {
    builds++;

    return div(
      [
        const Text('Hold me'),
        div([Text('count $count')], classes: 'counter'),
      ],
      classes: 'lift-region',
      // Focusable, so the keyboard can open the menu from inside the region.
      attributes: const {'tabindex': '0'},
      styles: const Styles(
        raw: {
          'width': '240px',
          'height': '140px',
          'box-sizing': 'border-box',
          'padding': '16px',
          'background-color': 'rgb(240, 240, 250)',
          'border': '1px solid rgb(180, 180, 200)',
          'border-radius': '8px',
        },
      ),
    );
  }
}

class _Probe extends StatefulComponent {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  Map<String, Object?> _config = const {};

  /// The rows activated, in order.
  final List<int> _chosen = [];

  final PopoverController _controller = PopoverController();

  @override
  void initState() {
    super.initState();
    _activated = (() => jsonEncode(_chosen)).toJS;
    _builds = (() => jsonEncode({
      'builds': [for (final c in _counters) c.builds],
      'created': _created,
    })).toJS;
    _open = _controller.show.toJS;
    _close = _controller.close.toJS;
    _increment = (() {
      if (_counters.isNotEmpty) _counters.first.increment();
    }).toJS;
    _configure = ((String json) {
      setState(() {
        _config = jsonDecode(json) as Map<String, Object?>;
        _chosen.clear();
      });
    }).toJS;
  }

  @override
  Component build(BuildContext context) {
    final preview = _config['preview'] as Map<String, Object?>?;
    final closeMs = (_config['closeMs'] as num?)?.toInt();
    final restyle = _config['style'] as Map<String, Object?>?;
    final rows = (_config['rows'] as num?)?.toInt() ?? 3;

    return div([
      div(
        [
          ContextMenu(
            id: 'cm',
            controller: _controller,
            items: [
              for (var i = 0; i < rows; i++)
                CoreMenuItem.action('Row $i', onPressed: () => _chosen.add(i)),
            ],
            liftChild: _config['lift'] == true,
            glideToSelect: _config['glide'] == true,
            haptics: _config['haptics'] == true,
            contextMenuStyle: _styleOf(closeMs: closeMs, restyle: restyle),
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
            child: const _Counter(),
          ),
        ],
        // A known place in the document: the page can be scrolled under it.
        styles: const Styles(
          raw: {'position': 'absolute', 'left': '60px', 'top': '160px'},
        ),
      ),
      const div([], styles: Styles(raw: {'height': '3000px'})),
    ]);
  }
}

/// The style the page states for its menu: how long the panel takes to leave
/// ([closeMs]) and the look of the lift ([restyle], the page API's `style`),
/// or `null` when it states neither.
CoreContextMenuStyle? _styleOf({
  required int? closeMs,
  required Map<String, Object?>? restyle,
}) {
  if (closeMs == null && restyle == null) return null;
  final liftMs = (restyle?['liftMs'] as num?)?.toInt();
  final radius = (restyle?['radius'] as num?)?.toDouble();
  final cast = restyle?['cast'] as List?;

  return CoreContextMenuStyle(
    menuStyle: closeMs == null
        ? null
        : CoreMenuStyle(
            popupStyle: CorePopupStyle(
              closeAnimationDuration: Duration(milliseconds: closeMs),
            ),
          ),
    liftScale: (restyle?['liftScale'] as num?)?.toDouble(),
    liftDuration: liftMs == null ? null : Duration(milliseconds: liftMs),
    liftDimOpacity: (restyle?['dim'] as num?)?.toDouble(),
    liftCast: cast == null
        ? null
        : [
            for (final layer in cast.cast<Map<String, Object?>>())
              (
                offsetX: (layer['offsetX']! as num).toDouble(),
                offsetY: (layer['offsetY']! as num).toDouble(),
                blurRadius: (layer['blurRadius']! as num).toDouble(),
                spreadRadius: (layer['spreadRadius']! as num).toDouble(),
                opacity: (layer['opacity']! as num).toDouble(),
                inset: false,
              ),
          ],
    liftRadius: radius == null ? null : CoreBorderRadius.all(radius),
    retractScale: (restyle?['retractScale'] as num?)?.toDouble(),
  );
}
