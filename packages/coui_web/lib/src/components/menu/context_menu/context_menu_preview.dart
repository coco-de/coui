import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/components/infra/popup/popup.dart';
import 'package:coui_web/src/overlay/top_layer.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// The preview of an open `ContextMenu`: the thing the menu is about, shown
/// beside it in the floating-panel chrome.
///
/// It is the second wrapper of the menu's portal entry, a sibling of the
/// engine-positioned panel wrapper, so it unmounts with the menu and is lifted
/// into the top layer the way the panel is. The menu keeps the place the
/// overlay engine gave it; where this goes is `CoreContextMenuPreview.place`
/// around the box the menu ended up in, and the host measures that box and
/// hands the answer to the resolver as [chrome]. This component only draws.
///
/// ```text
/// wrapper (<div fixed>)                  // [chrome]: corner and largest size
///   └─ motion (<div>)                    // [motion]: fades with the panel
///        └─ Popup (<div>)                // the floating-panel chrome
///             └─ child                   // caller-supplied preview
/// ```
///
/// The wrapper ignores the pointer, so a tap on the preview is a tap outside
/// the menu. Until the host places it the motion box is transparent, which
/// lets the host measure the preview at its natural size without it being seen
/// at the origin.
class ContextMenuPreviewLayer extends StatelessComponent {
  /// Creates a [ContextMenuPreviewLayer] drawing [child] in the wrapper
  /// [id], placed by [chrome] and faded by [motion].
  const ContextMenuPreviewLayer({
    required this.id,
    required this.chrome,
    required this.motion,
    required this.child,
    super.key,
  });

  /// The wrapper's id — what the host measures the preview's size through.
  final String id;

  /// The wrapper's class and inline styles (`ResolvedContextMenu.preview`).
  final WebElementChrome chrome;

  /// The fade the panel plays, from `resolveOverlayMotion`.
  final WebElementChrome motion;

  /// The preview the caller gave the menu.
  final Component child;

  @override
  Component build(BuildContext context) {
    return div(
      [
        div(
          [
            // The preview is a picture of something, not a menu, so the
            // panel chrome's default `menu` role is replaced by none.
            Popup(
              attributes: const {'role': 'presentation'},
              children: [child],
            ),
          ],
          classes: motion.className,
          styles: motion.inlineStyles,
        ),
      ],
      id: id,
      classes: chrome.className,
      styles: chrome.inlineStyles,
      attributes: TopLayer.attributesFor(context),
    );
  }
}
