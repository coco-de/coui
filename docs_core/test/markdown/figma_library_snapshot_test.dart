@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

// Agreement between two documented links is insufficient: they can agree on
// an invented or retired page id. Compare to the existing plugin capture rather
// than creating another slug/node registry or requiring a network credential.
void main() {
  group('Figma page provenance regression fixtures', () {
    const mapping = <String, Map<String, dynamic>>{
      'button': {'name': '❖ Button', 'nodeId': '12-34'},
    };

    test('accepts a page id and name from the same library capture', () {
      expect(_mappingIssues(mapping, 'library', _snapshot()), isEmpty);
    });

    test('rejects a capture from another Figma file', () {
      expect(
        _mappingIssues(mapping, 'other-library', _snapshot()),
        contains('snapshot fileKey does not match the canonical library'),
      );
    });

    test('rejects a retired page even when the id has valid syntax', () {
      final snapshot = _snapshot()..['pages'] = <Map<String, dynamic>>[];
      expect(
        _mappingIssues(mapping, 'library', snapshot),
        contains('button: page 12-34 is absent from the structure capture'),
      );
    });

    test('rejects an id belonging to a different component page', () {
      final snapshot = _snapshot();
      (snapshot['pages'] as List<Map<String, dynamic>>).single['name'] = '❖ Card';
      expect(
        _mappingIssues(mapping, 'library', snapshot),
        contains('button: page 12-34 is ❖ Card, not ❖ Button'),
      );
    });

    test('a file-only link needs no invented page id', () {
      expect(
        _mappingIssues(
          const {
            'button': {'name': '❖ Button'},
          },
          'library',
          _snapshot(),
        ),
        isEmpty,
      );
    });
  });

  test('Anatomy page ids come from the canonical library structure capture', () {
    final libraryFile = File('content/_data/figma_library.json');
    final snapshotFile = File(
      '../tools/figma-token-sync/reverse/baseline.structure.json',
    );
    expect(libraryFile.existsSync(), isTrue);
    expect(snapshotFile.existsSync(), isTrue);
    final library = jsonDecode(libraryFile.readAsStringSync()) as Map<String, dynamic>;
    final snapshot = jsonDecode(snapshotFile.readAsStringSync()) as Map<String, dynamic>;
    final url = Uri.parse(library['url'] as String);
    final mapping = (library['pages'] as Map<String, dynamic>).map(
      (slug, page) => MapEntry(slug, page as Map<String, dynamic>),
    );
    expect(mapping, isNotEmpty);
    expect(url.pathSegments.first, 'design');
    expect(snapshot['capturedBy'], 'figma-plugin:structure-snapshot');
    expect(DateTime.tryParse(snapshot['capturedAt'] as String), isNotNull);
    final issues = _mappingIssues(mapping, url.pathSegments[1], snapshot);
    expect(issues, isEmpty, reason: issues.join('\n'));
  });
}

Map<String, dynamic> _snapshot() => {
  'fileKey': 'library',
  'pages': <Map<String, dynamic>>[
    {'id': '12:34', 'name': '❖ Button'},
  ],
};

List<String> _mappingIssues(
  Map<String, Map<String, dynamic>> mapping,
  String fileKey,
  Map<String, dynamic> snapshot,
) {
  final issues = <String>[];
  if (snapshot['fileKey'] != fileKey) {
    issues.add('snapshot fileKey does not match the canonical library');
  }
  final pages = <String, String>{
    for (final page in snapshot['pages'] as List<dynamic>)
      (page['id'] as String).replaceAll(':', '-'): page['name'] as String,
  };
  for (final entry in mapping.entries) {
    final id = entry.value['nodeId'] as String?;
    if (id == null) continue;
    final capturedName = pages[id];
    if (capturedName == null) {
      issues.add('${entry.key}: page $id is absent from the structure capture');
    } else if (capturedName != entry.value['name']) {
      issues.add(
        '${entry.key}: page $id is $capturedName, not ${entry.value['name']}',
      );
    }
  }
  return issues;
}
