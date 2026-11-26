import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/form/rich_editor/rich_editor_toolbar.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;

/// The formatting toolbar a [RichEditor] floats over a run of selected text
/// (`RichEditor.showSelectionToolbar`).
///
/// It is the toolbar at the top of the editor's box, drawn by the same code
/// ([RichEditorToolbarBar]) from the same resolved chrome: the block-type
/// button and its menu, then the groups of
/// [CoreRichEditorFormat.selectionToolbar] — the inline formats, the lists
/// and the quote, with no image button — a gap and a line between groups.
/// What it adds is the face it sits on: a `Popup`, with the corner and the
/// inset `CoreRichEditorStyle.selectionToolbarPanelStyle` states. Too narrow
/// for its buttons it does not wrap: the bar folds them into a "more" (⋯)
/// menu, the quote first, then the lists, then the inline formats from the
/// link back ([CoreRichEditorFormat.selectionToolbarFoldOrder]); the
/// block-type menu always shows.
///
/// The editor owns everything else — when the toolbar shows, where it sits
/// (through the shared popover engine) and what a press does. This widget
/// has no say in any of it: the editor answers [isOn], [canApply] and
/// [onApply], and is told about Escape through [onDismiss].
///
/// Not exported: an app turns the toolbar off with
/// `RichEditor.showSelectionToolbar`, and restyles it through
/// `richEditorStyle`.
///
/// surface:functional — the panel is the composed `Popup`'s, mounted over
/// the page by the editor.
class RichEditorSelectionToolbar extends StatelessWidget {
  /// Creates a [RichEditorSelectionToolbar].
  const RichEditorSelectionToolbar({
    required this.resolved,
    required this.apple,
    required this.isOn,
    required this.canApply,
    required this.onApply,
    this.groups = CoreRichEditorFormat.selectionToolbar,
    this.availableWidth,
    this.focusScopeNode,
    this.onDismiss,
    this.onMenuOpenChanged,
    super.key,
  });

  /// Prefix of each button's `ValueKey` (`richEditorSelection.<format>`).
  static const String keyPrefix = 'richEditorSelection';

  /// The editor's resolved chrome; the toolbar slots and the panel are read.
  final ResolvedRichEditor resolved;

  /// Whether the shortcuts read ⌘ rather than Ctrl.
  final bool apple;

  /// Whether the format is on at the selection.
  final bool Function(CoreRichEditorFormat format) isOn;

  /// Whether the format can be applied now.
  final bool Function(CoreRichEditorFormat format) canApply;

  /// A button was pressed.
  final ValueChanged<CoreRichEditorFormat> onApply;

  /// The groups to draw.
  final List<List<CoreRichEditorFormat>> groups;

  /// The room the bar inside the panel has — the screen less the margins
  /// the panel is held inside of and the panel's own inset and line. The
  /// bar folds its buttons to it; null folds to the width it is given.
  final double? availableWidth;

  /// The scope the buttons take the keyboard's focus in; the editor reads it
  /// to tell the focus going to the toolbar from the focus leaving.
  final FocusScopeNode? focusScopeNode;

  /// Escape was pressed with the focus in the toolbar.
  final VoidCallback? onDismiss;

  /// Told when a menu of the toolbar — the block-type menu, the "more"
  /// menu — opens and closes.
  final ValueChanged<bool>? onMenuOpenChanged;

  @override
  Widget build(BuildContext context) {
    final localizations = CoUILocalizations.of(context);
    final dismiss = onDismiss;
    // One child, laid out down the panel: the bar then gets the room the
    // engine leaves the panel, and folds buttons into its "more" menu when
    // the screen is narrower than they are — it never wraps.
    final panel = FocusScope(
      node: focusScopeNode,
      child: Popup(
        popupStyle: resolved.selectionToolbarPanelStyle,
        children: [
          RichEditorToolbarBar(
            groups: groups,
            resolved: resolved,
            apple: apple,
            isOn: isOn,
            canApply: canApply,
            onApply: onApply,
            keyPrefix: keyPrefix,
            groupDividers: true,
            foldable: true,
            availableWidth: availableWidth,
            label: localizations.richEditorSelectionToolbar,
            onMenuOpenChanged: onMenuOpenChanged,
          ),
        ],
      ),
    );
    if (dismiss == null) return panel;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            // `CallbackAction.onInvoke` returns `Object?`; a dismiss has
            // nothing to hand back.
            onInvoke: (_) {
              dismiss();

              return null;
            },
          ),
        },
        child: panel,
      ),
    );
  }
}
