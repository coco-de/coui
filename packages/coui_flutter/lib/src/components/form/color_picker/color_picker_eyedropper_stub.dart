/// Non-web stub for the Flutter `ColorPicker`'s EyeDropper helper.
///
/// Native targets (iOS, Android, macOS, Windows, Linux) and SSR /
/// test environments don't have access to a screen-pixel sampler,
/// so [isEyeDropperSupported] is `false` and
/// [pickColorWithEyeDropper] always resolves to `null`. The picker's
/// action row hides the EyeDropper button when the helper reports
/// unsupported, so callers don't need to gate manually.
library;

/// Whether the host runtime exposes a native screen-color picker.
bool get isEyeDropperSupported => false;

/// Opens the host runtime's native EyeDropper picker. The stub
/// resolves to `null` immediately because non-web targets have no
/// such API. Signature must mirror the web implementation in
/// `co_color_picker_eyedropper_web.dart` so the conditional export
/// resolves to a single shape at every call site.
Future<String?> pickColorWithEyeDropper() => .value();
