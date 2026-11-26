/// Client fixture for the menu viewport-fit probe.
///
/// Two things are compiled into one page, because both have to be judged in a
/// real browser and neither can be judged from a VM:
///
/// * **The positioner on its own** (`couiFit*`). A panel whose natural height
///   and viewport paddings the probe chooses, positioned by the shipped
///   `OverlayPositioner` with `fitViewportHeight` and drawn by the shipped
///   `resolveOverlayFitBox` / `resolveOverlayFitScroller` chrome — through
///   component state, the way a host re-renders from `onPosition` / `onFit`.
///   The probe feeds it the shared vector table, so the browser answers the
///   same question Core and Flutter do.
/// * **The real hosts** (`DropdownMenu`, `ContextMenu`, `Menubar`) with a
///   thirty-row menu each, so the wiring between the positioner, the
///   resolver and the composed `Menu` is judged as shipped, and so Escape
///   and the roles of an anchored panel can be read off a live page.
library;

import 'dart:js_interop';

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/overlay/overlay_fit.dart';
import 'package:jaspr/client.dart' as client show runApp;

@JS('couiFitConfigure')
external set _configure(JSFunction value);
@JS('couiFitStart')
external set _start(JSFunction value);
@JS('couiFitEvents')
external set _events(JSFunction value);
@JS('couiFitUpdates')
external set _updates(JSFunction value);

/// How many rows each real host's menu has — more than a phone-sized
/// viewport has room for.
const int _kRows = 30;

void main() => client.runApp(CoUIWeb(theme: .coui, child: const _Probe()));

class _Probe extends StatefulComponent {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  /// What the rows reported, in order.
  final List<String> events = [];

  @override
  void initState() {
    super.initState();
    _events = (() => events.join(',')).toJS;
  }

  List<CoreMenuItem<Component>> _rows() => [
    for (var i = 1; i <= _kRows; i++)
      CoreMenuItem.action('Row $i', onPressed: () => events.add('Row $i')),
  ];

  @override
  Component build(BuildContext context) => div([
    const _RawFit(),
    // The hosts sit in a fixed layer the probe can move (`top`) to put a
    // trigger near the top or the middle of the viewport.
    div(
      [
        div(
          [
            DropdownMenu(
              id: 'dd',
              trigger: Button(
                id: 'dd-trigger',
                onPressed: () {},
                child: const Text('Open menu'),
              ),
              items: _rows(),
            ),
          ],
          styles: const Styles(
            raw: {'position': 'absolute', 'left': '16px', 'top': '0px'},
          ),
        ),
        div(
          [
            DropdownMenu(
              id: 'dd-short',
              trigger: Button(
                id: 'dd-short-trigger',
                onPressed: () {},
                child: const Text('Open short'),
              ),
              items: [
                CoreMenuItem.action('One', onPressed: () => events.add('One')),
                CoreMenuItem.action('Two', onPressed: () => events.add('Two')),
              ],
            ),
          ],
          styles: const Styles(
            raw: {'position': 'absolute', 'left': '200px', 'top': '0px'},
          ),
        ),
        div(
          [
            ContextMenu(
              id: 'cm',
              items: _rows(),
              child: const div(
                [Text('Context area')],
                id: 'cm-area',
                styles: Styles(raw: {'width': '120px', 'height': '60px'}),
              ),
            ),
          ],
          styles: const Styles(
            raw: {'position': 'absolute', 'left': '16px', 'top': '64px'},
          ),
        ),
        div(
          [
            Menubar(
              id: 'mb',
              menus: [
                CoreMenubarMenu(
                  label: 'File',
                  entries: [
                    for (var i = 1; i <= _kRows; i++)
                      CoreMenubarEntry.action(
                        label: 'Row $i',
                        onSelect: () => events.add('Row $i'),
                      ),
                  ],
                ),
              ],
            ),
          ],
          styles: const Styles(
            raw: {'position': 'absolute', 'left': '16px', 'top': '140px'},
          ),
        ),
      ],
      id: 'hosts',
      styles: const Styles(
        raw: {
          'position': 'fixed',
          'left': '0px',
          'top': '0px',
          'width': '100%',
          'height': '0px',
        },
      ),
    ),
  ]);
}

/// The positioner on its own, drawn the way a host draws it: the cap and the
/// origin come back through callbacks into component state, and the chrome is
/// the shipped `resolveOverlayFitBox` on the panel's box and
/// `resolveOverlayFitScroller` on the list inside it.
class _RawFit extends StatefulComponent {
  const _RawFit();

  @override
  State<_RawFit> createState() => _RawFitState();
}

class _RawFitState extends State<_RawFit> {
  double _extent = 0;
  double _before = 8;
  double _after = 8;
  double? _left;
  double? _top;
  double? _cap;
  OverlayPositioner? _positioner;

  /// How many times the positioner reported an origin — one per measurement.
  int _measurements = 0;

  @override
  void initState() {
    super.initState();
    _updates = (() => _measurements).toJS;
    _configure = ((double extent, double before, double after) {
      _positioner?.dispose();
      _positioner = null;
      setState(() {
        _extent = extent;
        _before = before;
        _after = after;
        _left = null;
        _top = null;
        _cap = null;
      });
    }).toJS;
    _start = (() {
      _positioner?.dispose();
      _positioner = OverlayPositioner(
        triggerId: 'fit-trigger',
        popoverId: 'fit-panel',
        viewportPadding: CoreEdgeInsets.only(
          left: 8,
          right: 8,
          top: _before,
          bottom: _after,
        ),
        closeOnOutsideClick: false,
        closeOnEsc: false,
        closeOnScroll: false,
        fitViewportHeight: true,
        onPosition: (left, top, _) => setState(() {
          _measurements++;
          _left = left;
          _top = top;
        }),
        onFit: (maxHeight) => setState(() => _cap = maxHeight),
      )..open();
    }).toJS;
  }

  @override
  void dispose() {
    _positioner?.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final cap = _cap;
    final scroller = cap == null ? null : resolveOverlayFitScroller();

    return div([
      const div(
        [],
        id: 'fit-trigger',
        styles: Styles(
          raw: {
            'position': 'fixed',
            'left': '120px',
            'top': '100px',
            'width': '80px',
            'height': '32px',
          },
        ),
      ),
      if (_extent > 0)
        div(
          [
            // The panel's own box: held to the cap, it does not scroll — the
            // list inside it does.
            div(
              [
                div(
                  [
                    // A block of the probe's height, which the list must not
                    // squeeze: it has no content of its own to hold it open.
                    div(
                      const [],
                      styles: Styles(
                        raw: {'height': '${_extent}px', 'flex': 'none'},
                      ),
                    ),
                  ],
                  id: 'fit-root',
                  classes: scroller?.className,
                  styles: scroller?.inlineStyles,
                ),
              ],
              id: 'fit-box',
              styles: Styles.combine([
                const Styles(
                  raw: {
                    'width': '160px',
                    'display': 'flex',
                    'flex-direction': 'column',
                    'overflow': 'hidden',
                  },
                ),
                ?(cap == null ? null : resolveOverlayFitBox(maxHeight: cap)),
              ]),
            ),
          ],
          id: 'fit-panel',
          styles: Styles(
            raw: {
              'position': 'fixed',
              if (_left != null) 'left': '${_left}px',
              if (_top != null) 'top': '${_top}px',
              if (_left == null) 'visibility': 'hidden',
            },
          ),
        ),
    ]);
  }
}
