/// The page the fold probe (`test/web/fold_probe_test.dart`) drives: a
/// CoUIWeb app whose content reads `FoldScope.of` into a script function,
/// with a dialog, a drawer and an anchored panel the probe opens. `?rtl`
/// mounts the app in Arabic, so its root reads right to left. `?ax=&ay=`
/// puts the anchored panel's trigger at that point of the viewport.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr/client.dart' as client show runApp;

@JS('couiFoldRead')
external set _read(JSFunction value);
@JS('couiFoldOpen')
external set _open(JSFunction value);
@JS('couiFoldOpenDrawer')
external set _openDrawer(JSFunction value);
@JS('couiFoldOpenPopover')
external set _openPopover(JSFunction value);

void main() {
  final rtl = Uri.base.queryParameters.containsKey('rtl');
  client.runApp(
    CoUIWeb(
      theme: .coui,
      locale: rtl ? const Locale('ar') : const Locale('en', 'US'),
      supportedLocales: const [Locale('ar'), Locale('en', 'US')],
      child: const _Probe(),
    ),
  );
}

class _Probe extends StatefulComponent {
  const _Probe();
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  bool open = false;
  CoreFoldLayout layout = CoreFoldLayout.unmeasured;
  final PopoverController _popover = PopoverController();

  @override
  void initState() {
    super.initState();
    _read = (() => jsonEncode({
      'kind': layout.kind?.name,
      'posture': layout.posture?.name,
      'split': layout.isSplit,
      'segments': [
        for (final segment in layout.segments)
          [segment.left, segment.top, segment.width, segment.height],
      ],
    })).toJS;
    _open = (() => setState(() => open = true)).toJS;
    _openDrawer = ((String side) {
      final docked = CoreDrawerSide.values.byName(side);
      unawaited(
        openDrawer<void>(
          context: context,
          side: docked,
          builder: (close) => Drawer(
            side: docked,
            content: const div(
              [],
              id: 'probe-drawer-content',
              styles: Styles(raw: {'width': '80px', 'height': '80px'}),
            ),
          ),
        ),
      );
    }).toJS;
    _openPopover = _popover.show.toJS;
  }

  @override
  void dispose() {
    _popover.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    layout = FoldScope.of(context);

    final query = Uri.base.queryParameters;
    final anchorX = query['ax'];
    final anchorY = query['ay'];

    return div([
      Dialog(
        open: open,
        title: const Text('Fold'),
        content: const Text('Which half does this open on?'),
      ),
      if (anchorX != null && anchorY != null)
        // A trigger at a point of the viewport, and a panel wide enough to
        // reach across a fold beside it.
        div(
          [
            Popover(
              controller: _popover,
              trigger: const div(
                [],
                id: 'probe-trigger',
                styles: Styles(raw: {'width': '40px', 'height': '40px'}),
              ),
              content: const div(
                [],
                id: 'probe-popover-content',
                styles: Styles(raw: {'width': '280px', 'height': '120px'}),
              ),
            ),
          ],
          styles: Styles(
            raw: {
              'position': 'fixed',
              'left': '${anchorX}px',
              'top': '${anchorY}px',
            },
          ),
        ),
    ]);
  }
}
