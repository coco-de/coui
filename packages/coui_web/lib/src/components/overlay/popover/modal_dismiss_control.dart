/// The assistive-technology twin of a modal surface's scrim click.
///
/// A modal surface leaves the page behind it `inert` (`OverlayHost`): out of
/// the accessibility tree, out of the tab order, out of hit-testing. A pointer
/// user closes the surface by clicking the scrim, a keyboard user with
/// `Escape`. A screen-reader user on a touch device has neither — the scrim is
/// `aria-hidden` and there is no key — and a screen-reader gesture that means
/// "dismiss" has nothing to land on. [modalDismissControl] is the node they can
/// find and activate: a button named by the locale's dismiss label, the same
/// name the Flutter seat gives the `dismiss` action it attaches to the same
/// surfaces (`Semantics(onDismiss:)` on a modal popover panel).
///
/// It is a phantom accessibility node, drawn for nobody: `sr-only`, and out of
/// the tab order. A tab stop no one can see lands keyboard focus on a clipped
/// 1px element with no indicator (WCAG 2.4.7), and the keyboard already has
/// `Escape`. Assistive technology reaches it by its own navigation and
/// activates it, which the browser delivers as a click — so `Enter` and the
/// space bar are handled too, for the moment a reader moves focus onto it.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/jaspr.dart';

/// Marks the control, the way `data-coui-backdrop` marks the host's backdrop.
const String kModalDismissAttribute = 'data-coui-modal-dismiss';

/// The control for a modal surface that [onDismiss] closes.
///
/// Mount it beside the panel in the same overlay entry, and only while the
/// surface really is dismissible by clicking away: a modal surface that
/// ignores outside clicks offers no action either, for the same reason the
/// scrim does nothing there. A surface that is not modal leaves the page
/// reachable, so the page's own controls are the way out.
///
/// It carries no top-layer marker: it is `absolute` and 1px, so it needs no
/// viewport containing block, and a marked element would be promoted and
/// counted as a panel.
Component modalDismissControl(
  BuildContext context, {
  required void Function() onDismiss,
}) {
  return Component.element(
    tag: 'div',
    classes: WebLayout.srOnly,
    attributes: {
      'role': CoreSemanticRole.button.ariaRole,
      'tabindex': '-1',
      'aria-label': CouiLocalizations.of(context).dismissLabel,
      kModalDismissAttribute: '',
    },
    events: {
      'click': (_) => onDismiss(),
      'keydown': EventHandlers.createKeyboardEventHandler((event) {
        final key = event.key;
        if (key == ' ' || key == 'Enter') {
          event.preventDefault();
          onDismiss();
        }
      }),
    },
  );
}
