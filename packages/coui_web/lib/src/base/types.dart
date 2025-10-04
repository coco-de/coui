/// Common type definitions for coui_web.
///
/// Re-exports commonly used types from dependencies and defines custom callbacks.
library;

export 'package:jaspr/jaspr.dart' show VoidCallback;

/// Callback signature for boolean state change events.
typedef BoolStateCallback = void Function({required bool state});
