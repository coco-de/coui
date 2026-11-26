/// Conditional barrel that selects the SSR stub or the web implementation
/// of `PaginationFitMeasurer` based on the presence of `dart:js_interop`.
///
/// Keeps every `package:web` / DOM import isolated to
/// `pagination_fit_measurer_web.dart` so `pagination.dart` stays SSR-safe.
library;

export 'pagination_fit_measurer_stub.dart'
    if (dart.library.js_interop) 'pagination_fit_measurer_web.dart';
