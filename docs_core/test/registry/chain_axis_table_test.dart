@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/shared/chain_axis_table.dart';
import 'package:docs_core/shared/chain_tier1.dart';
import 'package:test/test.dart';

/// chain 실측표 생성물(`tool/generate_chain_artifacts.dart`)의 내부 계약을
/// 게이트로 강제한다.
///
/// 두 생성물(실측표 · tier1 name-set)은 같은 생성기 실행에서 나오지만 별개
/// 파일이라, 한쪽만 재생성되면 조용히 갈라질 수 있다 — 여기서 파생 관계를
/// 다시 계산해 대조한다. tier1 set 의 **server-safe(순수 Dart)** 요건도
/// 문서가 아니라 이 테스트가 지킨다: SSG 판정 경로에 widget-bearing import
/// 가 한 줄이라도 들어오면 서버 빌드에 `dart:ui` 가 유입된다.
void main() {
  test('tier1 name-set 은 실측표 파생과 정확히 일치한다', () {
    final derived = {
      for (final entry in kChainAxisTable)
        if (entry.tier == ChainTier.t1 && entry.hasDocsExampleDir) entry.component,
    };
    expect(
      kChainTier1Components,
      derived,
      reason:
          '두 생성물이 갈라졌다 — dart run tool/generate_chain_artifacts.dart '
          '--write 로 함께 재생성해야 한다.',
    );
  });

  test('생성물 소스는 순수 Dart — import 자체가 0 (server-safe)', () {
    for (final path in [
      'lib/shared/chain_axis_table.dart',
      'lib/shared/chain_tier1.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(
        RegExp(r'^\s*import\b', multiLine: true).hasMatch(source),
        isFalse,
        reason:
            '$path 는 순수 데이터여야 한다 — jaspr/Flutter 는 물론 어떤 '
            'import 도 SSG 판정 경로의 서버 안전성을 흔든다.',
      );
    }
  });

  test('T1 행은 양 플랫폼 primary 가 양축 getter 와 withStyle 을 보유한다', () {
    for (final entry in kChainAxisTable.where(
      (e) => e.tier == ChainTier.t1,
    )) {
      final flutter = entry.flutterTargets.firstWhere(
        (t) => t.target == entry.primaryTarget,
        orElse: () => fail('${entry.component}: Flutter primary target 부재'),
      );
      final web = entry.webTargets.firstWhere(
        (t) => t.target == entry.primaryTarget,
        orElse: () => fail('${entry.component}: Web primary target 부재'),
      );
      for (final surface in [flutter, web]) {
        expect(
          surface.radiusGetters,
          isNotEmpty,
          reason: '${entry.component} ${surface.target}: radius 축 없음',
        );
        expect(
          surface.colorGetters,
          isNotEmpty,
          reason: '${entry.component} ${surface.target}: 색 축 없음',
        );
        expect(
          surface.hasWithStyle,
          isTrue,
          reason: '${entry.component} ${surface.target}: withStyle 없음',
        );
      }
    }
  });

  test('getter 이름은 축 규약을 따른다 (radius 접두 = radius 축 전용)', () {
    final radiusName = RegExp(r'^radius\d+$');
    for (final entry in kChainAxisTable) {
      for (final surface in [...entry.flutterTargets, ...entry.webTargets]) {
        for (final getter in surface.radiusGetters) {
          expect(
            radiusName.hasMatch(getter),
            isTrue,
            reason:
                '${entry.component} ${surface.target}: radius getter '
                "'$getter' 가 CoreRadius 상수 명명이 아니다",
          );
        }
        for (final getter in surface.colorGetters) {
          expect(
            getter.startsWith('radius'),
            isFalse,
            reason:
                '${entry.component} ${surface.target}: 색 축에 radius 이름 '
                "'$getter' 가 섞였다",
          );
        }
      }
    }
  });

  test('Text 체인은 표 밖이다 — 동명 getter 오검출 배제 규칙', () {
    // Text 의 `.primary` 류는 typography 체인(`TextExtension on Widget`)이지
    // Style-slot 체인이 아니다. 생성기의 `*StyleChain` 명명 스코프 +
    // framework-target 펜스가 이를 배제했는지 표 쪽에서 재확인한다.
    expect(
      kChainAxisTable.any((e) => e.component == 'text'),
      isFalse,
      reason: 'text 가 실측표에 들어왔다 — Text 체인 오검출',
    );
    expect(
      kChainExcludedComponents,
      contains('text'),
      reason: 'text 는 제외 목록(Style 슬롯 비대상)에 있어야 한다',
    );
  });

  test('컴포넌트 키는 registry 형식(하이픈 slug)이다', () {
    for (final entry in kChainAxisTable) {
      expect(
        entry.component,
        matches(RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$')),
        reason: '${entry.component}: 하이픈 slug 형식이 아니다',
      );
    }
  });
}
