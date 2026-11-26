@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/previews/web_chain_registry.dart';
import 'package:docs_core/shared/chain_permutations.dart';
import 'package:docs_core/shared/chain_tier1.dart';
import 'package:test/test.dart';

/// 순열 렌더러 registry 의 생성물-간 drift 를 게이트한다.
///
/// tier1 name-set 과 registry 2종은 같은 생성기 실행에서 나오지만 별개
/// 파일이라, 한쪽만 손편집·재생성되면 조용히 갈라진다 — SSG 는 name-set
/// 으로 버튼을 그리는데 registry 에 렌더러가 없으면 클릭이 조용히 base
/// 만 남는 반쪽 동작이 된다. Flutter registry 는 `dart:ui` 를 나르므로
/// VM 테스트가 import 할 수 없어 **소스 파싱**으로 키를 대조한다 (Web 은
/// jaspr 가 서버 VM 에서 컴파일되므로 직접 import).
void main() {
  Set<String> registryKeysOf(String path) {
    final source = File(path).readAsStringSync();
    final mapBody = source.substring(source.indexOf('ChainRegistry = {'));
    return RegExp(r"'([a-z0-9-]+)':").allMatches(mapBody).map((m) => m.group(1)!).toSet();
  }

  test('Flutter registry 키 ≡ tier1 name-set', () {
    expect(
      registryKeysOf('lib/previews/flutter_chain_registry.dart'),
      kChainTier1Components,
      reason: '생성물이 갈라졌다 — generate_chain_artifacts --write 로 재생성',
    );
  });

  test('Web registry 키 ≡ tier1 name-set (import + 소스 이중 확인)', () {
    expect(kWebChainRegistry.keys.toSet(), kChainTier1Components);
    expect(
      registryKeysOf('lib/previews/web_chain_registry.dart'),
      kChainTier1Components,
    );
  });

  test('Web 렌더러 스모크 — 대표 좌표에서 전 T1 구성 무예외', () {
    // 구성(위젯 트리 객체 생성)만으로도 축 분해 switch·getter 참조가 전부
    // 실행된다 — 존재하지 않는 getter 를 참조하면 여기서 던진다.
    final probes = [
      kChainBasePermutation,
      chainPermutationAt(1),
      chainPermutationAt(104),
      chainPermutationAt(208),
    ];
    for (final entry in kWebChainRegistry.entries) {
      for (final permutation in probes) {
        expect(
          entry.value(permutation),
          isNotNull,
          reason: '${entry.key} @ $permutation',
        );
      }
    }
  });

  test('docs_core 서버 경로는 Flutter chain registry 를 import 하지 않는다', () {
    // Flutter registry 는 dart:ui 를 나른다 — docs_core 안에서 이것을
    // import 하는 파일이 생기면 SSG(서버) 빌드가 깨진다. 유일한 소비자는
    // docs_site 의 임베드 위젯(web-only 컴파일 경로)이다.
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.endsWith('flutter_chain_registry.dart')) continue;
      if (file.readAsStringSync().contains('flutter_chain_registry.dart')) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty);
  });
}
