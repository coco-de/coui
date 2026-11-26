/// The names the site's brightness is kept under — shared by the server
/// markup, the pre-paint script and the browser code.
library;

/// The document attribute the stylesheet keys off (`light` / `dark`).
const String kSiteThemeAttribute = 'data-theme';

/// The storage key the reader's choice is remembered under.
const String kSiteThemeStorageKey = 'jaspr:theme';

/// The class of the header's brightness control.
const String kSiteThemeToggleClass = 'theme-toggle';
