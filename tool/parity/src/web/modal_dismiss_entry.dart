/// Client fixture for the modal dismiss control probe.
///
/// The surfaces whose scrim click has a screen-reader twin, and the ones that
/// must not have it, on one page whose background has a focusable control — so
/// the probe can judge in a real browser what a VM cannot: that the control is
/// clipped to nothing, never reached by Tab, activated by a click or by
/// `Enter` / space, and that closing brings the page behind it back.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr/client.dart' as client show runApp;

void main() => client.runApp(CoUIWeb(theme: .coui, child: const _Probe()));

class _Probe extends StatelessComponent {
  const _Probe();

  @override
  Component build(BuildContext context) => div(
    [
      // The page behind an open modal surface: focusable, so `inert` has
      // something to take out of the tab order.
      Button(
        id: 'bg-button',
        onPressed: () {},
        child: const Text('Background'),
      ),
      Popover(
        id: 'pop',
        modal: true,
        trigger: Button(
          id: 'pop-trigger',
          onPressed: () {},
          child: const Text('Open modal'),
        ),
        content: const Text('Modal body'),
      ),
      Popover(
        id: 'pop-plain',
        trigger: Button(
          id: 'pop-plain-trigger',
          onPressed: () {},
          child: const Text('Open plain'),
        ),
        content: const Text('Plain body'),
      ),
      Popover(
        id: 'pop-sticky',
        modal: true,
        dismissOnOutsideTap: false,
        trigger: Button(
          id: 'pop-sticky-trigger',
          onPressed: () {},
          child: const Text('Open sticky'),
        ),
        content: const Text('Sticky body'),
      ),
      DropdownMenu(
        id: 'dd',
        trigger: Button(
          id: 'dd-trigger',
          onPressed: () {},
          child: const Text('Open menu'),
        ),
        items: [
          CoreMenuItem.action('One', onPressed: () {}),
          CoreMenuItem.action('Two', onPressed: () {}),
        ],
      ),
      ContextMenu(
        id: 'cm',
        items: [
          CoreMenuItem.action('Copy', onPressed: () {}),
          CoreMenuItem.action('Paste', onPressed: () {}),
        ],
        child: const div(
          [Text('Context area')],
          id: 'cm-area',
          styles: Styles(raw: {'width': '160px', 'height': '60px'}),
        ),
      ),
    ],
    styles: const Styles(
      raw: {
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': '16px',
        'padding': '16px',
        'align-items': 'flex-start',
      },
    ),
  );
}
