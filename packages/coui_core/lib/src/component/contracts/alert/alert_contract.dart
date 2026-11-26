/// Cross-platform contract for unified alert components.
library;

import 'package:coui_core/src/component/contracts/alert/alert_layout.dart';
import 'package:coui_core/src/component/contracts/alert/alert_style.dart';
import 'package:coui_core/src/component/contracts/alert/alert_variant.dart';

/// Contract for a unified alert component.
///
/// Per Epic #1302 every chrome / dimensional override flows through
/// the single [alertStyle] field — see [CoreAlertStyle] for the
/// merge chain. Behaviour fields stay flat on the contract.
///
/// Type parameters:
/// - [W]: Widget type (Flutter: `Widget`, Web: `Component`).
///
/// The callback type is derived directly rather than carried as a second
/// type parameter: both platforms spell it `void Function()`
/// (Flutter `VoidCallback`, Web `CoreVoidCallback`), so a `Cb` parameter
/// bought nothing and broke `cross-platform/api.md`'s rule that the only
/// generic here is the widget type.
abstract interface class CoreAlertContract<W> {
  /// Title displayed at the top of the alert.
  ///
  /// Required. Alert and Banner used to disagree on this — Banner took a
  /// required message with an optional description, Alert the exact
  /// reverse — so two components in the same family had opposite
  /// contracts for the same two slots. Both now read "title required,
  /// description optional" (#4505 — the flip landed there but was
  /// squashed into a commit whose `BREAKING CHANGE:` footer was empty on
  /// its own line, so it never reached the release notes; restated in
  /// a follow-up commit's footer).
  String get title;

  /// Optional body description displayed under the title.
  ///
  /// When absent the card keeps its full [CoreAlertStyle.defaultMinHeight]
  /// rather than collapsing, so a list of alerts stays on one rhythm
  /// whether or not individual entries carry a description.
  ///
  /// Not drawn in [CoreAlertLayout.inline] — a one-line strip has room for
  /// one voice, and the title is it.
  String? get description;

  /// The visual variant of the alert.
  CoreAlertVariant get variant;

  /// How the alert arranges its content — a panel with a title and a
  /// description ([CoreAlertLayout.stacked], the default) or a one-line
  /// status strip ([CoreAlertLayout.inline]).
  CoreAlertLayout get layout;

  /// Optional widget drawn in place of the tone glyph, in either layout.
  ///
  /// `null` draws the tone glyph the variant picks. A widget here replaces
  /// it outright — the alert does not draw both. The slot receives the
  /// glyph's colour and the layout's glyph size as the ambient icon theme,
  /// so a bare icon passed here matches the glyph it replaces; a status
  /// badge brings its own colours. The hand-off is the icon theme and
  /// nothing more: content that is not an icon is not recoloured and keeps
  /// the line height of the text beside it, on both platforms.
  W? get leading;

  /// Whether the alert draws its glyph slot — the tone glyph, or a caller's
  /// [leading] in its place — together with the gap after it.
  ///
  /// `false` leaves the title, the description, the action and the dismiss
  /// mark where they were and starts the text at the panel's inset: a
  /// notice that reads by its words and its tone, without a picture. The
  /// tone still reaches the panel colour, and a theme's
  /// `variantStyles[variant].titleColor` can carry it into the title.
  /// Defaults to [defaultShowIcon].
  bool get showIcon;

  /// Default for [showIcon] — the glyph slot is drawn. Both widgets take
  /// their default from here, so the two cannot drift apart.
  static const bool defaultShowIcon = true;

  /// Callback when the alert is dismissed.
  void Function()? get onDismiss;

  /// Optional action widget (e.g. button) displayed in the alert.
  W? get action;

  /// Per-instance alert chrome / dimensional / slot style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreAlertTheme.style
  ///   → parent component slot override
  ///   → widget.alertStyle
  /// ```
  CoreAlertStyle? get alertStyle;
}
