/// `<CurrentVersion />` · `<ChangelogPreview />` — 네이티브가 docs_site 와
/// 같은 원본에서 같은 것을 그리는가.
///
/// 두 층을 따로 본다:
///
/// 1. **원본** — 앱 번들의 `release/` 자산이 `packages/<pkg>/` 의 파일과
///    같은가. 사본이면 첫 릴리스에 낡으므로 심링크여야 하고, 링크가 끊기면
///    그 자리가 조용히 저하 문구로 바뀐다.
/// 2. **해석** — 같은 원본을 받았을 때 네이티브가 그린 항목·버전이
///    docs_site 가 부르는 `changelogPreviewView` / `currentVersionView` 의
///    결과와 같은가.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/markdown/docs_markdown.dart';
import 'package:docs_app/src/markdown/docs_tag.dart';
import 'package:docs_app/src/markdown/tags/docs_tags.dart';
import 'package:docs_app/src/preview/preview_theme.dart';
import 'package:docs_core/markdown/changelog.dart';
import 'package:docs_core/markdown/current_version.dart';
import 'package:flutter/services.dart' show CachingAssetBundle, rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// 레포 루트 — 테스트 작업 디렉터리(app/docs_app) 기준.
const _kRepoRoot = '../..';

/// 콘텐츠 루트.
const _kContentRoot = '$_kRepoRoot/docs_core/content';

/// 문서가 부르는 패키지 — 콘텐츠에서 읽는다.
///
/// 목록을 손으로 적으면 changelog.md 가 새 패키지를 부르는 날 이 테스트는
/// 그 패키지를 모른 채 초록으로 남는다.
///
/// `<ReleaseTimeline />` 은 속성 없이 `kReleaseTimelinePackages` 를 읽는다 —
/// 그 태그가 콘텐츠에 있으면 그 목록이 문서가 부르는 패키지다.
Set<String> _referencedPackages() => {
  for (final file in Directory(_kContentRoot).listSync(recursive: true))
    if (file is File && file.path.endsWith('.md'))
      for (final match in findDocsTags(file.readAsStringSync()))
        if (match.tag.name == 'CurrentVersion' ||
            match.tag.name == 'ChangelogPreview')
          ?match.tag.attributes['package']
        else if (match.tag.name == 'ReleaseTimeline')
          ...kReleaseTimelinePackages,
};

String _packageFile(String package, String name) =>
    File('$_kRepoRoot/packages/$package/$name').readAsStringSync();

/// 키 → 문자열 번들. 없는 키는 실제 번들처럼 [FlutterError] 를 던진다.
class _StringBundle extends CachingAssetBundle {
  _StringBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final value = assets[key];
    if (value == null) throw FlutterError('Unable to load asset: "$key".');
    return ByteData.sublistView(utf8.encode(value));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = assets[key];
    if (value == null) throw FlutterError('Unable to load asset: "$key".');
    return value;
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required String markdown,
  required Map<String, String> assets,
}) async {
  await tester.pumpWidget(
    CoUIApp(
      home: Scaffold(
        child: SingleChildScrollView(
          child: DefaultAssetBundle(
            bundle: _StringBundle(assets),
            child: DocsMarkdown(
              markdown: markdown,
              registry: buildDocsTagRegistry(onInternalLink: (_) {}),
            ),
          ),
        ),
      ),
      theme: docsPreviewTheme(dark: false),
    ),
  );
  await tester.pumpAndSettle();
}

/// 화면의 텍스트를 위에서 아래로.
List<String> _texts(WidgetTester tester) => [
  for (final widget in tester.widgetList(find.byType(RichText)))
    (widget as RichText).text.toPlainText(),
];

final _kVersionLine = RegExp(r'^\d+\.\d+\.\d+$');

void main() {
  group('원본 — release/ 자산', () {
    test('문서가 부르는 패키지가 콘텐츠에서 실제로 읽혔다', () {
      // 경로가 틀리면 아래 테스트는 빈 집합을 돌며 항상 통과한다.
      expect(_referencedPackages(), isNotEmpty);
    });

    test('문서가 부르는 패키지마다 packages/<pkg>/ 로 가는 심링크가 있다', () {
      for (final package in _referencedPackages()) {
        for (final (key, name) in [
          (docsReleasePubspecKey(package), 'pubspec.yaml'),
          (docsReleaseChangelogKey(package), 'CHANGELOG.md'),
        ]) {
          expect(
            FileSystemEntity.isLinkSync(key),
            isTrue,
            reason:
                '$key 가 심링크가 아니다 — 사본은 다음 릴리스에 낡는다. '
                '`ln -s ../../../packages/$package/$name $key`',
          );
          expect(
            File(key).resolveSymbolicLinksSync(),
            File(
              '$_kRepoRoot/packages/$package/$name',
            ).resolveSymbolicLinksSync(),
            reason: '$key 가 다른 파일을 가리킨다',
          );
        }
      }
    });

    test('빌드된 번들이 패키지 파일과 같은 내용을 싣는다', () async {
      // pubspec 의 `assets:` 선언까지 봐야 한다 — 심링크가 있어도 선언이
      // 빠지면 앱에는 아무것도 실리지 않는다.
      TestWidgetsFlutterBinding.ensureInitialized();
      for (final package in _referencedPackages()) {
        expect(
          await rootBundle.loadString(docsReleasePubspecKey(package)),
          _packageFile(package, 'pubspec.yaml'),
        );
        expect(
          await rootBundle.loadString(docsReleaseChangelogKey(package)),
          _packageFile(package, 'CHANGELOG.md'),
        );
      }
    });
  });

  group('해석 — docs_site 와 같은 값', () {
    for (final package in ['coui_core', 'coui_flutter', 'coui_web']) {
      testWidgets('$package ChangelogPreview 의 버전·날짜·순서', (tester) async {
        final source = _packageFile(package, 'CHANGELOG.md');
        final attributes = {'package': package, 'count': '5'};
        final expected =
            changelogPreviewView(
                  package: package,
                  attributes: attributes,
                  changelogSource: source,
                )
                as ChangelogPreviewEntries;

        await _pump(
          tester,
          markdown: '<ChangelogPreview package="$package" count="5" />',
          assets: {docsReleaseChangelogKey(package): source},
        );

        final texts = _texts(tester);
        expect(
          texts.where(_kVersionLine.hasMatch).toList(),
          [for (final entry in expected.entries) entry.version],
        );
        for (final entry in expected.entries) {
          expect(texts, contains(entry.date));
        }
      });

      testWidgets('$package CurrentVersion 의 버전과 태그', (tester) async {
        final source = _packageFile(package, 'pubspec.yaml');
        final version = parsePubspecVersion(source)!;

        await _pump(
          tester,
          markdown:
              '<CurrentVersion package="$package" />\n\n'
              '<CurrentVersion package="$package" tag="true" />',
          assets: {docsReleasePubspecKey(package): source},
        );

        expect(
          _texts(tester),
          containsAllInOrder([
            version,
            releaseTag(package, version),
          ]),
        );
      });
    }

    testWidgets('count 속성이 항목 수를 정한다', (tester) async {
      const source = '''
## [0.3.0](https://x) (2026-01-03)

### 기능

* c

## [0.2.0](https://x) (2026-01-02)

### 기능

* b

## [0.1.0](https://x) (2026-01-01)

### 기능

* a
''';
      await _pump(
        tester,
        markdown: '<ChangelogPreview package="p" count="2" />',
        assets: {docsReleaseChangelogKey('p'): source},
      );

      expect(_texts(tester).where(_kVersionLine.hasMatch).toList(), [
        '0.3.0',
        '0.2.0',
      ]);
    });
  });

  group('ReleaseTimeline', () {
    String changelog(String package, int releases) => [
      for (var i = releases; i > 0; i--)
        [
          '## [0.$i.0](https://x) (2026-01-${i.toString().padLeft(2, '0')})',
          '### 버그 수정',
          '* **$package:** keep `Size.$i` ([#$i](https://x/$i))',
        ].join('\n\n'),
    ].join('\n');

    testWidgets('패키지마다 사이트가 읽는 만큼의 릴리스를 그린다', (tester) async {
      await _pump(
        tester,
        markdown: '<ReleaseTimeline />',
        assets: {
          for (final package in kReleaseTimelinePackages)
            docsReleaseChangelogKey(package): changelog(
              package,
              kReleaseTimelinePerPackage + 2,
            ),
        },
      );

      final texts = _texts(tester);
      for (final package in kReleaseTimelinePackages) {
        expect(texts, contains(package), reason: '$package 제목');
      }
      // 사이트는 패키지마다 kReleaseTimelinePerPackage 개를 읽고, 접힌
      // 것까지 모두 펼쳐 볼 수 있다 — 앱도 그 수만큼 보여야 한다.
      expect(
        texts.where(_kVersionLine.hasMatch),
        hasLength(kReleaseTimelinePackages.length * kReleaseTimelinePerPackage),
      );
    });

    testWidgets('항목의 굵게 · 인라인 코드 표시가 글자로 남지 않는다', (tester) async {
      await _pump(
        tester,
        markdown: '<ReleaseTimeline />',
        assets: {
          for (final package in kReleaseTimelinePackages)
            docsReleaseChangelogKey(package): changelog(package, 1),
        },
      );

      final texts = _texts(tester);
      expect(texts, contains('coui_web: keep Size.1 (#1)'));
      expect(
        texts.where((text) => text.contains('**') || text.contains('`')),
        isEmpty,
      );
    });
  });

  group('저하 — docs_site 와 같은 문구', () {
    testWidgets('package 속성이 없다', (tester) async {
      await _pump(
        tester,
        markdown: '<CurrentVersion />\n\n<ChangelogPreview />',
        assets: const {},
      );

      expect(
        _texts(tester),
        containsAllInOrder([
          kCurrentVersionMissingPackageNotice.message,
          kChangelogPreviewMissingPackageNotice.message,
        ]),
      );
    });

    testWidgets('번들에 없는 패키지', (tester) async {
      await _pump(
        tester,
        markdown:
            '<CurrentVersion package="nope" />\n\n'
            '<ChangelogPreview package="nope" />',
        assets: const {},
      );

      final texts = _texts(tester);
      expect(
        texts.any(
          (text) => text.startsWith('Could not read nope/pubspec.yaml'),
        ),
        isTrue,
      );
      expect(texts, contains(changelogPreviewMissingNotice('nope').message));
    });

    testWidgets('해석할 수 없는 원본', (tester) async {
      await _pump(
        tester,
        markdown:
            '<CurrentVersion package="p" />\n\n'
            '<ChangelogPreview package="p" />',
        assets: {
          docsReleasePubspecKey('p'): 'name: p\n',
          docsReleaseChangelogKey('p'): '# 아직 릴리스 없음\n',
        },
      );

      expect(
        _texts(tester),
        containsAllInOrder([
          'p/pubspec.yaml has no `version:` key.',
          'p/CHANGELOG.md has no parseable release entries yet.',
        ]),
      );
    });
  });
}
