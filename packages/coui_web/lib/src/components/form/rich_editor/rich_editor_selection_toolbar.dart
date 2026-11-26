import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/form/rich_editor/rich_editor_dom.dart';
import 'package:coui_web/src/components/form/rich_editor/rich_editor_style.dart';
import 'package:coui_web/src/components/form/rich_editor/rich_editor_toolbar.dart';
import 'package:coui_web/src/components/infra/popup/popup.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/overlay/popover/popover_controller.dart';
import 'package:coui_web/src/overlay/top_layer.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// The formatting toolbar a `RichEditor` floats over a run of selected text
/// (`RichEditor.showSelectionToolbar`).
///
/// It is the toolbar at the top of the editor's box, drawn by the same
/// component ([RichEditorToolbarBar]) from the same resolved chrome: the
/// block-type button and its menu, then the groups of
/// [CoreRichEditorFormat.selectionToolbar] — the inline formats, the lists
/// and the quote, with no image button — a gap and a line between groups.
/// What it adds is the face it sits on: a `Popup`, with the corner and the
/// inset `CoreRichEditorStyle.selectionToolbarPanelStyle` states. Too narrow
/// for its buttons it does not wrap: the bar folds them into a "more" (⋯)
/// menu ([foldSteps], measured by the editor), the quote first, then the
/// lists, then the inline formats from the link back; the block-type menu
/// always shows.
///
/// The editor owns everything else — when the toolbar shows, where it sits
/// (the shared `OverlayPositioner` measures the element [panelId] names) and
/// what a press does. This component has no say in any of it.
///
/// Not exported: an app turns the toolbar off with
/// `RichEditor.showSelectionToolbar`, and restyles it through
/// `richEditorStyle`.
///
/// ```text
/// root (<div id=panelId fixed popover="manual">)   // placed by the engine
///   └─ motion (<div>)                               // enter / exit keyframes
///        └─ Popup (role="toolbar")                  // ← panelStyle
///             └─ RichEditorToolbarBar               // the editor's own buttons
/// ```
///
/// surface:functional — the panel is the composed `Popup`'s, mounted over
/// the page by the editor.
class RichEditorSelectionToolbar extends StatelessComponent {
  /// Creates a [RichEditorSelectionToolbar].
  const RichEditorSelectionToolbar({
    required this.panelId,
    required this.chrome,
    required this.resolved,
    required this.active,
    required this.enabled,
    required this.apple,
    required this.surfaceId,
    required this.onFormat,
    required this.blockTypeMenu,
    required this.moreMenu,
    this.groups = CoreRichEditorFormat.selectionToolbar,
    this.foldSteps = 0,
    this.direction,
    this.onDismiss,
    this.onFocusOut,
    super.key,
  });

  /// The id of the element the positioning engine measures and places.
  final String panelId;

  /// The toolbar's own chrome: where it sits, its motion, its panel.
  final ResolvedRichEditorSelectionToolbar chrome;

  /// The editor's resolved chrome; the toolbar slots are read.
  final ResolvedRichEditor resolved;

  /// The formats on at the selection.
  final Set<CoreRichEditorFormat> active;

  /// Whether the buttons work.
  final bool enabled;

  /// Whether the shortcuts read ⌘ rather than Ctrl.
  final bool apple;

  /// The id of the editing surface the buttons control.
  final String surfaceId;

  /// A button was pressed, or a row of the block-type menu picked.
  final void Function(CoreRichEditorFormat format) onFormat;

  /// Opens and closes this toolbar's block-type menu.
  final PopoverController blockTypeMenu;

  /// Opens and closes this toolbar's "more" menu — the folded buttons.
  final PopoverController moreMenu;

  /// The groups to draw.
  final List<List<CoreRichEditorFormat>> groups;

  /// How many units of `CoreRichEditorFormat.selectionToolbarFoldOrder` the
  /// editor has folded into the "more" menu, having measured the bar
  /// against the room the engine leaves the panel.
  final int foldSteps;

  /// The direction the editor's text runs in (`ltr` / `rtl`). The panel is
  /// mounted on the page's overlay layer, away from the editor: an editor
  /// whose text runs the other way than the page keeps its direction on its
  /// toolbar through this.
  final String? direction;

  /// Escape was pressed with the focus in the toolbar.
  final void Function()? onDismiss;

  /// The focus left a button of the toolbar.
  final void Function()? onFocusOut;

  @override
  Component build(BuildContext context) {
    final l10n = CouiLocalizations.of(context);
    final dismiss = onDismiss;
    final focusOut = onFocusOut;
    final dir = direction;
    return div(
      [
        div(
          [
            Popup(
              popupStyle: chrome.panelStyle,
              attributes: {
                'role': 'toolbar',
                'aria-label': l10n.richEditorSelectionToolbar,
                'aria-controls': surfaceId,
              },
              children: [
                RichEditorToolbarBar(
                  groups: groups,
                  resolved: resolved,
                  active: active,
                  enabled: enabled,
                  apple: apple,
                  surfaceId: surfaceId,
                  onFormat: onFormat,
                  blockTypeMenu: blockTypeMenu,
                  moreMenu: moreMenu,
                  foldSteps: foldSteps,
                ),
              ],
            ),
          ],
          classes: chrome.motion.className,
          styles: chrome.motion.inlineStyles,
        ),
      ],
      id: panelId,
      classes: chrome.root.className,
      styles: chrome.root.inlineStyles,
      attributes: {
        ...TopLayer.attributesFor(context),
        'dir': ?dir,
      },
      events: {
        // A press on the toolbar must not take the focus — and with it the
        // selection — from the text. Keyboard activation does not press.
        'mousedown': richEditorPreventDefault,
        if (dismiss != null)
          'keydown': (event) {
            if (!richEditorKeyOf(event, apple: apple).escape) return;
            richEditorPreventDefault(event);
            dismiss();
          },
        if (focusOut != null) 'focusout': (_) => focusOut(),
      },
    );
  }
}
