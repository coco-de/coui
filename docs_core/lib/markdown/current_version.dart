/// Pure parsing of a package's `version:` field out of its `pubspec.yaml`.
///
/// Docs must never hardcode a version number in prose — every package here
/// bumps on nearly every merge (`release-please`, minor-bump-pre-major), so
/// a literal `^0.0.1` or `0.12x.x` written by hand is stale before the next
/// release lands. `<CurrentVersion package="coui_flutter" />` reads the
/// live `pubspec.yaml` at doc-build time instead, so the number is always
/// exactly what a fresh checkout resolves to.
library;

/// Matches the top-level `version:` key. Deliberately anchored at the
/// start of a line (not inside a nested map) — pubspec.yaml's own
/// `version:` is always top-level, and a naive substring match could catch
/// an unrelated `version:` under `environment:`/`dependencies:` if one
/// were ever added there.
final _versionPattern = RegExp(r'^version:\s*(\S+)\s*$', multiLine: true);

/// Returns the `version:` value from a `pubspec.yaml` source string, or
/// `null` if the key is missing or malformed (a package can then choose
/// to render a fallback rather than throw the whole page).
String? parsePubspecVersion(String pubspecYamlSource) {
  return _versionPattern.firstMatch(pubspecYamlSource)?.group(1);
}

/// Builds the `release-please` git tag for a package release —
/// `{component}-v{version}` — matching `include-component-in-tag: true` in
/// `release-please-config.json`. This is the exact `ref:` value a consumer
/// should pin a git dependency to.
String releaseTag(String package, String version) => '$package-v$version';

/// What a `<CurrentVersion>` tag shows — the value, or a one-line notice
/// when it cannot be shown.
///
/// Both documentation surfaces (the Jaspr site and the native app) render
/// this value. Only *reading* the pubspec differs between them (a file on
/// disk vs a bundled asset); what the tag says once the source is in hand is
/// decided here, so the two cannot disagree on a version or on how a failure
/// reads.
sealed class CurrentVersionView {
  const CurrentVersionView();
}

/// The version (`0.128.1`) or its release tag (`coui_flutter-v0.128.1`).
final class CurrentVersionText extends CurrentVersionView {
  const CurrentVersionText(this.text);

  final String text;
}

/// Why nothing can be shown — rendered in place of the value, so a renamed
/// package degrades the page instead of breaking it.
final class CurrentVersionNotice extends CurrentVersionView {
  const CurrentVersionNotice(this.message);

  final String message;
}

/// The `package` attribute, or `null` when it is missing or empty.
String? currentVersionPackage(Map<String, String> attributes) {
  final package = attributes['package'];
  return package == null || package.isEmpty ? null : package;
}

/// Shown when the tag has no `package` attribute.
const kCurrentVersionMissingPackageNotice = CurrentVersionNotice(
  '<CurrentVersion> is missing a required `package` attribute.',
);

/// Shown when the package's pubspec could not be read.
CurrentVersionNotice currentVersionUnreadableNotice(String package, Object error) =>
    CurrentVersionNotice('Could not read $package/pubspec.yaml ($error).');

/// Decides what `<CurrentVersion>` shows once the pubspec source is in hand.
///
/// `tag="true"` switches the value from the bare version to the release tag.
CurrentVersionView currentVersionView({
  required String package,
  required Map<String, String> attributes,
  required String pubspecSource,
}) {
  final version = parsePubspecVersion(pubspecSource);
  if (version == null) {
    return CurrentVersionNotice('$package/pubspec.yaml has no `version:` key.');
  }
  final asTag = attributes['tag']?.toLowerCase() == 'true';
  return CurrentVersionText(asTag ? releaseTag(package, version) : version);
}
