/// Conditional barrel that selects the SSR stub or the web implementation
/// of `InputOtpScaleMeasurer` based on the presence of `dart:js_interop`.
///
/// Keeps every `package:web` / DOM import isolated to
/// `input_otp_scale_measurer_web.dart` so `input_otp.dart` stays SSR-safe
/// and free of direct DOM dependencies.
library;

export 'input_otp_scale_measurer_stub.dart'
    if (dart.library.js_interop) 'input_otp_scale_measurer_web.dart';
