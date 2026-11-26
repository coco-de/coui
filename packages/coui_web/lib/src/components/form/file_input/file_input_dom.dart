/// Conditional barrel that selects the SSR stub or the web implementation
/// of `FileInput`'s drop collection.
///
/// Keeps every `dart:js_interop` / `package:web` import isolated to
/// `file_input_dom_web.dart` so `file_input.dart` stays SSR-safe — the VM
/// has no `dart:js_interop`, and importing it from a file the whole
/// `coui_web` barrel pulls in breaks every VM test in the package.
library;

export 'file_input_dom_stub.dart'
    if (dart.library.js_interop) 'file_input_dom_web.dart';
