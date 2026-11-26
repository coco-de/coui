@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/markdown/changelog.dart';
import 'package:test/test.dart';

const _fixture = '''
## [0.128.1](https://github.com/coco-de/coui/compare/coui_flutter-v0.128.0...coui_flutter-v0.128.1) (2026-07-25)


### 버그 수정

* **button:** 🐛 outline variant 설명 ([#3293](https://github.com/coco-de/coui/issues/3293)) ([feb46b2](https://github.com/coco-de/coui/commit/feb46b2))
* **resizable:** 🐛 direction 전환 버그 ([#3291](https://github.com/coco-de/coui/issues/3291)) ([47723c0](https://github.com/coco-de/coui/commit/47723c0))

## [0.128.0](https://github.com/coco-de/coui/compare/coui_flutter-v0.127.16...coui_flutter-v0.128.0) (2026-07-23)


### 기능

* **color:** ✨ ResolvedColorScheme 도입 ([#3282](https://github.com/coco-de/coui/issues/3282)) ([0bde409](https://github.com/coco-de/coui/commit/0bde409))

## 0.127.15 (2026-06-16)

### Refactored
- #2585 — legacy 레이어 제거 (#2601)
''';

void main() {
  group('parseChangelogEntries', () {
    test('newest-first order and header fields (release-please + legacy)', () {
      final entries = parseChangelogEntries(_fixture, limit: 10);
      expect(entries, hasLength(3));
      expect(entries[0].version, '0.128.1');
      expect(entries[0].date, '2026-07-25');
      expect(entries[1].version, '0.128.0');
      expect(entries[2].version, '0.127.15');
      expect(entries[2].date, '2026-06-16');
    });

    test('groups bullets under their section heading', () {
      final entries = parseChangelogEntries(_fixture, limit: 1);
      expect(entries, hasLength(1));
      expect(entries.single.sections.keys, ['버그 수정']);
      expect(entries.single.sections['버그 수정'], hasLength(2));
    });

    test('respects both `*` (release-please) and `-` (legacy) bullets', () {
      final entries = parseChangelogEntries(_fixture, limit: 10);
      final legacy = entries.firstWhere((e) => e.version == '0.127.15');
      expect(legacy.sections['Refactored'], hasLength(1));
      expect(legacy.sections['Refactored']!.single, contains('legacy 레이어 제거'));
    });

    test('limit=0 returns no entries without throwing', () {
      expect(parseChangelogEntries(_fixture, limit: 0), isEmpty);
    });

    test('source with no parseable header returns empty, not throwing', () {
      expect(parseChangelogEntries('no headers here\njust prose.'), isEmpty);
    });

    test('limit caps the number of entries even when more exist', () {
      final entries = parseChangelogEntries(_fixture, limit: 2);
      expect(entries, hasLength(2));
      expect(entries.map((e) => e.version), ['0.128.1', '0.128.0']);
    });
  });

  group('stripChangelogNoise', () {
    test('collapses markdown links to their text', () {
      expect(
        stripChangelogNoise(
          '**button:** fix ([#3293](https://x/issues/3293)) ([feb46b2](https://x/commit/feb46b2))',
        ),
        '**button:** fix (#3293) (feb46b2)',
      );
    });

    test('leaves plain text untouched', () {
      expect(stripChangelogNoise('plain bullet text'), 'plain bullet text');
    });
  });

  group('changelogBulletSpans', () {
    test('splits the bold scope and inline code out of the subject', () {
      expect(
        changelogBulletSpans('**button:** keep `Button.size` ([#3293](https://x/issues/3293))'),
        [
          (kind: ChangelogSpanKind.strong, text: 'button:'),
          (kind: ChangelogSpanKind.text, text: ' keep '),
          (kind: ChangelogSpanKind.code, text: 'Button.size'),
          (kind: ChangelogSpanKind.text, text: ' (#3293)'),
        ],
      );
    });

    test('a marker without its closing pair stays as text', () {
      expect(changelogBulletSpans('2 ** 3 and `x'), [(kind: ChangelogSpanKind.text, text: '2 ** 3 and `x')]);
    });

    test('no real bullet reaches a reader with a literal marker', () {
      for (final package in kReleaseTimelinePackages) {
        final source = File('../packages/$package/CHANGELOG.md').readAsStringSync();
        for (final entry in parseChangelogEntries(source, limit: kReleaseTimelinePerPackage)) {
          for (final bullet in entry.sections.values.expand((bullets) => bullets)) {
            for (final span in changelogBulletSpans(bullet)) {
              expect(span.text, isNot(contains('**')), reason: '$package ${entry.version}: $bullet');
              expect(span.text, isNot(contains('`')), reason: '$package ${entry.version}: $bullet');
            }
          }
        }
      }
    });
  });

  group('real package CHANGELOG.md files parse cleanly', () {
    // Gate: if a package's CHANGELOG.md ever drifts to a header shape this
    // parser cannot read, `<ChangelogPreview>` on the /changelog page
    // silently renders "no parseable release entries" instead of the real
    // releases. This test makes that failure visible in CI instead of only
    // on the live site.
    for (final package in ['coui_flutter', 'coui_web', 'coui_core']) {
      test('packages/$package/CHANGELOG.md yields at least one entry', () {
        final file = File('../packages/$package/CHANGELOG.md');
        expect(file.existsSync(), isTrue, reason: '${file.path} must exist');

        final entries = parseChangelogEntries(file.readAsStringSync(), limit: 5);
        expect(
          entries,
          isNotEmpty,
          reason:
              '${file.path} has release entries but none parsed — the '
              'header format likely drifted from what parseChangelogEntries expects.',
        );
        // A version number, not markdown link/date noise.
        expect(entries.first.version, matches(RegExp(r'^\d+\.\d+\.\d+$')));
      });
    }
  });

  group('changelogPreviewView — what both documentation surfaces show', () {
    test('count limits the entries, newest first', () {
      final view = changelogPreviewView(
        package: 'p',
        attributes: const {'package': 'p', 'count': '2'},
        changelogSource: _fixture,
      );
      expect(view, isA<ChangelogPreviewEntries>());
      expect((view as ChangelogPreviewEntries).entries.map((e) => e.version), ['0.128.1', '0.128.0']);
    });

    test('an absent or non-numeric count falls back to the default', () {
      for (final attributes in [
        const {'package': 'p'},
        const {'package': 'p', 'count': 'many'},
      ]) {
        final view =
            changelogPreviewView(package: 'p', attributes: attributes, changelogSource: _fixture)
                as ChangelogPreviewEntries;
        // The fixture has 3 entries, fewer than the default.
        expect(view.entries, hasLength(3));
      }
      expect(kChangelogPreviewDefaultCount, 5);
    });

    test('a source with no release header degrades to a notice', () {
      final view = changelogPreviewView(
        package: 'p',
        attributes: const {'package': 'p'},
        changelogSource: '# nothing released yet\n',
      );
      expect(
        (view as ChangelogPreviewNotice).message,
        'p/CHANGELOG.md has no parseable release entries yet.',
      );
    });

    test('package attribute: missing and empty both read as absent', () {
      expect(changelogPreviewPackage(const {}), isNull);
      expect(changelogPreviewPackage(const {'package': ''}), isNull);
      expect(changelogPreviewPackage(const {'package': 'coui_web'}), 'coui_web');
    });
  });
}
