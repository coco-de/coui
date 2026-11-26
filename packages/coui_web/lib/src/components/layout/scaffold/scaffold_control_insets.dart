/// Browser-only safe-area observation; SSR keeps the horizontal layout.
library;

export 'scaffold_control_insets_stub.dart'
    if (dart.library.js_interop) 'scaffold_control_insets_web.dart';
