@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/previews/code_registry.dart';
import 'package:docs_core/previews/flutter_code_registry.dart';
import 'package:docs_core/shared/chain_axis_table.dart';
import 'package:docs_core/shared/chain_permutations.dart';
import 'package:test/test.dart';

/// T1 저작 규약(AC-2)과 코드 동기(AC-3)를 실측표 기반으로 게이트한다.
///
/// 규약의 요체는 "치환 앵커의 유일성" — 축당 getter 리터럴이 base 전체에서
/// 체인 위치에 정확히 1회. 이를 필드별 grep 이 아니라 **실제 치환 함수의
/// fail-safe** 로 판정한다: `substituteChainTokens` 는 출현 ≠1 이면 원문을
/// 돌려주므로, "비-base 좌표 치환 결과 ≠ 원문" 이 곧 앵커 유일성의 증명이다
/// — 판정기와 런타임이 같은 코드라 가짜 통과가 구조적으로 없다.
///
/// 검사 대상 티어는 예제 확충이 완료된 티어만 켠다 — 티어 batch 가 끝날
/// 때마다 여기 집합에 추가한다.
const _enforcedTiers = {
  ChainTier.t1,
  ChainTier.t2Radius,
  ChainTier.t2Color,
  ChainTier.t3,
};

void main() {
  final entries = kChainAxisTable.where((e) => _enforcedTiers.contains(e.tier) && e.hasDocsExampleDir).toList();

  test('검사 대상이 비어 있지 않다 (게이트 공회전 방지)', () {
    expect(entries, isNotEmpty);
  });

  group('AC-2 — T1 4요소 (combo 앵커 + withStyle full-control)', () {
    for (final entry in kChainAxisTable.where(
      (e) => e.tier == ChainTier.t1 && e.hasDocsExampleDir,
    )) {
      test(entry.component, () {
        for (final (platform, registry) in [
          ('flutter', kFlutterCodeSnippetRegistry),
          ('web', kCodeSnippetRegistry),
        ]) {
          final builder = registry[entry.component];
          expect(
            builder,
            isNotNull,
            reason: '${entry.component}: $platform 코드 registry 미등재',
          );
          final snippet = builder!('chain');
          expect(
            snippet,
            isNot(builder(null)),
            reason:
                '${entry.component}: $platform chain 스니펫이 default 와 '
                '동일 — chain 케이스 부재',
          );

          // (a)(b)(c) — 양축 앵커가 체인 위치에 정확히 1회씩이면 비-base
          // 좌표 치환이 성립한다 (fail-safe 통과 = 앵커 유일성 증명).
          final probe = ChainPermutation(
            radiusIndex: kChainRadiusGetters.indexOf('radius0'),
            colorIndex: kChainColorGetters.indexOf('error'),
          );
          final substituted = substituteChainTokens(snippet, probe);
          expect(
            substituted,
            isNot(snippet),
            reason:
                '${entry.component}: $platform base 의 치환이 fail-safe 로 '
                '원문 반환 — 축당 체인-위치 getter 가 정확히 1회가 아니다 '
                '(누락 또는 중복)',
          );
          expect(substituted, contains('.radius0'));
          expect(substituted, contains('.error'));

          // base 앵커는 표준 좌표(radius16·primary) — step 0 = base 계약.
          expect(
            substituteChainTokens(snippet, kChainBasePermutation),
            snippet,
            reason:
                '${entry.component}: $platform combo 앵커가 '
                '.radius16.primary 표준 좌표가 아니다',
          );

          // (d) — withStyle full-control 인스턴스.
          expect(
            snippet,
            contains('.withStyle('),
            reason: '${entry.component}: $platform withStyle 인스턴스 부재',
          );
        }
      });
    }
  });

  group('AC-2 — T2 단축 (보유 축 getter 조합 + withStyle full-control)', () {
    for (final entry in kChainAxisTable.where(
      (e) => (e.tier == ChainTier.t2Radius || e.tier == ChainTier.t2Color) && e.hasDocsExampleDir,
    )) {
      test(entry.component, () {
        final vocab = entry.tier == ChainTier.t2Radius ? kChainRadiusGetters : kChainColorGetters;
        for (final (platform, registry) in [
          ('flutter', kFlutterCodeSnippetRegistry),
          ('web', kCodeSnippetRegistry),
        ]) {
          final builder = registry[entry.component];
          expect(
            builder,
            isNotNull,
            reason: '${entry.component}: $platform 코드 registry 미등재',
          );
          final snippet = builder!('chain');
          expect(
            snippet,
            isNot(builder(null)),
            reason:
                '${entry.component}: $platform chain 스니펫이 default 와 '
                '동일 — chain 케이스 부재',
          );

          // (a/b) — 보유 축 getter 체인-적용 ≥1 (T2 는 치환 대상이 아니라
          // 정확-1 이 아닌 ≥1 이 계약).
          expect(
            chainAxisAnchorCount(snippet, vocab),
            greaterThanOrEqualTo(1),
            reason: '${entry.component}: $platform 보유 축 getter 체인 부재',
          );

          // (d) — withStyle full-control (getter 와의 조합 체인 = (c)).
          expect(
            snippet,
            contains('.withStyle('),
            reason: '${entry.component}: $platform withStyle 인스턴스 부재',
          );
        }
      });
    }
  });

  group('AC-2 — T3 무축 (withStyle full-control 만)', () {
    for (final entry in kChainAxisTable.where(
      (e) => e.tier == ChainTier.t3 && e.hasDocsExampleDir,
    )) {
      test(entry.component, () {
        for (final (platform, registry) in [
          ('flutter', kFlutterCodeSnippetRegistry),
          ('web', kCodeSnippetRegistry),
        ]) {
          final builder = registry[entry.component];
          expect(
            builder,
            isNotNull,
            reason: '${entry.component}: $platform 코드 registry 미등재',
          );
          final snippet = builder!('chain');
          expect(
            snippet,
            isNot(builder(null)),
            reason:
                '${entry.component}: $platform chain 스니펫이 default 와 '
                '동일 — chain 케이스 부재',
          );

          // (d) — withStyle full-control. T3 는 getter 축이 없다 (getter
          // 사용은 컴파일 자체가 불가하므로 별도 부정 단언은 두지 않는다).
          expect(
            snippet,
            contains('.withStyle('),
            reason: '${entry.component}: $platform withStyle 인스턴스 부재',
          );
        }
      });
    }
  });

  group('AC-3 — _code.dart chain 스니펫 ≡ 예제 클래스 전문', () {
    for (final entry in kChainAxisTable.where(
      (e) => _enforcedTiers.contains(e.tier) && e.hasDocsExampleDir,
    )) {
      test(entry.component, () {
        final dir = entry.component.replaceAll('-', '_');
        for (final (platform, registry) in [
          ('flutter', kFlutterCodeSnippetRegistry),
          ('web', kCodeSnippetRegistry),
        ]) {
          final file = File(
            'lib/previews/examples/$platform/$dir/${dir}_chain_example.dart',
          );
          expect(
            file.existsSync(),
            isTrue,
            reason: '${entry.component}: $platform chain 예제 파일 부재',
          );
          final source = file.readAsStringSync();
          final classStart = source.indexOf(RegExp(r'^class ', multiLine: true));
          expect(classStart, greaterThanOrEqualTo(0));
          final classText = source.substring(classStart).trimRight();

          final snippet = registry[entry.component]!('chain').trimRight();
          expect(
            snippet,
            classText,
            reason:
                '${entry.component}: $platform _code.dart chain 스니펫이 '
                '예제 클래스 전문과 다르다 — 복사용 코드와 렌더가 어긋난다',
          );
        }
      });
    }
  });
}
