@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// Holds the canonical Figma library URL in the one JSON file the exporter
/// and the figma-library guide both read. A null URL ships as an empty
/// table cell and the plugin has nothing to show consumers.
///
/// `pages` is the slug → Figma page (`❖ Name`) map Anatomy links read.
/// Node ids are hyphen form, taken from the reverse structure snapshot —
/// invented ids are a consumer-facing lie, so this file gates the shape.
void main() {
  final file = File('content/_data/figma_library.json');
  late Map<String, dynamic> data;
  late String libraryUrl;
  late Map<String, Map<String, dynamic>> pages;

  setUpAll(() {
    expect(file.existsSync(), isTrue);
    data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    libraryUrl = data['url'] as String;
    final raw = data['pages'];
    pages = raw is Map
        ? raw.map(
            (key, value) => MapEntry(
              key as String,
              Map<String, dynamic>.from(value as Map),
            ),
          )
        : <String, Map<String, dynamic>>{};
  });

  test('canonical Figma library URL is wired', () {
    expect(libraryUrl, isNotEmpty);
    expect(
      libraryUrl,
      startsWith('https://www.figma.com/design/'),
      reason: 'consumers need a file they can open, not a placeholder',
    );
    expect(data['identifier'], 'coui-component-library');
  });

  test('pages 맵의 nodeId 는 hyphen 형식이고 페이지 이름을 가진다', () {
    expect(pages, isNotEmpty, reason: 'Anatomy 가 읽을 slug → 페이지 맵이 없다');
    final hyphenId = RegExp(r'^\d+-\d+$');
    final offenders = <String>[];
    for (final entry in pages.entries) {
      final slug = entry.key;
      final name = entry.value['name'];
      final nodeId = entry.value['nodeId'];
      if (name is! String || !name.startsWith('❖ ')) {
        offenders.add('$slug: name 은 "❖ …" 페이지 이름이어야 함 (got $name)');
      }
      if (nodeId != null && (nodeId is! String || !hyphenId.hasMatch(nodeId))) {
        offenders.add(
          '$slug: nodeId 는 hyphen 형식(`2467-96798`)이어야 함 — '
          'colon 이나 빈 값은 가짜 id (got $nodeId)',
        );
      }
      if (nodeId is String && nodeId.contains(':')) {
        offenders.add('$slug: nodeId 에 colon 이 있다 — Figma URL 은 hyphen');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n  '));
  });

  test('pages 맵 슬러그의 문서에 Anatomy 가 있고 node-id 가 맵과 같다', () {
    final offenders = <String>[];
    for (final entry in pages.entries) {
      final slug = entry.key;
      final page = File('content/components/$slug.md');
      if (!page.existsSync()) {
        offenders.add('$slug: pages 맵에 있는데 content/components/$slug.md 가 없다');
        continue;
      }
      final source = page.readAsStringSync();
      // A v2 page shows its anatomy with the `<Anatomy>` block, and the page
      // head links Figma from this same map (`manual_layout.dart`
      // `_headMeta`) — so the page carries no node-id of its own, and any it
      // does carry has to be the mapped one.
      if (RegExp(r'^template:\s*v2\s*$', multiLine: true).hasMatch(source)) {
        if (!source.contains('<Anatomy')) {
          offenders.add('$slug: v2 페이지인데 <Anatomy> 블록이 없다');
        }
        final mappedId = entry.value['nodeId'] as String?;
        final stray = _nodeIdsIn(source).where((id) => id != mappedId).toList();
        if (stray.isNotEmpty) {
          offenders.add('$slug: 맵에 없는 node-id ${stray.join(",")}');
        }
        continue;
      }
      if (!source.contains('## 구조 (Anatomy)')) {
        offenders.add('$slug: pages 맵에 있는데 Anatomy 섹션이 없다');
        continue;
      }
      final section = _anatomySection(source);
      if (section == null) {
        offenders.add('$slug: Anatomy 섹션을 자를 수 없다');
        continue;
      }
      if (!RegExp(r'\|\s*부분\s*\|\s*역할\s*\|\s*슬롯\s*\|').hasMatch(section)) {
        offenders.add('$slug: Anatomy 표 헤더가 `부분 | 역할 | 슬롯` 이 아니다');
      }
      if (section.contains('_Docs /')) {
        offenders.add('$slug: `_Docs /` 프레임을 링크했다 — 안정 id 가 없다');
      }

      final mappedId = entry.value['nodeId'] as String?;
      final ids = _nodeIdsIn(section);
      if (mappedId == null || mappedId.isEmpty) {
        if (ids.isNotEmpty) {
          offenders.add(
            '$slug: 맵에 nodeId 가 없는데 Anatomy 가 node-id=${ids.join(",")} '
            '를 적었다 — 가짜 id',
          );
        }
        if (!section.contains(libraryUrl)) {
          offenders.add('$slug: nodeId 없는 항목은 파일 URL 로만 링크해야 한다');
        }
      } else {
        if (!ids.contains(mappedId)) {
          offenders.add(
            '$slug: Anatomy node-id 가 맵($mappedId)과 다르다 '
            '(found ${ids.isEmpty ? "없음" : ids.join(",")})',
          );
        }
        final extra = ids.where((id) => id != mappedId).toList();
        if (extra.isNotEmpty) {
          offenders.add('$slug: 맵에 없는 node-id ${extra.join(",")}');
        }
        if (!section.contains('$libraryUrl?node-id=$mappedId')) {
          offenders.add('$slug: Anatomy 링크가 library url + 맵 node-id 가 아니다');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n  '));
  });

  test('Anatomy 섹션은 Live Preview 뒤 · 사용 시기 앞에 있다', () {
    final offenders = <String>[];
    final dir = Directory('content/components');
    for (final page in dir.listSync().whereType<File>()) {
      if (!page.path.endsWith('.md')) continue;
      final slug = page.uri.pathSegments.last.replaceAll('.md', '');
      final lines = page.readAsLinesSync();
      var live = -1;
      var anatomy = -1;
      var when = -1;
      for (var i = 0; i < lines.length; i++) {
        if (lines[i] == '## Live Preview') live = i;
        if (lines[i] == '## 구조 (Anatomy)') anatomy = i;
        if (RegExp(r'^## (사용 시기|When to Use)').hasMatch(lines[i])) {
          when = i;
        }
      }
      if (anatomy < 0) continue;
      if (live < 0 || anatomy < live) {
        offenders.add('$slug: Anatomy 가 Live Preview 뒤에 있어야 함');
      }
      if (when < 0 || anatomy > when) {
        offenders.add('$slug: Anatomy 가 사용 시기 앞에 있어야 함');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n  '));
  });

  test('Anatomy 의 node-id 는 pages 맵에 있는 것만', () {
    final offenders = <String>[];
    final dir = Directory('content/components');
    for (final page in dir.listSync().whereType<File>()) {
      if (!page.path.endsWith('.md')) continue;
      final slug = page.uri.pathSegments.last.replaceAll('.md', '');
      final source = page.readAsStringSync();
      if (!source.contains('## 구조 (Anatomy)')) continue;
      final section = _anatomySection(source);
      if (section == null) continue;
      final ids = _nodeIdsIn(section);
      final mapped = pages[slug]?['nodeId'] as String?;
      for (final id in ids) {
        if (id != mapped) {
          offenders.add('$slug: Anatomy node-id=$id 는 pages 맵에 없음');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n  '));
  });
}

String? _anatomySection(String source) {
  final start = source.indexOf('## 구조 (Anatomy)');
  if (start < 0) return null;
  final rest = source.substring(start);
  final next = RegExp(r'\n## ', multiLine: true).firstMatch(rest.substring(1));
  if (next == null) return rest;
  return rest.substring(0, next.start + 1);
}

List<String> _nodeIdsIn(String markdown) {
  return [
    for (final match in RegExp(r'[?&]node-id=([0-9]+-[0-9]+)').allMatches(markdown)) match.group(1)!,
  ];
}
