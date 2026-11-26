/// Conditional barrel that selects the IO or the web reading of a picked
/// directory.
///
/// `dir_picker` answers `pick()` on every platform, but what comes back
/// differs: native hands over a `file://` (or Android `content://`) URI per
/// entry, while web hands over a `FileSystemDirectoryHandle` whose files
/// have to be read through the File System Access API. Keeping the two
/// apart here means the widget never imports `dart:js_interop` — which the
/// VM has no library for.
library;

export 'file_input_directory_io.dart'
    if (dart.library.js_interop) 'file_input_directory_web.dart';
