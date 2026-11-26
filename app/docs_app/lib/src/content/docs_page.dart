/// 파싱된 문서 페이지 — frontmatter + 마크다운 본문.
library;

import 'package:yaml/yaml.dart';

/// 마크다운 파일 하나: frontmatter 메타 + 본문.
class DocsPage {
  /// 페이지를 만든다.
  const DocsPage({
    required this.path,
    required this.body,
    this.title,
    this.description,
    this.category,
    this.platforms = const [],
    this.related = const [],
    this.tags = const [],
  });

  /// 이 페이지의 라우트 경로.
  final String path;

  /// Frontmatter `title` — 없으면 `null`.
  final String? title;

  /// Frontmatter `description` — 없으면 `null`.
  final String? description;

  /// Frontmatter `category` (컴포넌트 페이지에만) — 없으면 `null`.
  final String? category;

  /// Frontmatter `platforms` (예: `[flutter, web]`).
  final List<String> platforms;

  /// Frontmatter `related` — 관련 컴포넌트 슬러그.
  final List<String> related;

  /// Frontmatter `tags`.
  final List<String> tags;

  /// Frontmatter 를 뺀 마크다운 본문.
  final String body;
}

const _kFence = '---';

/// 원본 마크다운을 frontmatter 와 본문으로 파싱한다.
///
/// Frontmatter 는 선택이다 — 없으면 전체가 본문이고 메타는 `null`/빈 값이다.
/// Frontmatter 가 깨진 페이지 하나 때문에 앱 전체가 죽지 않도록, YAML 파싱
/// 실패는 메타 없음으로 저하시킨다.
DocsPage parseDocsPage({required String path, required String source}) {
  final normalized = source.replaceAll('\r\n', '\n');
  if (!normalized.startsWith('$_kFence\n')) {
    return DocsPage(path: path, body: normalized);
  }

  final end = normalized.indexOf('\n$_kFence', _kFence.length);
  if (end == -1) return DocsPage(path: path, body: normalized);

  final frontmatter = normalized.substring(_kFence.length + 1, end);
  final bodyStart = normalized.indexOf('\n', end + 1);
  final body = bodyStart == -1 ? '' : normalized.substring(bodyStart + 1);

  YamlMap? map;
  try {
    final parsed = loadYaml(frontmatter);
    if (parsed is YamlMap) map = parsed;
  } on Object {
    map = null;
  }
  if (map == null) return DocsPage(path: path, body: body);

  return DocsPage(
    path: path,
    body: body,
    title: _string(map['title']),
    description: _string(map['description']),
    category: _string(map['category']),
    platforms: _stringList(map['platforms']),
    related: _stringList(map['related']),
    tags: _stringList(map['tags']),
  );
}

String? _string(Object? value) => value == null ? null : '$value';

List<String> _stringList(Object? value) {
  if (value is YamlList) return [for (final v in value) '$v'];
  if (value is List) return [for (final v in value) '$v'];
  if (value == null) return const [];
  return ['$value'];
}
