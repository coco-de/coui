/// Platform-independent contract for the disclosure badge component.
library;

import 'package:coui_core/src/component/contracts/disclosure_badge/core_disclosure_kind.dart';
import 'package:coui_core/src/component/contracts/disclosure_badge/disclosure_badge_style.dart';
import 'package:coui_core/src/typography/text_overflow.dart';

/// Contract for a disclosure badge — a static marker stating whether a
/// piece of evidence can be opened right now.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
///   No member is typed `W` today because the badge has exactly one
///   content slot and it is plain text ([label]); the parameter is kept
///   so the Flutter twin declares
///   `CoreDisclosureBadgeContract<Widget>` like every sibling contract
///   and so a future slot has somewhere to land.
///
/// ### Why [label] is a required `String` and not an optional slot
///
/// The badge's whole job is to state a disclosure status. If the status
/// can render as an outline with nothing in it, the state is carried by
/// colour and shape alone — which fails a screen reader outright and
/// makes the shape distinction do work it was only meant to reinforce.
/// A required, non-empty [label] is the enforcement.
abstract interface class CoreDisclosureBadgeContract<W> {
  /// Which of the three disclosure states this badge states.
  CoreDisclosureKind get kind;

  /// The status text. Required and non-empty — see the class doc.
  ///
  /// For [CoreDisclosureKind.private] this is where the reason goes
  /// ("비공개 · NDA"), not a bare "비공개".
  String get label;

  /// Maximum number of lines for [label] before it overflows.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  int? get labelMaxLines;

  /// How [label] overflow is handled once [labelMaxLines] is reached.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  CoreTextOverflow? get labelOverflow;

  /// Per-instance chrome style. See [CoreDisclosureBadgeStyle] for the
  /// merge chain and for the three overrides it deliberately does not
  /// offer.
  CoreDisclosureBadgeStyle? get disclosureBadgeStyle;
}
