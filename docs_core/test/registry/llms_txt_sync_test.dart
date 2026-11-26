@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/shared/block_catalog.dart';
import 'package:docs_core/shared/component_catalog.dart';
import 'package:docs_core/shared/docs_navigation.dart';
import 'package:docs_core/shared/guide_catalog.dart';
import 'package:docs_core/shared/llms_txt.dart';
import 'package:test/test.dart';

import '../../tool/gen_llms_txt.dart';

/// `llms.txt` 가 카탈로그에서 파생된 그대로인지, 그리고 AI 표면 언어 정책
/// (영문)을 지키는지 게이트한다.
///
/// 왜 테스트인가: `llms.txt` 는 손으로 고치지 않는 생성물이다. 카탈로그에
/// 컴포넌트를 추가하고 생성기 재실행을 잊으면, 사이드바에는 있는데 AI
/// 소비자에게는 없는 컴포넌트가 조용히 생긴다 — 카탈로그 이전 시절 손으로
/// 관리하던 nav 사본들이 갈라졌던 것과 같은 모양이다.
void main() {
  final hangul = RegExp('[가-힣ㄱ-ㆎ]');

  test('커밋된 llms.txt 가 카탈로그에서 다시 구운 것과 같다', () {
    final file = File(kLlmsTxtOutputPath);
    expect(
      file.existsSync(),
      isTrue,
      reason:
          '$kLlmsTxtOutputPath 가 없다 — '
          '`cd docs_core && dart run tool/gen_llms_txt.dart` 로 생성하라',
    );
    expect(
      file.readAsStringSync(),
      renderLlmsTxt(),
      reason:
          'llms.txt 가 카탈로그와 어긋난다 — '
          '`cd docs_core && dart run tool/gen_llms_txt.dart` 로 재생성하라',
    );
  });

  test('모든 카탈로그 컴포넌트가 정확히 한 번 링크된다', () {
    final text = renderLlmsTxt();
    for (final entry in kDocsComponentEntries) {
      final link = '($kDocsSiteOrigin/components/${entry.slug})';
      expect(
        link.allMatches(text).length,
        1,
        reason: '${entry.slug} 가 llms.txt 에 한 번 링크돼야 한다',
      );
    }
  });

  test('모든 블록이 정확히 한 번 링크된다', () {
    final text = renderLlmsTxt();
    for (final block in kDocsBlocks) {
      final link = '($kDocsSiteOrigin${block.path})';
      expect(link.allMatches(text).length, 1, reason: block.slug);
    }
    expect(text, isNot(contains('/components/footer')));
  });

  test('모든 가이드가 링크된다', () {
    final text = renderLlmsTxt();
    for (final guide in kDocsGuides) {
      expect(text, contains('($kDocsSiteOrigin${guide.path})'));
    }
  });

  test('AI 표면은 영문이다 — 한글이 한 글자도 없다', () {
    final offending = renderLlmsTxt().split('\n').where(hangul.hasMatch).toList();
    expect(
      offending,
      isEmpty,
      reason:
          'llms.txt 에 한글이 섞였다. 컴포넌트면 카탈로그 엔트리에 '
          '`englishDescription`, 가이드면 `englishLabel` 을 영문으로 채워라',
    );
  });

  test('englishDescription 은 한글 description 에만 둔다', () {
    // 영문 description 에 영문 요약을 하나 더 두면 두 벌이 생기고, 한쪽만
    // 고쳐지는 날 사이드바와 llms.txt 가 서로 다른 말을 한다.
    final redundant = [
      for (final entry in kDocsComponentEntries)
        if (entry.englishDescription != null && !hangul.hasMatch(entry.description)) entry.slug,
    ];
    expect(redundant, isEmpty);
  });

  test('구조의 모든 페이지가 정확히 한 번 링크된다', () {
    // 사이드바에는 있는데 AI 소비자에게는 없는 페이지가 생기지 않는다 —
    // 탭 하나를 통째로 빠뜨려도 여기서 걸린다.
    final text = renderLlmsTxt();
    for (final location in kDocsNavLocations) {
      final link = '($kDocsSiteOrigin${location.page.path})';
      expect(link.allMatches(text).length, 1, reason: location.page.path);
    }
  });
}
