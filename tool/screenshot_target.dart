/// Which docs_site page `tool/screenshot.dart` points at, and where the PNG
/// lands — kept apart from the browser code so the rules can be tested
/// without launching Chrome.
///
/// A capture names its page one of two ways:
///
/// - a component slug (`button`) → `<base>/components/button`, the shape
///   every per-component caller has always used;
/// - a site path (`/`, `/components-overview`) → `<base><path>`, for pages
///   that are not a component — the landing and the gallery, whose
///   surface-preset reach is the thing a nightly capture has to record.
library;

/// The two ways a capture can name its page. Exactly one is set.
typedef ScreenshotPage = ({String? component, String? path});

/// Why [page] cannot be captured, or `null` when it can — a page must name
/// exactly one of a component slug or a site path, and a path must start
/// at the site root.
///
/// The leading `/` is required rather than added: `components-overview`
/// without it reads as a component slug to anyone skimming a workflow
/// file, and silently prefixing it would make the two spellings mean the
/// same thing in one place and different things in another.
String? screenshotPageProblem(ScreenshotPage page) {
  final (:component, :path) = page;
  if ((component == null) == (path == null)) {
    return 'Give exactly one of a component slug or --path=<site path>.';
  }
  if (path != null && !path.startsWith('/')) {
    return '--path must start with "/" (e.g. "/" or "/components-overview"), '
        'got "$path".';
  }

  return null;
}

/// Throws [ArgumentError] carrying [screenshotPageProblem]'s message.
void validateScreenshotPage(ScreenshotPage page) {
  final problem = screenshotPageProblem(page);
  if (problem != null) throw ArgumentError(problem);
}

/// The URL the browser navigates to.
String screenshotUrl(ScreenshotPage page, {required String baseUrl}) {
  validateScreenshotPage(page);
  final base = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  final (:component, :path) = page;

  return component != null ? '$base/components/$component' : '$base$path';
}

/// A filename-safe name for the page — the component slug as-is, or the
/// path with its slashes folded to `-`. The site root has no segments, so
/// it is named `index`, the file the server actually answers it with.
String screenshotLabel(ScreenshotPage page) {
  validateScreenshotPage(page);
  final (:component, :path) = page;
  if (component != null) return component;

  final segments = path!
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .join('-');

  return segments.isEmpty
      ? 'index'
      : segments.replaceAll(RegExp('[^A-Za-z0-9._-]'), '-');
}

/// Where one capture is written.
///
/// With a template, `{label}`, `{theme}` and `{style}` are substituted —
/// `{style}` becomes `default` when no surface style is set, because the
/// default style is the attribute being absent and a filename still needs
/// a word for it. Without one, the long-standing
/// `/tmp/<label>[-<style>]-<theme>.png` default.
String screenshotOutPath({
  required String label,
  required String theme,
  String? surfaceStyle,
  String? template,
}) {
  if (template != null) {
    return template
        .replaceAll('{label}', label)
        .replaceAll('{theme}', theme)
        .replaceAll('{style}', surfaceStyle ?? 'default');
  }
  final suffix = surfaceStyle == null ? '' : '-$surfaceStyle';

  return '/tmp/$label$suffix-$theme.png';
}
