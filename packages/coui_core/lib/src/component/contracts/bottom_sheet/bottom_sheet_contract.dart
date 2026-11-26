/// Cross-platform contract for `BottomSheet`.
library;

import 'package:coui_core/src/component/contracts/bottom_action_bar/bottom_action_bar_style.dart';
import 'package:coui_core/src/component/contracts/bottom_action_bar/bottom_action_bar_theme.dart';
import 'package:coui_core/src/component/contracts/bottom_sheet/bottom_sheet_style.dart';

/// The panel that rises from the bottom of a phone screen — a title, a short
/// line under it, the content, and the actions that finish it.
///
/// Anatomy, top to bottom: `[ handle ] [ title · close ] [ description ]
/// [ divider ] [ content ] [ footer ]`. The sheet owns the arrangement, the
/// padding and the filled surface with its two rounded top corners; the
/// content and the footer (usually a `BottomActionBar`) are the caller's own.
///
/// The sheet is at most [CoreBottomSheetStyle.maxHeightFactor] of the
/// viewport's height. When the content is taller, the content alone scrolls:
/// the header stays at the top, the footer stays pinned at the bottom, and
/// the content is clipped above the footer — it never shows behind the
/// actions. The footer's area paints no fill of its own, and the hairline
/// above it is the sheet's: drawn only while more content lies below the
/// visible part.
///
/// The sheet is the panel, not the presenter: it does not open, dim the page
/// or dismiss itself. A caller that needs the sheet to slide over a page
/// places it in an overlay of its own.
///
/// Chrome flows through the single [bottomSheetStyle] slot; everything here
/// is content (the slots), a visibility flag or a callback.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreBottomSheetContract<W> {
  /// Default for the grab handle at the top — on.
  static const bool defaultShowHandle = true;

  /// Default for the close button at the end of the title row — off.
  static const bool defaultShowCloseButton = false;

  /// Default for the hairline between the header and the content — off.
  static const bool defaultShowDivider = false;

  /// The `BottomActionBar` theme style a sheet installs around its
  /// [footer].
  ///
  /// [inherited] is the project-wide bar theme in effect around the sheet;
  /// [footerBarStyle] is the sheet's resolved `footerBarStyle` (its default
  /// merged with what the sheet's theme and instance state). The sheet's
  /// statement wins over the project-wide bar theme — the project theme
  /// describes standalone bars, and a bar in a sheet is the sheet's action
  /// area — while the bar's own per-instance style still wins over both,
  /// because it sits after the theme in the bar's chain.
  ///
  /// Both platforms call this one function, so the sheet's footer resolves
  /// identically on Flutter and Web.
  static CoreBottomActionBarStyle footerBarThemeStyle(
    CoreBottomActionBarTheme? inherited,
    CoreBottomActionBarStyle footerBarStyle,
  ) => (inherited?.style ?? const CoreBottomActionBarStyle()).merge(
    footerBarStyle,
  );

  /// The sheet's name. Required.
  W get title;

  /// A short line under [title]. Absent by default.
  W? get description;

  /// The body of the sheet. Absent by default.
  W? get content;

  /// The area pinned under the content — a `BottomActionBar` by convention.
  /// Absent by default; it carries its own padding.
  ///
  /// A `BottomActionBar` placed here takes the sheet's
  /// [CoreBottomSheetStyle.footerBarStyle] (no fill, no hairline of its
  /// own). Any other widget is placed as it is — the sheet does not restyle
  /// it — and still gets the sheet's hairline above it while the content
  /// continues below.
  W? get footer;

  /// Whether the grab handle is drawn above the title.
  bool get showHandle;

  /// Whether the close button is drawn at the end of the title row.
  bool get showCloseButton;

  /// Whether the hairline between the header and the content is drawn.
  bool get showDivider;

  /// Called when the close button is pressed. The sheet is not the
  /// presenter, so it only reports the press.
  void Function()? get onClose;

  /// Single chrome slot — see [CoreBottomSheetStyle].
  CoreBottomSheetStyle? get bottomSheetStyle;
}
