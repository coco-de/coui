/// Server stub — there is no document to read while pre-rendering.
library;

export 'site_theme_names.dart';

/// Whether the document is in dark mode — never, on the server.
bool readDarkTheme() => false;

/// Remembers the brightness choice — a no-op on the server.
void rememberSiteTheme({required bool dark}) {}

/// Flips the site's brightness — a no-op on the server.
void toggleSiteTheme() {}

/// Whether the OS asks for the media [feature] — never, on the server.
bool matchesMediaFeature(String feature) => false;

/// Applies or lifts the page's preview of [feature] — a no-op on the server.
void previewMediaFeature(String feature, {required bool enabled}) {}

/// Calls [onChange] when the document's brightness changes. Returns the
/// function that stops listening.
void Function() observeTheme(void Function() onChange) => () {};

/// Calls [onChange] when the OS turns [feature] on or off. Returns the
/// function that stops listening.
void Function() observeMediaFeature(String feature, void Function() onChange) => () {};
