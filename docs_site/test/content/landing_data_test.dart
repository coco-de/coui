@TestOn('vm')
library;

import 'dart:io';

import 'package:coui_web/coui_web.dart' show CoreButtonVariant, CoreTypography, ThemeConfig;
import 'package:docs_core/markdown/changelog.dart';
import 'package:docs_core/shared/component_catalog.dart';
import 'package:docs_core/shared/guide_catalog.dart';
import 'package:docs_site/components/site_landing_data.dart';
import 'package:docs_site/components/site_showcase.dart';
import 'package:jaspr_test/server_test.dart';

/// 랜딩이 말하는 값이 살아 있는 출처에서 오는지 본다.
///
/// 랜딩은 숫자와 이름을 많이 말한다. 손으로 적힌 값은 지금은 맞고,
/// 카탈로그나 계약이 바뀌는 날 조용히 거짓이 된다. 아래 테스트는 그 값이
/// 가리키는 것이 **실재하는지**를 본다 — 값 자체를 다시 적어 두지 않는다
/// (그러면 킷이 값을 바꾸는 날 이 테스트가 틀린 쪽이 된다).
void main() {
  /// 문서 경로가 가리키는 콘텐츠 파일.
  ///
  /// `/x/y#z` → `content/x/y.md` 또는 `content/x/y/index.md`.
  File? contentFile(String href) {
    final path = href.split('#').first;
    for (final candidate in ['../docs_core/content$path.md', '../docs_core/content$path/index.md']) {
      final file = File(candidate);
      if (file.existsSync()) return file;
    }
    return null;
  }

  final total = kDocsComponentGroups.fold<int>(0, (sum, group) => sum + group.items.length);
  final kitSheet = ThemeConfig.defaults().cssVariables;

  group('컴포넌트 수', () {
    test('카탈로그의 수를 십 단위로 내린 값이다', () {
      expect(siteComponentTotal, total);
      expect(siteComponentFloor, greaterThan(0));
      expect(siteComponentFloor % 10, 0);
      // "N+" 가 참이려면 내린 값이 실제 수를 넘지 않아야 하고, 열 개 넘게
      // 모자라면 낡은 숫자다.
      expect(siteComponentFloor, lessThanOrEqualTo(total));
      expect(total - siteComponentFloor, lessThan(10));
    });
  });

  group('경로', () {
    test('가이드 경로를 카탈로그에서 찾는다', () {
      for (final guide in kDocsGuides) {
        expect(siteGuidePath(guide.slug), guide.path);
      }
    });

    test('카탈로그에 없는 slug 는 던진다', () {
      // 죽은 링크가 조용히 나가는 대신 빌드가 멈춘다.
      expect(() => siteGuidePath('no-such-guide'), throwsStateError);
      expect(() => siteComponent('no-such-component'), throwsStateError);
    });
  });

  group('진입 카드', () {
    test('네 갈래이고 목적지가 서로 다르다', () {
      expect(siteEntryPoints, hasLength(4));
      expect(siteEntryPoints.map((entry) => entry.href).toSet(), hasLength(4));
    });

    test('목적지가 전부 실재하는 문서다', () {
      for (final entry in siteEntryPoints) {
        expect(contentFile(entry.href), isNotNull, reason: '`${entry.title}` 카드의 `${entry.href}` 에 문서가 없다');
      }
    });

    test('컴포넌트 카드가 말하는 수가 카탈로그에서 온다', () {
      final components = siteEntryPoints.singleWhere((entry) => entry.href == '/components-overview');

      expect(components.description, contains('$siteComponentFloor개'));
    });
  });

  group('코드 견본', () {
    test('두 플랫폼이 갈리는 것은 import 한 줄뿐이다', () {
      expect(kSiteCodeSamples, hasLength(2));
      expect(kSiteCodeSamples.map((sample) => sample.importLine).toSet(), hasLength(2));
      expect(kSiteCodeSamples.map((sample) => sample.id).toSet(), hasLength(2));
    });

    test('import 가 가리키는 패키지가 실재한다', () {
      for (final sample in kSiteCodeSamples) {
        expect(
          File('../packages/${sample.package}/lib/${sample.package}.dart').existsSync(),
          isTrue,
          reason: '`${sample.importLine}` 는 없는 배럴을 가리킨다',
        );
      }
    });

    test('변형 이름이 enum 의 멤버다', () {
      final variant = siteCodeCall.singleWhere((line) => line.contains('variant:'));

      expect(variant, contains('CoreButtonVariant.${CoreButtonVariant.primary.name}'));
    });
  });

  group('타이포그래피 견본', () {
    test('옆에 적는 크기가 그 역할의 크기다', () {
      for (final sample in kSiteTypeSamples) {
        expect(sample.size, sample.role.read(CoreTypography.coui).fontSize?.round());
        expect(sample.size, greaterThan(0), reason: '`${sample.label}` 역할에 크기가 없다');
      }
    });

    test('큰 역할부터 작은 역할로 내려간다', () {
      final sizes = [for (final sample in kSiteTypeSamples) sample.size];

      expect(sizes, orderedEquals([...sizes]..sort((a, b) => b.compareTo(a))));
    });
  });

  group('색상 견본', () {
    test('단계가 전부 neutral 램프에 있다', () {
      final ramp = siteNeutralRamp;

      for (final step in kSiteNeutralSteps) {
        expect(ramp, contains(step));
        expect(kitSheet, contains('--coui-neutral-$step:'), reason: '킷이 `--coui-neutral-$step` 을 정의하지 않는다');
      }
    });

    test('밝은 쪽에서 어두운 쪽으로 간다', () {
      expect(kSiteNeutralSteps, orderedEquals([...kSiteNeutralSteps]..sort()));
    });
  });

  group('레이어 목록', () {
    test('이름과 문서가 카탈로그에서 온다', () {
      for (final layer in siteLayers) {
        expect(layer.name, siteComponent(layer.slug).name);
        expect(contentFile(layer.href), isNotNull, reason: '`${layer.href}` 에 문서가 없다');
      }
    });

    test('토큰이 킷의 색 변수다', () {
      for (final layer in siteLayers) {
        expect(layer.token, isNotEmpty);
        expect(kitSheet, contains('--coui-${layer.token}:'), reason: '`${layer.name}` 의 `${layer.token}`');
      }
    });

    test('변형을 Figma 가 적는 방식으로 적는다', () {
      for (final layer in siteLayers) {
        expect(layer.figmaProperty, matches(RegExp(r'^[A-Z][a-z]+=[a-zA-Z0-9]+$')));
        expect(layer.figmaProperty.toLowerCase(), '${layer.property}=${layer.value}'.toLowerCase());
      }
    });

    test('줄마다 다른 컴포넌트다', () {
      expect(siteLayers.map((layer) => layer.slug).toSet(), hasLength(siteLayers.length));
    });
  });

  group('최근 업데이트 — 한 릴리스에서 한 줄 고르기', () {
    ChangelogEntry release(Map<String, List<String>> sections, {String date = '2026-11-12'}) =>
        ChangelogEntry(version: '1.2.3', date: date, sections: sections);

    test('기능이 있으면 기능을 올린다', () {
      final update = siteUpdateOf(
        release({
          '버그 수정': ['fix first'],
          '기능': ['feature first', 'feature second'],
        }),
      );

      expect(update?.kind, SiteUpdateKind.feature);
      expect(update?.summary, 'feature first');
      expect(update?.version, 'v1.2.3');
    });

    test('기능이 없으면 수정을 올린다', () {
      final update = siteUpdateOf(
        release({
          '리팩터링': ['refactor first'],
          '버그 수정': ['fix first'],
        }),
      );

      expect(update?.kind, SiteUpdateKind.fix);
      expect(update?.summary, 'fix first');
    });

    test('둘 다 없으면 처음 나오는 섹션의 첫 항목이다', () {
      final update = siteUpdateOf(
        release({
          '문서': <String>[],
          '리팩터링': ['refactor first'],
        }),
      );

      expect(update?.kind, SiteUpdateKind.update);
      expect(update?.summary, 'refactor first');
    });

    test('항목이 없는 릴리스는 올리지 않는다', () {
      expect(siteUpdateOf(release({})), isNull);
      expect(siteUpdateOf(release({'기능': <String>[]})), isNull);
    });

    test('항목에서 표시와 참조를 걷어 낸다', () {
      final update = siteUpdateOf(
        release({
          '기능': [
            '**banner:** `Button` 의 상태 레이어를 넓힌다 '
                '([#6235](https://example.test/issues/6235)) '
                '([daec939](https://example.test/commit/daec939394)), closes #6001',
          ],
        }),
      );

      expect(update?.summary, 'banner: Button 의 상태 레이어를 넓힌다');
    });

    test('날짜를 월.일로 적는다', () {
      expect(
        siteUpdateOf(
          release({
            '기능': ['x'],
          }),
        )?.date,
        '11.12',
      );
      // 형식이 다르면 지어내지 않고 적힌 그대로 둔다.
      expect(
        siteUpdateOf(
          release({
            '기능': ['x'],
          }, date: 'soon'),
        )?.date,
        'soon',
      );
    });
  });

  group('최근 업데이트 — CHANGELOG 에서 읽기', () {
    const source = '''
## Unreleased

- not a release yet

## [3.0.0](https://example.test/compare/v2...v3) (2026-03-03)

### 기능

* third ([#3](https://example.test/3))

## [2.0.0](https://example.test/compare/v1...v2) (2026-02-02)

## [1.0.0](https://example.test/compare/v0...v1) (2026-01-01)

### 버그 수정

* first
''';

    test('최근 것부터, 항목 없는 릴리스는 건너뛴다', () {
      final updates = siteUpdatesFrom(source, count: 2);

      expect(updates.map((update) => update.version), ['v3.0.0', 'v1.0.0']);
      expect(updates.map((update) => update.kind), [SiteUpdateKind.feature, SiteUpdateKind.fix]);
      expect(updates.first.summary, 'third');
    });

    test('요청한 수를 넘지 않는다', () {
      expect(siteUpdatesFrom(source, count: 1), hasLength(1));
    });

    test('패키지의 실제 CHANGELOG 에서 줄을 채운다', () {
      final updates = SiteUpdates.read();

      expect(updates, hasLength(SiteUpdates.count), reason: '`${SiteUpdates.package}` 의 CHANGELOG 를 읽지 못했다');
      for (final update in updates) {
        expect(update.version, matches(RegExp(r'^v\d+\.\d+\.\d+')));
        expect(update.date, matches(RegExp(r'^\d{2}\.\d{2}$')));
        expect(update.summary, isNotEmpty);
        // 마크다운 표시와 참조가 화면에 새지 않는다.
        expect(update.summary, isNot(contains('**')));
        expect(update.summary, isNot(contains('](')));
        expect(update.summary, isNot(matches(RegExp(r'\(#\d+\)\s*$'))));
      }
    });
  });
}
