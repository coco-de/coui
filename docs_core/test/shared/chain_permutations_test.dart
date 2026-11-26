@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/shared/chain_axis_table.dart';
import 'package:docs_core/shared/chain_permutations.dart';
import 'package:test/test.dart';

/// 순열 모듈의 세 계약을 게이트로 강제한다: (1) 어휘 상수가 실측표의
/// 실제 getter 표면과 1:1 — 존재하지 않는 이름은 좌표가 가리킬 수 없다,
/// (2) 시퀀스 결정성·전 조합 순회·base 복귀, (3) 치환의
/// identifier-boundary 매칭과 fail-safe — 충돌쌍(radius4↔radius40,
/// surface↔surfaceContainer 류)은 의무 케이스다.
void main() {
  group('어휘 — 실측표 1:1 (AC-7)', () {
    test('radius 19 · 색 11 — T1 primary 표면과 이름·순서까지 일치', () {
      expect(kChainRadiusGetters, hasLength(19));
      expect(kChainColorGetters, hasLength(11));

      final tier1 = kChainAxisTable.where((e) => e.tier == ChainTier.t1);
      expect(tier1, isNotEmpty);
      for (final entry in tier1) {
        for (final targets in [entry.flutterTargets, entry.webTargets]) {
          final primary = targets.firstWhere(
            (t) => t.target == entry.primaryTarget,
          );
          // radius 는 실측표도 scale 순으로 기록되므로 순서까지 동일해야
          // 한다 — 순서가 갈리면 인덱스 좌표가 다른 토큰을 가리킨다.
          expect(
            primary.radiusGetters,
            kChainRadiusGetters,
            reason: '${entry.component} ${primary.target}: radius 어휘 불일치',
          );
          // 색은 실측표가 사전순, 어휘는 시맨틱 순 — 집합 동일성이 계약.
          expect(
            primary.colorGetters.toSet(),
            kChainColorGetters.toSet(),
            reason: '${entry.component} ${primary.target}: 색 어휘 불일치',
          );
        }
      }
    });

    test('base 순열 좌표는 radius16·primary 를 가리킨다', () {
      expect(
        kChainRadiusGetters[kChainBasePermutation.radiusIndex],
        'radius16',
      );
      expect(kChainColorGetters[kChainBasePermutation.colorIndex], 'primary');
    });

    test('전 조합 수는 19×11', () {
      expect(
        kChainPermutationCount,
        kChainRadiusGetters.length * kChainColorGetters.length,
      );
    });

    test('좌표 라벨은 실재 getter 이름 그대로 (.radius16.primary)', () {
      // jaspr 칩·네이티브 칩·SR 통보가 공유하는 단일 표기 — 사본이 아니라
      // 이 헬퍼 하나에서 파생돼야 두 UI 의 표기가 갈라질 수 없다.
      expect(chainPermutationLabel(kChainBasePermutation), '.radius16.primary');
      expect(
        chainPermutationLabel(
          const ChainPermutation(radiusIndex: 0, colorIndex: 10),
        ),
        '.${kChainRadiusGetters[0]}.${kChainColorGetters[10]}',
      );
    });
  });

  group('시퀀스 — 결정성·순회 (AC-6, BDD Feature C)', () {
    test('같은 seed·같은 step 은 같은 좌표다', () {
      for (final step in [0, 1, 7, 42, 208, 209, 1000]) {
        expect(chainPermutationAt(step), chainPermutationAt(step));
      }
      // 명시 seed 경로(캐시 밖)도 동일해야 한다.
      expect(
        chainPermutationAt(5, seed: 1234),
        chainPermutationAt(5, seed: 1234),
      );
    });

    test('step 0 = base 순열 (클릭 전 = 기본)', () {
      expect(chainPermutationAt(0), kChainBasePermutation);
    });

    test('209회 전진은 전 조합을 무중복 순회하고 base 로 복귀한다', () {
      final visited = <ChainPermutation>{};
      for (var step = 1; step <= kChainPermutationCount; step++) {
        visited.add(chainPermutationAt(step));
      }
      expect(visited, hasLength(kChainPermutationCount), reason: '중복 발생');
      expect(
        chainPermutationAt(kChainPermutationCount),
        kChainBasePermutation,
        reason: '209번째 전진은 base 복귀여야 한다 (순환)',
      );
    });

    test('210번째 좌표는 첫 좌표와 같다 (순환 반복)', () {
      expect(chainPermutationAt(210), chainPermutationAt(1));
    });

    test('모든 step 의 좌표가 어휘 범위 안이다 — throw 0', () {
      for (var step = -3; step < 430; step++) {
        expect(chainPermutationAt(step).isInRange, isTrue, reason: 'step $step');
      }
    });
  });

  group('치환 — boundary 매칭·fail-safe (AC-7, BDD Feature C)', () {
    const base = '''
Button(
  variant: CoreButtonVariant.primary,
  onPressed: () {},
  child: Text('Primary'),
).radius16.primary;
''';

    ChainPermutation at(String radius, String color) => ChainPermutation(
      radiusIndex: kChainRadiusGetters.indexOf(radius),
      colorIndex: kChainColorGetters.indexOf(color),
    );

    test('base 좌표 치환은 문자열 항등이다', () {
      expect(substituteChainTokens(base, kChainBasePermutation), base);
    });

    test('좌표의 이름으로 양축이 교체된다 — 체인 위치만', () {
      final result = substituteChainTokens(base, at('radius9999', 'success'));
      expect(result, contains('.radius9999.success'));
      expect(result, isNot(contains('.radius16.primary')));
      expect(
        result,
        contains('CoreButtonVariant.primary'),
        reason: 'enum 멤버 접근은 무변경',
      );
    });

    test('전 209 조합의 산출 getter 가 전부 어휘에 존재한다', () {
      final vocabulary = {...kChainRadiusGetters, ...kChainColorGetters};
      for (var step = 0; step < kChainPermutationCount; step++) {
        final permutation = chainPermutationAt(step);
        final result = substituteChainTokens(base, permutation);
        final chained = RegExp(
          r'\.(\w+)',
        ).allMatches(result).map((m) => m.group(1)!);
        for (final name in chained.where(vocabulary.contains)) {
          expect(vocabulary, contains(name));
        }
        // 좌표가 가리킨 두 이름이 실제로 결과에 들어갔는지도 본다.
        expect(
          result,
          contains('.${kChainRadiusGetters[permutation.radiusIndex]}'),
        );
        expect(
          result,
          contains('.${kChainColorGetters[permutation.colorIndex]}'),
        );
      }
    });

    group('충돌쌍 의무 케이스', () {
      test('radius4 ↔ radius40 — 접두 이름이 긴 이름 안에서 안 매칭된다', () {
        final base4 = base.replaceFirst('.radius16', '.radius4');
        final to40 = substituteChainTokens(base4, at('radius40', 'primary'));
        expect(to40, contains('.radius40'));
        expect(to40, isNot(contains('.radius4.')));

        final base40 = base.replaceFirst('.radius16', '.radius40');
        final to4 = substituteChainTokens(base40, at('radius4', 'primary'));
        expect(to4, contains('.radius4.'));
        expect(to4, isNot(contains('.radius40')));
      });

      test('radius2 ↔ radius20/24/28', () {
        for (final long in ['radius20', 'radius24', 'radius28']) {
          final baseLong = base.replaceFirst('.radius16', '.$long');
          final result = substituteChainTokens(
            baseLong,
            at('radius2', 'primary'),
          );
          expect(result, contains('.radius2.'));
          expect(result, isNot(contains('.$long')));
        }
      });

      test('radius6 ↔ radius64', () {
        final base64 = base.replaceFirst('.radius16', '.radius64');
        final result = substituteChainTokens(base64, at('radius6', 'primary'));
        expect(result, contains('.radius6.'));
        expect(result, isNot(contains('.radius64')));
      });

      test('surface ↔ surfaceContainer', () {
        final baseSc = base.replaceFirst(
          '.radius16.primary;',
          '.radius16.surfaceContainer;',
        );
        final toSurface = substituteChainTokens(
          baseSc,
          at('radius16', 'surface'),
        );
        expect(toSurface, contains('.radius16.surface;'));
        expect(toSurface, isNot(contains('.surfaceContainer')));

        final baseS = base.replaceFirst(
          '.radius16.primary;',
          '.radius16.surface;',
        );
        final toContainer = substituteChainTokens(
          baseS,
          at('radius16', 'surfaceContainer'),
        );
        expect(toContainer, contains('.radius16.surfaceContainer;'));
      });
    });

    group('fail-safe — 원문 반환 (부분 치환 0)', () {
      test('축 출현 0 이면 원문', () {
        const noRadius = "Button(child: Text('x')).primary;";
        final result = substituteChainTokens(
          noRadius,
          at('radius4', 'success'),
        );
        expect(result, noRadius);
      });

      test('서로 다른 chain 적용 2회면 원문', () {
        final doubled =
            '$base\nBadge(child: Text('
            "'x')).radius16.success;";
        expect(
          substituteChainTokens(doubled, at('radius4', 'warning')),
          doubled,
        );
      });

      test('서로 다른 getter 2개도 축 출현 2 로 센다', () {
        final two = base.replaceFirst(
          '.radius16.primary;',
          '.radius16.radius8.primary;',
        );
        expect(substituteChainTokens(two, at('radius4', 'success')), two);
      });

      test('범위 밖 좌표면 원문', () {
        const outOfRange = ChainPermutation(radiusIndex: 19, colorIndex: 0);
        expect(substituteChainTokens(base, outOfRange), base);
        const negative = ChainPermutation(radiusIndex: -1, colorIndex: 0);
        expect(substituteChainTokens(base, negative), base);
      });
    });

    group('receiver-위치 판별 — 값-위치 동명 심볼은 앵커가 아니다', () {
      test('enum 멤버 접근(CoreButtonVariant.primary)은 세지 않는다', () {
        // base 자체가 `variant: CoreButtonVariant.primary` 를 담고 있는데도
        // 색 축 출현은 체인의 `.primary` 1회다 — 치환이 성립한다.
        final result = substituteChainTokens(base, at('radius8', 'info'));
        expect(result, contains('.radius8.info'));
        expect(result, contains('CoreButtonVariant.primary'), reason: 'enum 멤버는 무변경');
      });

      test('값-위치 토큰 상수(CoreRadius.radius16)는 세지도 바꾸지도 않는다', () {
        final withInstance =
            '$base\nfinal styled = button.withStyle(CoreButtonStyle('
            'borderRadius: CoreBorderRadius.all(CoreRadius.radius16)));';
        final result = substituteChainTokens(
          withInstance,
          at('radius4', 'success'),
        );
        expect(result, contains('.radius4.success'));
        expect(
          result,
          contains('CoreRadius.radius16'),
          reason: 'withStyle 인스턴스의 값-위치 토큰은 무변경',
        );
      });

      test('dot shorthand(variant: .primary)는 세지 않는다', () {
        final shorthand = base.replaceFirst(
          'CoreButtonVariant.primary',
          '.primary',
        );
        final result = substituteChainTokens(shorthand, at('radius8', 'info'));
        expect(result, contains('.radius8.info'));
        expect(
          result,
          contains('variant: .primary'),
          reason: 'shorthand 값-위치는 무변경',
        );
      });

      test('여러 줄로 꺾인 체인도 매칭된다 (dart format 대응)', () {
        const multiline = '''
Button(
  onPressed: () {},
  child: Text('Primary'),
)
    .radius16
    .primary;
''';
        final result = substituteChainTokens(
          multiline,
          at('radius9999', 'outline'),
        );
        expect(result, contains('.radius9999'));
        expect(result, contains('.outline'));
        expect(result, isNot(contains('.radius16')));
      });
    });
  });

  group('chainAxisAnchorCount — 체인-적용 출현 계수', () {
    test('치환 매칭과 같은 판별을 쓴다 (값-위치 배제·boundary)', () {
      const snippet = '''
Button(variant: CoreButtonVariant.primary).radius16.primary;
CoreRadius.radius16; // 값-위치 — 세지 않음
final x = Badge(child: y).radius40;
''';
      expect(chainAxisAnchorCount(snippet, kChainRadiusGetters), 2);
      expect(chainAxisAnchorCount(snippet, kChainColorGetters), 1);
      expect(chainAxisAnchorCount('no chains here', kChainRadiusGetters), 0);
    });
  });

  test('모듈 소스의 import 그래프에 jaspr/Flutter 0 (AC-11)', () {
    for (final path in [
      'lib/shared/chain_permutations.dart',
      'lib/shared/chain_shuffle_store.dart',
    ]) {
      final source = File(path).readAsStringSync();
      final imports = RegExp(
        r'^\s*import\s+(.+);',
        multiLine: true,
      ).allMatches(source).map((m) => m.group(1)!);
      for (final import in imports) {
        expect(
          import,
          isNot(
            anyOf(
              contains('jaspr'),
              contains('coui_flutter'),
              contains('coui_web'),
              contains('flutter'),
              contains('dart:ui'),
              contains('dart:html'),
            ),
          ),
          reason: '$path: 순수 Dart 요건 위반 import — $import',
        );
      }
    }
  });
}
