/// Conditional barrel that selects the SSR stub or the web implementation
/// of `BottomSheetMeasurer` based on the presence of `dart:js_interop`.
///
/// Keeps every `package:web` / DOM import isolated to
/// `bottom_sheet_measurer_web.dart` so `bottom_sheet.dart` stays SSR-safe.
library;

export 'bottom_sheet_measurer_stub.dart'
    if (dart.library.js_interop) 'bottom_sheet_measurer_web.dart';
