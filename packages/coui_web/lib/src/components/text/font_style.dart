/// Font style enum for Web `TextStyle`.
///
/// Mirrors Flutter `dart:ui.FontStyle` so user code reads identically:
///
/// ```dart
/// // 양쪽 동일
/// Text('hi', style: TextStyle(fontStyle: FontStyle.italic))
/// ```
enum FontStyle {
  /// Selects a font that is classified as normal within a font-family.
  normal('normal'),

  /// Selects a font that is classified as italic.
  italic('italic');

  const FontStyle(this.cssValue);

  /// CSS `font-style` value.
  final String cssValue;
}
