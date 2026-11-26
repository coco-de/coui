/// Conditional barrel that selects the SSR stub or the web implementation
/// of `coui_web`'s file download.
///
/// Keeps every `dart:js_interop` / `package:web` import isolated to
/// `co_file_saver_dom_web.dart` so `co_file_saver.dart` stays SSR-safe —
/// the VM has no `dart:js_interop`.
library;

export 'co_file_saver_dom_stub.dart'
    if (dart.library.js_interop) 'co_file_saver_dom_web.dart';
