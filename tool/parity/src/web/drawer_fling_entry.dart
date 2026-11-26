/// Client fixture: the shipped `Drawer`, opened from page script, so a probe
/// can put real pointer input through the shipped drag handlers.
///
/// The Web drawer's pointer path needs a real `PointerEvent`, real layout and
/// a real pointer capture — none of which the VM has — so the release rule's
/// Web half (`_DrawerEntryState._handlePointerUp`) can only be judged here.
/// Nothing in this file re-implements it: the drawer is opened through
/// `openDrawer` and the page only reports what happened to it.
///
/// Page API (all on `window`):
///
///   couiDrawerOpen(side, extent)  opens a drawer on `side`
///                                 (`bottom` / `top` / `left` / `right`) whose
///                                 panel is `extent` px long on its slide axis
///   couiDrawerDismissed()         how many opened drawers have been closed
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr/client.dart' as client show runApp;

@JS('couiDrawerOpen')
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
    _open = ((String sideName, double extent) {
      final side = CoreDrawerSide.values.byName(sideName);
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
            drawerStyle: style,
            content: const Text('panel body'),
          ),
        ).then((_) => dismissed++),
      );
    }).toJS;
  }

  @override
  Component build(BuildContext context) => const div([], id: 'probe-root');
}
