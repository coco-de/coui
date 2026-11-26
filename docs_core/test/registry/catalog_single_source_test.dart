@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/previews/code_registry.dart';
import 'package:docs_core/previews/flutter_code_registry.dart';
import 'package:docs_core/shared/block_catalog.dart';
import 'package:docs_core/shared/component_catalog.dart';
import 'package:docs_core/shared/docs_template.dart';
import 'package:docs_core/shared/preview_constraints.dart';
import 'package:docs_core/shared/preview_layout.dart';
import 'package:test/test.dart';

/// 문서 컴포넌트 카탈로그가 진짜로 단일 출처인지 강제한다.
///
/// 예전에는 같은 138개 컴포넌트가 손으로 관리되는 사본 3벌(사이드바 · 개요
/// 그리드 · 검색 인덱스)로 살았다. 지켜준 건 코드가 아니라 규율이었다 — 룰
/// 문서가 컴포넌트마다 세 곳 등록을 요구했다. 이 테스트가 그 규율을 게이트로
/// 바꾼다: 목록이 갈라지면 여기서 깨진다.
void main() {
  final contentDir = Directory('content/components');

  final catalogSlugs = kDocsComponentEntries.map((e) => e.slug).toSet();
  final blockSlugs = kDocsBlocks.map((e) => e.slug).toSet();
  final documentedSlugs = catalogSlugs.union(blockSlugs);

  test('블록 카탈로그와 블록 마크다운이 대응한다', () {
    final blockDir = Directory('content/blocks');
    final fileSlugs = blockDir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.md'))
        .map((n) => n.substring(0, n.length - 3))
        .toSet();

    expect(
      blockSlugs.difference(fileSlugs),
      isEmpty,
      reason: '블록 카탈로그에는 있는데 content/blocks/<slug>.md 가 없다',
    );
    expect(fileSlugs.difference(blockSlugs), {'index'});
  });

  test('옮겨진 컴포넌트 경로는 블록 페이지를 가리킨다', () {
    expect(kDocsMovedBlockPaths['/components/footer'], '/blocks/footer');
    for (final entry in kDocsMovedBlockPaths.entries) {
      final slug = entry.value.split('/').last;
      expect(blockSlugs, contains(slug));
      expect(File('content/blocks/$slug.md').existsSync(), isTrue);
      expect(catalogSlugs, isNot(contains(entry.key.split('/').last)));
      expect(
        File('content/components/${entry.key.split('/').last}.md').existsSync(),
        isFalse,
      );
    }
  });

  test('카탈로그와 마크다운 페이지가 정확히 대응한다', () {
    final fileSlugs = contentDir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.md'))
        .map((n) => n.substring(0, n.length - 3))
        .toSet();

    expect(
      catalogSlugs.difference(fileSlugs),
      isEmpty,
      reason: '카탈로그에는 있는데 content/components/<slug>.md 가 없다',
    );
    expect(
      fileSlugs.difference(catalogSlugs),
      isEmpty,
      reason:
          '마크다운 페이지는 있는데 카탈로그 엔트리가 없다 — 사이드바와 '
          '개요 그리드에서 보이지 않게 된다',
    );
  });

  test('모든 컴포넌트가 Web + Flutter 코드 스니펫을 가진다', () {
    // Flutter 스니펫은 deprecated 여도 요구한다 — Flutter 는 외부 호환을 위해
    // 계속 동작해야 하므로(process/deprecation.md), 데모도 계속 유효하다.
    expect(
      kFlutterCodeSnippetRegistry.keys.toSet().difference(documentedSlugs),
      isEmpty,
    );
    expect(
      catalogSlugs.difference(kFlutterCodeSnippetRegistry.keys.toSet()),
      isEmpty,
    );
    expect(
      blockSlugs.difference(kFlutterCodeSnippetRegistry.keys.toSet()),
      isEmpty,
      reason: '블록 카탈로그의 슬러그가 Flutter 코드 스니펫에 없다',
    );

    // Web 스니펫은 active 컴포넌트에만 요구한다 — deprecated 전체-컴포넌트의
    // Web 구현은 완전 삭제가 정책이라(process/component-creation.md), 카탈로그엔
    // 남아 있어도(사이드바/그리드 deprecation 배너용) Web 쪽 짝이 없는 게 정상이다.
    final deprecatedSlugs = kDocsComponentEntries.where((e) => e.isDeprecated).map((e) => e.slug).toSet();
    final activeSlugs = catalogSlugs.difference(deprecatedSlugs);

    expect(
      kCodeSnippetRegistry.keys.toSet().difference(documentedSlugs),
      isEmpty,
    );
    expect(activeSlugs.difference(kCodeSnippetRegistry.keys.toSet()), isEmpty);
  });

  test('카탈로그 슬러그가 유일하다', () {
    expect(kDocsComponentEntries.length, catalogSlugs.length);
  });

  test('그룹 id 가 유일하고 비어있지 않다', () {
    final ids = kDocsComponentGroups.map((g) => g.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(ids.every((id) => id.isNotEmpty), isTrue);
  });

  test('프리뷰 제약과 레이아웃 셋이 실재하는 컴포넌트만 가리킨다', () {
    // `component/variant` 키는 컴포넌트 부분만 검사한다.
    final constrained = kDocsPreviewConstraints.keys.map((k) => k.split('/').first).toSet();
    expect(
      constrained.difference(documentedSlugs),
      isEmpty,
      reason: '제약이 문서화되지 않은 컴포넌트를 가리킨다 (오타이거나 죽은 키)',
    );
    expect(kDocsWideComponents.difference(documentedSlugs), isEmpty);
    expect(kDocsFullRowGalleryComponents.difference(catalogSlugs), isEmpty);
  });

  test('mockup 은 반폭 페인에서 Flutter 크롬이 중앙 슬라이스되므로 wide 다', () {
    // Phone defaultWidth 320 + Align(topCenter) 가 ~149px 반폭 페인에서
    // 프레임/노치를 잘라 내부 카피만 남긴다 (#4767).
    expect(kDocsWideComponents, contains('mockup'));
  });

  test('모든 컴포넌트 문서가 접근성 섹션을 갖는다', () {
    // 왜 테스트인가: 이 요구사항은 이미 문서 템플릿에 들어 있었고, 그러고도
    // 50건이 비어 있었다. 템플릿은 새 문서를 쓰는 사람이 읽을 때만 작동하고
    // 게이트는 안 읽어도 작동한다 — 실패가 입증된 대책을 한 번 더 두는 대신
    // 깨지는 것으로 바꾼다.
    //
    // 접근성 섹션이 없는 문서는 소비자가 그 컴포넌트의 키보드 조작과
    // 스크린리더 동작을 알 방법이 없다는 뜻이고, 알 수 없으면 자기 앱에서
    // 검증할 수도 없다.
    final missing = <String>[];
    for (final slug in catalogSlugs) {
      final file = File('content/components/$slug.md');
      if (!file.existsSync()) continue;
      final source = file.readAsStringSync();
      final heading = docsUsesTemplateV2(source) ? '## $kDocsV2AccessibilitySection\n' : '## 접근성 (Accessibility)';
      if (!source.contains(heading)) {
        missing.add(slug);
      }
    }

    expect(
      missing,
      isEmpty,
      reason: '접근성 섹션이 없는 컴포넌트 문서: ${missing.join(" ")}',
    );
  });

  test('모든 컴포넌트 문서가 사용 가이드라인 섹션을 갖는다', () {
    // 왜 테스트인가: 위 접근성 섹션 게이트와 같은 이유 — 이 요구사항도 이미
    // 문서 템플릿(_templates/component.md)에 들어 있었지만 139건 중 90건이
    // 비어 있었다. 템플릿은 새 문서를 쓰는 사람이 읽을 때만 작동하고 게이트는
    // 안 읽어도 작동한다.
    //
    // 사용 가이드라인 섹션이 없는 문서는 소비자가 이 컴포넌트를 언제·어떻게
    // 써야 하는지(Do/Don't)를 알 방법이 없다는 뜻이다.
    final missing = <String>[];
    for (final slug in catalogSlugs) {
      final file = File('content/components/$slug.md');
      if (!file.existsSync()) continue;
      final source = file.readAsStringSync();
      final heading = docsUsesTemplateV2(source) ? '## $kDocsV2UsageSection\n' : '## 사용 가이드라인 (Usage Guidelines)';
      if (!source.contains(heading)) {
        missing.add(slug);
      }
    }

    expect(
      missing,
      isEmpty,
      reason: '사용 가이드라인 섹션이 없는 컴포넌트 문서: ${missing.join(" ")}',
    );
  });

  test('컴포넌트 문서의 섹션 순서가 표준을 따른다', () {
    // 왜 테스트인가: _templates/component.md 가 정하는 섹션 순서와 실제
    // 139개 문서 간 순서가 들쭉날쭉했다(예: drawer/toast 는 스타일 섹션이
    // Props 보다 먼저, 여러 문서가 크로스 플랫폼 차이점을 접근성보다 먼저
    // 배치). 표준 순서를 문서로만 적어두면 새 문서를 쓰는 사람이 참고할
    // 때만 지켜지므로, 존재하는 섹션들의 상대 순서를 게이트로 강제한다.
    //
    // 순위가 매겨진 섹션 중 실제로 그 문서에 존재하는 것들만 비교 대상이며,
    // 순위가 없는 컴포넌트 고유 섹션(예: "배치 옵션", "충돌 정책")은
    // 검사하지 않는다 — 표준 섹션들 사이의 상대 순서만 고정한다.
    final rankedSections = <double, RegExp>{
      0: RegExp(r'^## Live Preview$'),
      1: RegExp(r'^## (사용 시기|When to Use)'),
      2: RegExp(r'^## (기본 사용법|Basic [Uu]sage)'),
      4: RegExp(r'^## Props\b'),
      4.5: RegExp(r'^## (스타일 시스템|Style System)\b'),
      5: RegExp(r'^## 변형 \(Variants\)'),
      6: RegExp(r'^## 동작 스펙 \(Behavior\)'),
      7: RegExp(r'^## 사용 가이드라인 \(Usage Guidelines\)'),
      8: RegExp(r'^## 접근성 \(Accessibility\)'),
      9: RegExp(r'^## (크로스 플랫폼 차이점|양쪽 플랫폼 차이)'),
      9.5: RegExp(r'^## 레거시 vs 통일 비교'),
      10: RegExp(r'^## 관련 컴포넌트'),
    };

    double? classify(String heading) {
      for (final entry in rankedSections.entries) {
        if (entry.value.hasMatch(heading)) return entry.key;
      }
      return null;
    }

    final offenders = <String>[];
    for (final slug in catalogSlugs) {
      final file = File('content/components/$slug.md');
      if (!file.existsSync()) continue;
      final headings = file.readAsLinesSync().where((line) => line.startsWith('## '));
      var prev = -1.0;
      for (final heading in headings) {
        final rank = classify(heading);
        if (rank == null) continue;
        if (rank < prev) {
          offenders.add('$slug: "$heading" 가 앞선 섹션보다 뒤에 있어야 함');
        }
        prev = rank > prev ? rank : prev;
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: '섹션 순서 위반:\n  ${offenders.join("\n  ")}',
    );
  });

  test('공유 문서 모델이 순수 Dart 로 남는다', () {
    // 이 파일들은 jaspr 사이트와 네이티브 Flutter 앱이 함께 읽는다. 어느 한
    // 쪽 프레임워크를 import 하는 순간 다른 쪽에서 컴파일이 깨지고, 그러면
    // 목록이 다시 갈라진다.
    for (final name in [
      'component_catalog.dart',
      'preview_constraints.dart',
      'preview_layout.dart',
      // `tool/gen_llms_txt.dart` 가 `dart run` 으로 이 파일을 읽는다 —
      // Flutter 를 import 하면 생성기가 dart:ui 없이 컴파일되지 않는다.
      'llms_txt.dart',
    ]) {
      final source = File('lib/shared/$name').readAsStringSync();
      expect(
        RegExp('package:(flutter|jaspr)').hasMatch(source),
        isFalse,
        reason:
            'lib/shared/$name 이 프레임워크를 import 한다 — 공유 모델은 '
            '순수 Dart 여야 한다',
      );
    }
  });
}
