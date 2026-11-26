/// The property fields a `PropertySnapshot` can carry, common to Flutter and
/// Web after normalization (#3606 owns the normalization itself — this enum
/// is the shared vocabulary both the manifest's `ProbeSpec` and the
/// normalizer's output key off).
///
/// Source: `.bmad/architecture-*.md` Data Architecture → `PropertySnapshot`.
enum PropertyField {
  fontFamily,
  fontWeight,
  fontSizePx,
  lineHeightPx,
  letterSpacingPx,
  color,
  backgroundColor,
  borderColor,
  borderWidthPx,
  borderRadiusPx,
  paddingPx,
  outlineWidthPx,
  outlineOffsetPx,
  boxShadow,
  opacity,

  // Geometry. Everything above describes how a box is PAINTED; these two
  // are how big it came out, and nothing in this set could see that
  // before — a component whose size token one platform honours and the
  // other treats as a minimum produced two different boxes and fifteen
  // matching fields.
  //
  // Both sides report the BORDER box: Flutter's `RenderBox.size` and
  // Web's `getBoundingClientRect()`. Not `getComputedStyle().width` —
  // that is the content box in Chrome regardless of `box-sizing`, so it
  // would have compared Flutter's outer edge against Web's inner one and
  // called every padded component divergent.
  widthPx,
  heightPx;

  /// Every field — the conservative default for a probe role the manifest
  /// cannot yet say more about than "read whatever this role has".
  static const Set<PropertyField> all = {...PropertyField.values};
}
