@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/markdown/versions.dart';
import 'package:test/test.dart';

void main() {
  group('parseVersionManifest', () {
    test('parses a well-formed manifest', () {
      const source = '''
{
  "versions": [
    {"tag": "coui_flutter-v0.128.1", "label": "0.128.1", "date": "2026-07-25"},
    {"tag": "coui_flutter-v0.127.16", "label": "0.127.16", "date": "2026-07-21"}
  ]
}
''';
      final versions = parseVersionManifest(source);
      expect(versions, hasLength(2));
      expect(versions.first.tag, 'coui_flutter-v0.128.1');
      expect(versions.first.label, '0.128.1');
      expect(versions.first.date, '2026-07-25');
    });

    test('an empty versions list parses to an empty list, not an error', () {
      expect(parseVersionManifest('{"versions": []}'), isEmpty);
    });

    test('throws FormatException on malformed JSON', () {
      expect(() => parseVersionManifest('not json'), throwsFormatException);
    });

    test('throws FormatException when the versions key is missing', () {
      expect(() => parseVersionManifest('{}'), throwsFormatException);
    });

    test('throws FormatException when versions is not a list', () {
      expect(() => parseVersionManifest('{"versions": "nope"}'), throwsFormatException);
    });
  });

  group('renderVersionManifest', () {
    test('round-trips through parseVersionManifest', () {
      const original = [
        VersionSnapshot(tag: 'coui_flutter-v0.128.1', label: '0.128.1', date: '2026-07-25'),
      ];
      final rendered = renderVersionManifest(original);
      expect(parseVersionManifest(rendered), original);
    });

    test('renders a trailing newline (clean git diffs)', () {
      expect(renderVersionManifest(const []), endsWith('}\n'));
    });
  });

  group('sortedNewestFirst', () {
    test('orders by date descending', () {
      const a = VersionSnapshot(tag: 'a', label: 'a', date: '2026-01-01');
      const b = VersionSnapshot(tag: 'b', label: 'b', date: '2026-06-01');
      expect(sortedNewestFirst([a, b]), [b, a]);
    });

    test('breaks same-date ties by tag descending, deterministically', () {
      const a = VersionSnapshot(tag: 'coui_flutter-v0.100.0', label: 'x', date: '2026-01-01');
      const b = VersionSnapshot(tag: 'coui_flutter-v0.99.0', label: 'y', date: '2026-01-01');
      final once = sortedNewestFirst([a, b]);
      final twice = sortedNewestFirst([b, a]);
      expect(once, twice);
    });
  });

  group('withSnapshot', () {
    test('appends a new tag', () {
      const existing = [VersionSnapshot(tag: 'a', label: 'a', date: '2026-01-01')];
      const added = VersionSnapshot(tag: 'b', label: 'b', date: '2026-06-01');
      final result = withSnapshot(existing, added);
      expect(result.map((v) => v.tag), ['b', 'a']);
    });

    test('re-archiving the same tag replaces, does not duplicate', () {
      const existing = [VersionSnapshot(tag: 'a', label: 'a-old', date: '2026-01-01')];
      const reArchived = VersionSnapshot(tag: 'a', label: 'a-new', date: '2026-02-01');
      final result = withSnapshot(existing, reArchived);
      expect(result, hasLength(1));
      expect(result.single.label, 'a-new');
    });
  });

  test('the committed docs_core/content/_data/versions.json parses cleanly', () {
    final file = File('content/_data/versions.json');
    expect(file.existsSync(), isTrue);
    expect(() => parseVersionManifest(file.readAsStringSync()), returnsNormally);
  });
}
