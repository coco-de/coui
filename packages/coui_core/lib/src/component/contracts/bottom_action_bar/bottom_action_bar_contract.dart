/// Cross-platform contract for `BottomActionBar`.
library;

import 'package:coui_core/src/component/contracts/bottom_action_bar/bottom_action_bar_layout.dart';
import 'package:coui_core/src/component/contracts/bottom_action_bar/bottom_action_bar_style.dart';

/// The action area pinned to the bottom of a screen — the one or two buttons
/// that finish a flow (register, pay, confirm), and an optional short note
/// above them.
///
/// Anatomy: `[ divider ] [ note ] [ primary ] [ secondary ]` (or, in the
/// summary layout, `[ summary ] [ primary ]`), over a filled
/// surface. The bar owns the arrangement, the padding, the hairline above it
/// and the surface; the buttons are the caller's own `Button`s and keep their
/// own size and look. The bar gives each action the full width of its cell,
/// so a `Button` inside needs no `expanded` of its own.
///
/// The bottom padding is added to the device's bottom safe area (the home
/// indicator): the surface paints under it and the actions sit above it.
///
/// Chrome flows through the single [bottomActionBarStyle] slot; everything
/// here is content (the slots), arrangement ([layout]) or a visibility
/// flag ([showDivider]).
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreBottomActionBarContract<W> {
  /// Default for the hairline above the bar — on.
  static const bool defaultShowDivider = true;

  /// The action that finishes the flow. Required; first in the column,
  /// last in the row.
  W get primaryAction;

  /// The quieter alternative to [primaryAction] — a ghost `Button` by
  /// convention. Absent by default.
  W? get secondaryAction;

  /// A short note above the actions (a consent line, a fee notice). Absent
  /// by default. Its text takes [CoreBottomActionBarStyle.descriptionTextStyle]
  /// through the ambient text style.
  W? get description;

  /// The small caption of the summary (a total's name). Drawn only in
  /// [CoreBottomActionBarLayout.summary], over [summaryValue]. Absent by
  /// default. Its text takes [CoreBottomActionBarStyle.summaryLabelTextStyle]
  /// through the ambient text style.
  W? get summaryLabel;

  /// The figure of the summary (a total). Drawn only in
  /// [CoreBottomActionBarLayout.summary], under [summaryLabel]. Absent by
  /// default. Its text takes [CoreBottomActionBarStyle.summaryValueTextStyle]
  /// through the ambient text style.
  W? get summaryValue;

  /// How the actions are arranged — see [CoreBottomActionBarLayout].
  CoreBottomActionBarLayout get layout;

  /// Whether the hairline above the bar is drawn.
  bool get showDivider;

  /// Single chrome slot — see [CoreBottomActionBarStyle].
  CoreBottomActionBarStyle? get bottomActionBarStyle;
}
