/// Conditional-export barrel for the `RichEditor`'s DOM bridge.
///
/// SSR / non-`dart:js_interop` builds get the inert
/// `rich_editor_dom_stub.dart`; browser builds get `rich_editor_dom_web.dart`,
/// which edits the `contenteditable` surface through `package:web`.
library;

export 'rich_editor_dom_stub.dart'
    if (dart.library.js_interop) 'rich_editor_dom_web.dart';
