/// How loudly a `Banner` says whatever `CoreBannerVariant` it is.
///
/// The second of Banner's two variant axes. `CoreBannerVariant` answers
/// "what kind of message is this"; this one answers "how hard does it
/// press". They stay separate axes rather than one flattened enum for the
/// reason the design file gives: folding them turns a 5 × 2 lookup into
/// 10 hand-authored entries, and every later tone has to be authored
/// twice or silently miss one emphasis.
///
/// Named `Emphasis` rather than mirroring Figma's `Style` axis label
/// because `CoreBannerStyle` is already this component's chrome-slot
/// class — a `CoreBannerStyle` enum next to a `CoreBannerStyle` style
/// class would be unreadable at every call site.
enum CoreBannerEmphasis {
  /// Tinted container fill with a hairline bottom rule — the default.
  ///
  /// Reads as page furniture: present, legible, but not competing with
  /// the content underneath it.
  weak,

  /// Saturated fill in the tone's own colour, no rule.
  ///
  /// Reserved for messages the user genuinely cannot be allowed to miss
  /// — service outages, forced maintenance. Using it for ordinary
  /// information wears the signal out, and then it is not available when
  /// something actually is urgent.
  solid;

  /// Widget default emphasis — the Flutter / Web `Banner` constructors
  /// reference this so the default cannot silently diverge.
  static const CoreBannerEmphasis defaultEmphasis = weak;
}
