import 'dart:io';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart' show CustomComponentBase;

import 'current_version.dart';
import 'repo_root.dart';

/// `<CurrentVersion package="coui_flutter" />` — inline, build-time-read
/// version number (`0.128.1`), and `<CurrentVersion package="coui_flutter"
/// tag="true" />` — the matching git tag (`coui_flutter-v0.128.1`), the
/// exact `ref:` value for a pinned git dependency.
///
/// Exists so prose never spells out a version literal by hand — every
/// package here bumps on nearly every merge, so a hand-typed number is
/// wrong by the next release. `docs_api_sync_test.dart`'s "문서가 존재하지
/// 않는 Core 심볼을 참조한다" gate closes the same class of drift for API
/// symbols; this closes it for version numbers.
class CurrentVersion extends CustomComponentBase {
  @override
  Pattern get pattern => 'CurrentVersion';

  @override
  Component apply(String name, Map<String, String> attributes, Component? child) {
    // What the tag says is decided by `currentVersionView` — the native app
    // reads the same function, so the two surfaces cannot show different
    // versions. Only the file read below is Web's own.
    final package = currentVersionPackage(attributes);
    if (package == null) return _render(kCurrentVersionMissingPackageNotice);

    final String source;
    try {
      final root = findRepoRoot();
      final file = File('${root.path}/packages/$package/pubspec.yaml');
      source = file.readAsStringSync();
    } on Object catch (e) {
      return _render(currentVersionUnreadableNotice(package, e));
    }

    return _render(
      currentVersionView(package: package, attributes: attributes, pubspecSource: source),
    );
  }

  Component _render(CurrentVersionView view) => switch (view) {
    CurrentVersionNotice(:final message) => span(classes: 'current-version-error', [
      Component.text(message),
    ]),
    CurrentVersionText(:final text) => Component.element(
      tag: 'code',
      attributes: {'class': 'current-version'},
      children: [Component.text(text)],
    ),
  };
}
