/// Cross-platform contract for unified banner components.
library;

import 'package:coui_core/src/component/contracts/banner/banner_emphasis.dart';
import 'package:coui_core/src/component/contracts/banner/banner_style.dart';
import 'package:coui_core/src/component/contracts/banner/banner_variant.dart';

/// Contract for a unified banner component.
///
/// Per Epic #1302 every chrome / dimensional override flows through
/// the single [bannerStyle] field — see [CoreBannerStyle] for the
/// merge chain. Behaviour fields stay flat on the contract.
///
/// Type parameters:
/// - [W]: Widget type (Flutter: `Widget`, Web: `Component`).
///
/// Phase 6f: `onDismiss` is a plain `void Function()?` — no separate
/// `Cb` generic (avoids Dart variance issues and keeps the contract a
/// single widget-type generic, verify.md 7-7).
///
/// Implementations render a full-width alert banner with variant-based
/// styling, optional icon, dismiss button, and action widget.
abstract interface class CoreBannerContract<W> {
  /// The main message content of the banner.
  ///
  /// Widget/Component (not String) so the host can put rich content
  /// in the slot — inline link, bold/italic spans, icon next to a
  /// label, etc. The host is expected to apply typography via the
  /// Text chain (`Text('...').labelLarge`) when a plain styled
  /// label is enough; banner does not force `labelLarge` over
  /// arbitrary children because doing so would clobber any
  /// customisation the host opts into.
  ///
  /// For surface-owned typography on plain strings, use
  /// `CoreAlertContract` instead.
  W get message;

  /// Optional description displayed below the message. Same
  /// "rich content allowed, host opts into typography" reasoning
  /// as [message].
  W? get description;

  /// The visual variant of the banner — *what kind* of message it is.
  CoreBannerVariant get variant;

  /// How hard the banner presses — *how loudly* it says its [variant].
  ///
  /// Separate axis from [variant] on purpose: the tone of a message and
  /// the force behind it vary independently, and folding them into one
  /// enum makes every future tone two entries to author instead of one.
  ///
  /// [CoreBannerEmphasis.solid] is for messages the reader genuinely
  /// cannot be allowed to miss. Spending it on ordinary information
  /// wears the signal out, and then it is not available when something
  /// actually is urgent.
  CoreBannerEmphasis get emphasis;

  /// Callback invoked when the dismiss button is pressed.
  ///
  /// If null, no dismiss button is shown.
  void Function()? get onDismiss;

  /// Whether the variant icon is shown at the leading edge.
  bool get showIcon;

  /// Optional action widget, typically a button.
  W? get action;

  /// Per-instance banner chrome / dimensional / slot style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreBannerTheme.style
  ///   → parent component slot override
  ///   → widget.bannerStyle
  /// ```
  CoreBannerStyle? get bannerStyle;
}
