/// Browser implementation — reached only through `site_theme_dom.dart`.
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'site_theme_names.dart';

export 'site_theme_names.dart';

const String _kDark = 'dark';
const String _kLight = 'light';

/// The mark on the sheet a preview writes, so it can be found and removed.
const String _kPreviewAttribute = 'data-site-preview';

/// Whether the document is in dark mode.
bool readDarkTheme() => web.document.documentElement?.getAttribute(kSiteThemeAttribute) == _kDark;

/// Remembers the reader's brightness choice across pages.
///
/// The attribute is not written here. The header toggle declares it on the
/// document (`SiteThemeToggle`), and a value written behind that declaration
/// is undone the next time any island rebuilds — see [toggleSiteTheme].
void rememberSiteTheme({required bool dark}) {
  try {
    web.window.localStorage.setItem(kSiteThemeStorageKey, dark ? _kDark : _kLight);
  } on Object {
    // Storage can be blocked (third-party contexts). The page still
    // changes; the choice just does not outlive it.
  }
}

/// Flips the site's brightness through the control that owns it.
///
/// The header toggle keeps the brightness in its own state and declares the
/// document attribute from it. Every declaration on `<html>` is reconciled
/// together: when any island rebuilds, an attribute nobody declares goes back
/// to the value it had when the page started. So writing the attribute behind
/// the toggle's back does not last — the page flips and then flips back the
/// moment something else redraws. This presses the toggle instead of doing
/// the toggle's job.
///
/// Until the toggle has hydrated it cannot be pressed: the server renders it
/// hidden and a click reaches no handler. In that window the attribute is
/// written directly, which is safe — nothing has declared it yet, and the
/// toggle reads the attribute when it hydrates, so it starts from whatever
/// was written.
void toggleSiteTheme() {
  final toggle = web.document.querySelector('.$kSiteThemeToggleClass') as web.HTMLElement?;
  if (toggle != null && toggle.style.visibility != 'hidden') {
    toggle.click();
    return;
  }

  final dark = !readDarkTheme();
  web.document.documentElement?.setAttribute(kSiteThemeAttribute, dark ? _kDark : _kLight);
  rememberSiteTheme(dark: dark);
}

/// Whether the OS asks for the media [feature] (`prefers-contrast: more`).
bool matchesMediaFeature(String feature) => web.window.matchMedia('($feature)').matches;

/// Applies or lifts this page's preview of the media [feature].
///
/// The kit answers `prefers-contrast` and `prefers-reduced-motion` with
/// rules inside `@media` blocks, and a page cannot make a media query match.
/// So the preview copies every rule that sits under the feature into a sheet
/// of its own, where it applies unconditionally. Nothing is restated: the
/// rules the preview shows are the rules the OS setting would switch on.
///
/// What it does not reach is code that asks the browser directly
/// (`matchMedia`) — a script that reads the OS setting still sees the OS
/// setting.
void previewMediaFeature(String feature, {required bool enabled}) {
  web.document.querySelector('style[$_kPreviewAttribute="$feature"]')?.remove();
  if (!enabled) return;

  final rules = StringBuffer();
  final sheets = web.document.styleSheets;
  for (var index = 0; index < sheets.length; index++) {
    final sheet = sheets.item(index);
    if (sheet == null) continue;
    try {
      _collect(sheet.cssRules, _compact(feature), rules);
    } on Object {
      // A sheet from another origin refuses to show its rules. It is not
      // the kit's, so there is nothing of the kit's to copy from it.
    }
  }

  final sheet = web.document.createElement('style')
    ..setAttribute(_kPreviewAttribute, feature)
    ..textContent = rules.toString();
  web.document.head?.append(sheet);
}

/// Writes every rule under a `@media` block that names [feature] to [out].
void _collect(web.CSSRuleList rules, String feature, StringBuffer out) {
  for (var index = 0; index < rules.length; index++) {
    final rule = rules.item(index);
    if (rule == null || !rule.isA<web.CSSGroupingRule>()) continue;

    final group = rule as web.CSSGroupingRule;
    final names =
        rule.isA<web.CSSMediaRule>() && _compact((rule as web.CSSMediaRule).media.mediaText).contains(feature);
    if (!names) {
      _collect(group.cssRules, feature, out);
      continue;
    }

    final inner = group.cssRules;
    for (var position = 0; position < inner.length; position++) {
      final text = inner.item(position)?.cssText;
      if (text != null) out.writeln(text);
    }
  }
}

/// A media condition with its spaces removed — browsers serialise
/// `(prefers-contrast:more)` as `(prefers-contrast: more)`.
String _compact(String text) => text.replaceAll(' ', '');

/// Calls [onChange] when the document's brightness changes. Returns the
/// function that stops listening.
void Function() observeTheme(void Function() onChange) {
  final root = web.document.documentElement;
  if (root == null) return () {};

  void handleMutation(JSArray<web.MutationRecord> records, web.MutationObserver observer) => onChange();

  final observer = web.MutationObserver(handleMutation.toJS)
    ..observe(
      root,
      web.MutationObserverInit(attributes: true, attributeFilter: [kSiteThemeAttribute.toJS].toJS),
    );

  // A closure, not `observer.disconnect`: the web compilers reject tearing
  // off an interop member.
  return () => observer.disconnect();
}

/// Calls [onChange] when the OS turns [feature] on or off. Returns the
/// function that stops listening.
void Function() observeMediaFeature(String feature, void Function() onChange) {
  final query = web.window.matchMedia('($feature)');

  void handleChange(web.Event event) => onChange();

  final listener = handleChange.toJS;
  query.addEventListener('change', listener);

  return () => query.removeEventListener('change', listener);
}
