/// How a `Dialog` spreads its actions across the panel.
library;

/// How a `Dialog` spreads its actions across the actions row — what
/// `CoreDialogStyle.actionsLayout` states.
///
/// The choice moves the actions, not the panel: the gap between two actions
/// and the gap between two rows stay `actionSpacing` / `actionRunSpacing`
/// in both layouts, and the order of the actions is the order the caller
/// handed in.
enum CoreDialogActionsLayout {
  /// At the panel's end, each action its own width. Actions that do not fit
  /// on one line wrap onto further rows, each row at the end — the
  /// desktop dialog, and the default.
  end,

  /// Every action starts at the same share of the row and together they fill
  /// it: one action takes the whole row, two split it in half. When either of
  /// two does not fit its half, both stack, each the full width of the panel.
  /// Three or more fill a line as far as they fit their shares and the next
  /// line takes the rest, every line filling its width — an action wider
  /// than its share keeps its own width there and the others share what it
  /// leaves. The mobile confirm dialog.
  stretch,
}
