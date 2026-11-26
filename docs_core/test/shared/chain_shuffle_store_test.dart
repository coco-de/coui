@TestOn('vm')
library;

import 'package:docs_core/shared/chain_shuffle_store.dart';
import 'package:test/test.dart';

/// 셔플 스토어의 두 계약을 게이트로 강제한다: (1) per-panel 격리 —
/// 한 패널의 전진이 다른 패널의 상태·리스너에 닿으면 복수 chain 패널
/// 페이지에서 코드 표면만 어긋나는 REQ-B7 위반이 된다, (2) 서버 경로
/// no-op — jaspr 는 SSG 중에도 initState 를 실행하므로 가드가 없으면
/// 정적 빌드가 리스너를 누적한다.
void main() {
  group('클라이언트 런타임 (오버라이드)', () {
    late ChainShuffleStore store;

    setUp(() {
      store = ChainShuffleStore(isClientRuntime: true);
    });

    test('미초기화 패널의 step 은 0 (base)', () {
      expect(store.stepOf('chain-button-1'), 0);
    });

    test('advance 는 step 을 전진시키고 리스너에게 통지한다', () {
      var notified = 0;
      store.addListener('chain-button-1', () => notified++);

      store.advance('chain-button-1');
      expect(store.stepOf('chain-button-1'), 1);
      expect(notified, 1);

      store.advance('chain-button-1');
      expect(store.stepOf('chain-button-1'), 2);
      expect(notified, 2);
    });

    test('per-panel 격리 — 다른 패널의 상태·리스너에 무영향', () {
      var panel1 = 0;
      var panel2 = 0;
      store.addListener('chain-button-1', () => panel1++);
      store.addListener('chain-button-2', () => panel2++);

      store.advance('chain-button-1');

      expect(store.stepOf('chain-button-1'), 1);
      expect(store.stepOf('chain-button-2'), 0);
      expect(panel1, 1);
      expect(panel2, 0);
    });

    test('removeListener 이후 통지가 오지 않는다', () {
      var notified = 0;
      void listener() => notified++;
      store.addListener('chain-button-1', listener);
      store.removeListener('chain-button-1', listener);

      store.advance('chain-button-1');
      expect(notified, 0);
      expect(store.stepOf('chain-button-1'), 1, reason: 'step 은 전진한다');
    });

    test('통지 중 자기 해제 리스너가 순회를 깨지 않는다', () {
      var first = 0;
      var second = 0;
      late void Function() selfRemoving;
      selfRemoving = () {
        first++;
        store.removeListener('chain-button-1', selfRemoving);
      };
      store.addListener('chain-button-1', selfRemoving);
      store.addListener('chain-button-1', () => second++);

      store.advance('chain-button-1');
      expect(first, 1);
      expect(second, 1, reason: '자기 해제 뒤 리스너도 통지받는다');

      store.advance('chain-button-1');
      expect(first, 1, reason: '해제된 리스너는 재통지되지 않는다');
      expect(second, 2);
    });
  });

  group('restore — 순열 딥링크 복원', () {
    test('step 을 그 값으로 놓고 리스너에게 통지한다', () {
      final store = ChainShuffleStore(isClientRuntime: true);
      var notified = 0;
      store.addListener('chain-button-1', () => notified++);

      store.restore('chain-button-1', 42);

      expect(store.stepOf('chain-button-1'), 42);
      expect(notified, 1);
      // 복원 후 advance 는 그 지점에서 이어진다 — 딥링크로 온 사용자가
      // 셔플을 계속 누르면 시퀀스가 그 좌표 다음으로 흐른다.
      store.advance('chain-button-1');
      expect(store.stepOf('chain-button-1'), 43);
    });

    test('음수는 무시한다 — 전진 카운터에 음수 상태는 없다', () {
      final store = ChainShuffleStore(isClientRuntime: true);
      store.restore('chain-button-1', -3);
      expect(store.stepOf('chain-button-1'), 0);
    });
  });

  group('서버 경로 (오버라이드 false = 비클라이언트)', () {
    // 기본 생성자의 모드는 컴파일 환경이 정한다 — pure `dart test` 에서는
    // 서버 경로지만 `flutter test`(dart:ui 존재) 에서는 클라이언트라, 여기서
    // 기본 생성자로 서버 경로를 단언하면 테스트가 스토어가 아니라 **하네스**
    // 를 단언하게 된다 (CI 는 docs_core 를 flutter test 로 돌린다). 서버
    // 동작 자체는 오버라이드로 결정적으로 고정해 검증한다 — 실환경 매핑
    // (jaspr SSG = pure VM = 서버 / 네이티브·브라우저 = 클라이언트)은
    // 가드 상수의 컴파일 환경 판정 몫이다.
    test('advance 와 리스너 등록이 no-op 이다 — read-only 계약', () {
      final server = ChainShuffleStore(isClientRuntime: false);
      var notified = 0;
      server.addListener('chain-button-1', () => notified++);

      server.advance('chain-button-1');

      expect(server.stepOf('chain-button-1'), 0);
      expect(notified, 0);
    });

    test('restore 도 서버 경로 no-op 이다 — 딥링크는 클라이언트 전용', () {
      final server = ChainShuffleStore(isClientRuntime: false);
      server.restore('chain-button-1', 42);
      expect(server.stepOf('chain-button-1'), 0);
    });
  });
}
