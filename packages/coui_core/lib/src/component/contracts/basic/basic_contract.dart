/// Platform-independent contract for unified basic slot-layout components.
library;

import 'package:coui_core/src/component/contracts/basic/basic_style.dart';

/// Contract for a unified slot-based layout component.
///
/// Arranges up to five slots — `leading`, `title`, `subtitle`, `content`,
/// `trailing` — in a single horizontal row with an inner vertical stack of
/// title/subtitle/content between leading and trailing. Each slot has its own
/// alignment and can be omitted independently.
///
/// Type parameters:
/// - [W] — platform widget/component type (`Widget` on Flutter, `Component`
///   on Web).
abstract interface class CoreBasicContract<W> {
  /// Widget displayed at the start of the row (e.g. icon, avatar).
  W? get leading;

  /// Primary title slot, shown above [subtitle] and [content].
  W? get title;

  /// Optional subtitle rendered below [title].
  W? get subtitle;

  /// Main content rendered below title/subtitle.
  W? get content;

  /// Widget displayed at the end of the row (e.g. action button).
  W? get trailing;

  /// Value shown at the end of the row, before the trailing icon
  /// (e.g. a count or a current selection). `null` hides it.
  W? get trailingText;

  /// Whether the [subtitle] slot is shown. Defaults to `true`; `false`
  /// hides it without discarding the slot.
  bool get showSubtitle;

  /// Whether to draw the built-in trailing chevron when [trailing] is
  /// `null`. Defaults to [defaultShowTrailingIcon]. A caller-supplied
  /// [trailing] always wins over the chevron.
  bool get showTrailingIcon;

  /// Default for [showTrailingIcon] — on: a `Basic` row with no `trailing`
  /// draws the chevron-right that says the row leads somewhere.
  static const bool defaultShowTrailingIcon = true;

  /// Default for [showSubtitle].
  static const bool defaultShowSubtitle = true;

  /// Whether to apply CoUI's default text styles to the slots.
  ///
  /// - `true` (default): title = small-medium, subtitle = xs muted, content
  ///   = small. Matches legacy Flutter `Basic`.
  /// - `false`: no enforced text style. Slots are rendered with whatever the
  ///   caller passes. Matches legacy Flutter `BasicLayout`.
  bool get forceTextStyle;

  /// Per-instance composite style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default (CoreBasicStyle.defaultX)
  ///   → CoreBasicTheme.style
  ///   → parent component slot override
  ///   → widget.basicStyle
  /// ```
  ///
  /// All chrome (alignment / spacing / padding / nested text styles) lives
  /// inside this slot — there are no flat chrome getters on the contract.
  CoreBasicStyle? get basicStyle;
}
