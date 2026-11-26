/// Supported raster image formats for `ImageProperties`.
library;

/// Image format enum shared by the Flutter and Web image-editing
/// components.
///
/// Mirrors the legacy Flutter / Web `ImageType` enum 1:1 — same
/// members, same order — so existing call sites map directly onto the
/// unified `CoreImageType`.
enum CoreImageType {
  /// BMP (bitmap) format.
  bmp,

  /// GIF (graphics interchange) format.
  gif,

  /// ICO (icon) format.
  ico,

  /// JPEG format.
  jpg,

  /// PNG (portable network graphics) format.
  png,

  /// PVR (PowerVR texture) format.
  pvr,

  /// TGA (Truevision graphics adapter) format.
  tga,

  /// TIFF (tagged image file) format.
  tiff;

  /// Default image format for new editing sessions.
  static const CoreImageType defaultType = png;
}
