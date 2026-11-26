/// Client fixture: the shipped `Drawer`, opened from page script with a rubber
/// band, so a probe can put real pointer input through the shipped drag
/// handlers and read the panel back.
///
/// The Web drawer's pointer path needs a real `PointerEvent`, real layout, a
/// real pointer capture and a real CSS transition — none of which the VM has —
/// so the stretch, the pull back and the hand-over to a finger that takes hold
/// of a returning panel can only be judged here. Nothing in this file
/// re-implements them: the drawer is opened through `openDrawer` and the page
/// only reports what happened to it.
///
/// Page API (all on `window`):
///
///   couiRubberBandOpen(spec)  opens a drawer. `spec` is JSON:
///                               side        `bottom` / `top` / `left` / `right`
///                               extent      the panel's length on its slide
///                                           axis, px
///                               rubberBand  whether the panel may be pulled
///                                           past its dock (default true)
///                               sheet       a title and a grab handle
///                               scrolling   a body taller than the panel, so
///                                           it scrolls
///   couiDrawerDismissed()     how many opened drawers have been closed
library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr/client.dart' as client show runApp;

@JS('couiRubberBandOpen')
external set _open(JSFunction value);
@JS('couiDrawerDismissed')
external set _dismissed(JSFunction value);

void main() => client.runApp(CoUIWeb(theme: .coui, child: const _Probe()));

class _Probe extends StatefulComponent {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  int dismissed = 0;

  @override
  void initState() {
    super.initState();
    _dismissed = (() => dismissed).toJS;
    _open = ((String json) {
      final spec = jsonDecode(json) as Map<String, Object?>;
      final side = CoreDrawerSide.values.byName(spec['side']! as String);
      final extent = (spec['extent']! as num).toDouble();
      final sheet = (spec['sheet'] as bool?) ?? false;
      final scrolling = (spec['scrolling'] as bool?) ?? false;
      final horizontal = side == .left || side == .right;
      final style = horizontal
          ? CoreDrawerStyle(panelWidth: extent)
          : CoreDrawerStyle(panelHeight: extent);
      unawaited(
        openDrawer<void>(
          context: context,
          side: side,
          builder: (close) => Drawer(
            side: side,
            rubberBand: (spec['rubberBand'] as bool?) ?? true,
            title: sheet ? 'Sheet' : null,
            showDragHandle: sheet,
            drawerStyle: style,
            content: scrolling
                ? div([
                    for (var i = 0; i < 40; i++) div([Text('row $i')]),
                  ])
                : const Text('panel body'),
          ),
        ).then((_) => dismissed++),
      );
    }).toJS;
  }

  @override
  Component build(BuildContext context) => const div([], id: 'probe-root');
}
