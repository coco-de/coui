/// Platform-independent contract for a unified page footer.
library;

import 'package:coui_core/src/component/contracts/footer/core_footer_layout.dart';
import 'package:coui_core/src/component/contracts/footer/footer_style.dart';

/// A single navigation section rendered inside a footer.
///
/// Holds a platform-neutral list of links/widgets; the actual item widget or
/// component is built by the platform implementation.
class CoreFooterNavData<W> {
  /// Creates a [CoreFooterNavData].
  const CoreFooterNavData({
    required this.children,
    this.title,
  });

  /// Optional section title rendered above [children] with a heavier font
  /// weight. Skipped entirely when null or empty.
  final String? title;

  /// Link-like widgets/components displayed below the title. Usually a list
  /// of `Link` or plain text nodes.
  final List<W> children;
}

/// Contract for a unified page footer bar.
///
/// The footer stacks up to three blocks: an optional top rule
/// ([showDivider]), the navigation band ([aside] + [sections]), and the
/// legal block ([company] / the business-info disclosure / [links] /
/// [copyright]). Every block below the first is skipped when its slots
/// are empty, so a footer that only carries navigation renders exactly
/// what it did before the legal block existed.
///
/// Chrome flows through the single [footerStyle] slot; composition
/// slots ([aside] / [company] / [businessInfo] / [businessInfoLabel] /
/// [links] / [copyright]) and behaviour flags ([businessInfoExpanded] /
/// [showDivider]) stay flat here.
///
/// Type parameters:
/// - [W] — platform widget type (`Widget` on Flutter, `Component` on Web).
abstract interface class CoreFooterContract<W> {
  // Behaviour defaults shared by both platforms — the constructors bind
  // their flags to these so Flutter ↔ Web cannot drift apart in a
  // file-local `_kDefault*` const.

  /// Default expanded state of the business-info disclosure — collapsed,
  /// matching the designer set's `Info=collapsed` member.
  static const bool defaultBusinessInfoExpanded = false;

  /// Default for the top hairline rule — off. The designer set hides the
  /// rule in every member and calls it an opt-in ("기본 꺼짐 옵션"), so a
  /// footer that says nothing draws no rule.
  static const bool defaultShowDivider = false;

  /// Navigation sections rendered inside the footer from leading to
  /// trailing order.
  List<CoreFooterNavData<W>> get sections;

  /// Branding / logo slot rendered before [sections]. Typically holds a logo
  /// + copyright paragraph.
  W? get aside;

  /// Layout mode. When null, falls back to `CoreFooterTheme.layout` or
  /// [CoreFooterLayout.horizontal].
  CoreFooterLayout? get layout;

  /// Company name rendered at the head of the legal block's first row.
  ///
  /// Typography arrives as the ambient text style the platform installs
  /// from `CoreFooterStyle.companyTextStyle`, so a plain `Text('…')`
  /// inherits it and a `Text('…').titleMedium` chain still wins.
  W? get company;

  /// Label of the business-info disclosure trigger (e.g. "Business info").
  ///
  /// Rendered as the trigger of the composed `Collapsible`, which draws
  /// its own chevron — this slot carries the label alone.
  W? get businessInfoLabel;

  /// The disclosure paragraph revealed by [businessInfoLabel] — the
  /// registration details a storefront is required to publish.
  ///
  /// `null` means the footer draws no disclosure at all: no trigger, no
  /// chevron, no hairline tick before it. The trigger is only an affordance
  /// for this paragraph, so it cannot outlive it.
  W? get businessInfo;

  /// Whether the business-info disclosure starts expanded.
  ///
  /// Forwarded to the composed `Collapsible`. Leaving
  /// [onBusinessInfoExpandedChanged] null lets that `Collapsible`
  /// self-manage the toggle from this initial state; supplying the
  /// callback makes this a controlled value the caller owns.
  bool get businessInfoExpanded;

  /// Called when the business-info disclosure is toggled.
  ///
  /// Forwarded to the composed `Collapsible`'s `onExpandedChanged`.
  void Function(bool)? get onBusinessInfoExpandedChanged;

  /// Legal links rendered in a row, separated by hairline ticks.
  ///
  /// Usually `Link` widgets. Empty means the row is not drawn.
  List<W> get links;

  /// Copyright line closing the legal block.
  W? get copyright;

  /// Whether the top hairline rule above the navigation band is drawn.
  bool get showDivider;

  /// Accessible label announced by screen readers for the footer landmark.
  String? get semanticLabel;

  /// Per-instance composite chrome / slot style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default (CoreFooterStyle.defaultX)
  ///   → CoreFooterTheme.style
  ///   → parent component slot override
  ///   → widget.footerStyle
  /// ```
  ///
  /// Carries chrome (background / text colour / padding / block and row
  /// spacing) plus the nested text, `Divider`, and `Collapsible` slots the
  /// footer composes.
  CoreFooterStyle? get footerStyle;
}
