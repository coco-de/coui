/// Platform-independent contract for unified badge components.
///
/// Defines the interface that all Badge implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/badge/badge_form.dart';
import 'package:coui_core/src/component/contracts/badge/badge_style.dart';
import 'package:coui_core/src/component/contracts/badge/badge_tone.dart';
import 'package:coui_core/src/component/contracts/badge/badge_variant.dart';
import 'package:coui_core/src/size/component_size.dart';

/// Contract for a unified badge component.
///
/// Every chrome / dimensional override flows through the single
/// [badgeStyle] field — see [CoreBadgeStyle] for the merge chain.
/// Behaviour fields (`tone` / `variant` / `form` / `size` / `showDot` /
/// `child` / `leading` / `trailing` / `onPressed`) stay flat on the
/// contract.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
///
/// `onPressed` is a plain `void Function()?` — no separate callback
/// generic, so the contract keeps a single widget-type generic.
abstract interface class CoreBadgeContract<W> {
  /// Widget default size — the Flutter / Web `Badge` constructors
  /// reference this so the default cannot silently diverge.
  ///
  /// `md` is the 24px step: the height a status label and a tag share.
  static const CoreComponentSize defaultSize = CoreComponentSize.md;

  /// Widget default for [showDot] — off. The dot is a status cue a caller
  /// asks for, not decoration every label carries.
  static const bool defaultShowDot = false;

  /// What the badge's colour means.
  CoreBadgeTone get tone;

  /// How loud the badge is — filled, tonal or outlined.
  ///
  /// Orthogonal to [tone] — every tone has all three strengths.
  CoreBadgeVariant get variant;

  /// Whether this badge holds a word, a number, or nothing.
  ///
  /// Orthogonal to [tone] — a dot still wears the tone's colour.
  CoreBadgeForm get form;

  /// Whether a small status dot is drawn before the content.
  ///
  /// The dot takes the label's colour, so it reads as part of the label
  /// rather than as a second signal. Not drawn in [CoreBadgeForm.dot],
  /// which is a dot already.
  bool get showDot;

  /// Content of the badge.
  ///
  /// Label-form text wraps within the width left by the dot, leading and
  /// trailing slots when the parent bounds its width. The badge grows in
  /// height as needed; without a width bound it keeps its natural width.
  /// Parents that lay out children without a width limit (such as a Row)
  /// must supply a bound to request wrapping. Explicit text overflow or
  /// line limits remain the caller's choice.
  /// Count-form text stays on one line and defaults to ellipsis if bounded;
  /// its full value remains available to assistive technology.
  ///
  /// Nullable because [CoreBadgeForm.dot] has none. For
  /// [CoreBadgeForm.label] and [CoreBadgeForm.count] callers are expected
  /// to pass it; a badge with no content collapses to its padding, which
  /// is a caller error the type system deliberately does not try to catch
  /// — making it non-null would make the dot form unexpressible.
  W? get child;

  /// Widget displayed before the content.
  ///
  /// Not drawn in [CoreBadgeForm.dot] — a dot has no content row to
  /// lead.
  W? get leading;

  /// Widget displayed after the content.
  ///
  /// Not drawn in [CoreBadgeForm.dot], for the same reason as
  /// [leading].
  W? get trailing;

  /// Callback when the badge is pressed.
  void Function()? get onPressed;

  /// Size of the badge.
  CoreComponentSize get size;

  /// Per-instance badge chrome / dimensional / slot style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default (size row → form row → tone row × variant)
  ///   → CoreBadgeTheme.style
  ///   → CoreBadgeTheme.toneStyles[tone]
  ///   → CoreBadgeTheme.variantStyles[variant]
  ///   → parent component slot override
  ///   → widget.badgeStyle
  /// ```
  CoreBadgeStyle? get badgeStyle;
}
