/// Web implementation of full-page navigation.
///
/// Selected via the conditional export in `web_navigation.dart` for
/// browser builds — kept out of the SSR path so the server compile target
/// never resolves `package:web`.
library;

import 'package:web/web.dart' as web;

/// Navigates the whole page to [path] via `window.location.assign`.
void navigateToPath(String path) => web.window.location.assign(path);
