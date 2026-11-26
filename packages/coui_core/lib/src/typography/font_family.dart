/// Font family primitive tokens.
///
/// Flutter: `CoreFontFamily.sans` → 'Pretendard' (폰트 이름).
/// Web: `CoreFontFamily.scale.sans` → 'sans' (Tailwind 키).
abstract final class CoreFontFamily {
  const CoreFontFamily._();

  // === Values (String — 폰트 이름) ===

  /// Sans-serif font (Pretendard).
  static const sans = 'Pretendard';

  /// Serif font (TBD).
  static const serif = '';

  /// Monospace font (Geist Mono — code/technical contexts).
  ///
  /// Geist Mono carries no Hangul, so both platforms fall back to [sans]
  /// for it. The fallback stacks are adapter-owned (not here): Flutter →
  /// the `GeistMono` coui_flutter bundles, then `Pretendard`; Web →
  /// `Pretendard`, `monospace`. Because Flutter bundles the face, an app
  /// that provides no Geist Mono still draws the same glyphs.
  static const mono = 'Geist Mono';

  // === Scale Names (String — Tailwind 키) ===

  /// Tailwind class name record for compile-safe interpolation.
  static const ({String mono, String sans, String serif}) scale = (
    sans: 'sans',
    serif: 'serif',
    mono: 'mono',
  );
}
