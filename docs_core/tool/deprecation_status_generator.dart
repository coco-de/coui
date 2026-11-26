/// `component_deprecation_status.g.dart` 를 계산·직렬화하는 순수 로직.
///
/// `dart:io` 를 쓰므로 `lib/` 가 아니라 `tool/` 에 산다 — docs_app(Flutter
/// 앱)이 `component_catalog.dart` 를 통해 이 파일을 실수로 끌어들이는 일이
/// 없다. `docs_core/test/registry/deprecation_status_sync_test.dart` 가 같은
/// 함수를 다시 호출해 커밋된 생성 파일과 대조한다 — 그래서 이 파일은
/// `computeDeprecationStatus` 를 (쓰기가 아니라) 순수 계산으로 분리해 둔다.
library;

import 'dart:io';

import 'package:docs_core/shared/component_catalog.dart';

/// 슬러그에 해당하는 위젯 파일 — `docs_api_sync_test.dart` 의 `widgetFile()`
/// 와 같은 규칙(카테고리 폴더 아래 `<component>/<component>.dart`).
File? _widgetFile(Directory base, String slug) {
  final component = slug.replaceAll('-', '_');
  if (!base.existsSync()) return null;
  for (final category in base.listSync().whereType<Directory>()) {
    final candidate = File('${category.path}/$component/$component.dart');
    if (candidate.existsSync()) return candidate;
  }
  return null;
}

/// `text-field` → `TextField` 처럼 슬러그를 위젯 클래스명으로.
String classNameForSlug(String slug) =>
    slug.split('-').map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1)).join();

/// 카탈로그 전 슬러그에 대해 Flutter/Web 위젯 소스를 스캔해 deprecation
/// 상태를 계산한다.
///
/// 디렉터리는 호출자가 넘긴다 — 이 함수 자체는 어느 경로가 진짜인지 모른다
/// (생성기와 drift 테스트가 서로 다른 CWD 에서 돌아도 같은 계산을 하도록).
/// Flutter 에서 못 찾으면 Web 을 본다 — 컴포넌트가 한쪽에만 있을 수 있다.
Map<String, DocsDeprecationStatus> computeDeprecationStatus({
  required Directory flutterComponentsDir,
  required Directory webComponentsDir,
}) {
  final entries = kDocsComponentEntries;
  final slugByName = {for (final e in entries) e.name: e.slug};
  final result = <String, DocsDeprecationStatus>{};

  for (final entry in entries) {
    final className = classNameForSlug(entry.slug);
    DocsDeprecationStatus? parsed;
    for (final base in [flutterComponentsDir, webComponentsDir]) {
      final file = _widgetFile(base, entry.slug);
      if (file == null) continue;
      parsed = parseClassDeprecation(file.readAsStringSync(), className);
      if (parsed != null) break;
    }
    if (parsed == null) continue;

    final replacementSlug = parsed.replacementName == null ? null : slugByName[parsed.replacementName];
    result[entry.slug] = DocsDeprecationStatus(
      since: parsed.since,
      message: parsed.message,
      replacementName: parsed.replacementName,
      replacementSlug: replacementSlug,
    );
  }
  return result;
}

/// 계산된 맵을 커밋 가능한 Dart 파일 소스로 직렬화한다.
String renderGeneratedFile(Map<String, DocsDeprecationStatus> status) {
  final buffer = StringBuffer()
    ..writeln('// GENERATED FILE — DO NOT EDIT BY HAND.')
    ..writeln('//')
    ..writeln('// `cd docs_core && dart run tool/gen_deprecation_status.dart` 로')
    ..writeln('// 재생성한다. `packages/coui_{flutter,web}/lib/src/components/**/*.dart`')
    ..writeln('// 의 클래스-레벨 `@Deprecated(...)` 를 스캔한 결과다 — 손으로 고치지')
    ..writeln('// 않는다. `test/registry/deprecation_status_sync_test.dart` 가 이 파일이')
    ..writeln('// 소스와 어긋나지 않는지 게이트한다.')
    ..writeln('library;')
    ..writeln()
    ..writeln("import 'component_deprecation.dart';")
    ..writeln()
    ..writeln('/// 슬러그 → 파싱된 deprecation 상태. 소스에 클래스-레벨')
    ..writeln('/// `@Deprecated` 가 없는 컴포넌트는 이 맵에 없다(= active).')
    ..writeln('const Map<String, DocsDeprecationStatus> kDocsDeprecationStatus = {');
  final slugs = status.keys.toList()..sort();
  for (final slug in slugs) {
    final s = status[slug]!;
    buffer
      ..writeln("  '$slug': DocsDeprecationStatus(")
      ..writeln("    since: '${s.since}',")
      ..writeln('    message: ${_dartStringLiteral(s.message)},')
      ..writeln(
        '    replacementSlug: '
        '${s.replacementSlug == null ? 'null' : "'${s.replacementSlug}'"},',
      )
      ..writeln(
        '    replacementName: '
        '${s.replacementName == null ? 'null' : "'${s.replacementName}'"},',
      )
      ..writeln('  ),');
  }
  buffer.writeln('};');
  return buffer.toString();
}

String _dartStringLiteral(String value) {
  final escaped = value.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll('\n', r'\n').replaceAll(r'$', r'\$');
  return "'$escaped'";
}
