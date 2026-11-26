/// panelId → 셔플 step 스토어 — chain 랜덤 토글의 **단일 상태 출처**.
///
/// framework-free 자체 Listenable 이다: jaspr 도 Flutter 도 import 하지
/// 않고, 버튼 아일랜드(jaspr `@client`)와 Flutter 임베드(`PreviewApp`)가
/// **같은 Dart 힙**에서 같은 인스턴스([chainShuffleStore])를 구독한다 —
/// DOM attribute·폴링 경유 없는 스토어 직결 채널의 몸통.
///
/// **서버 경로 read-only**: jaspr 는 SSG 중에도 컴포넌트 `initState` 를
/// 실행하므로, 가드 없이는 정적 빌드가 리스너를 계속 누적한다. 쓰기
/// (`advance`)와 리스너 등록은 클라이언트 런타임에서만 동작하고 서버
/// 경로에서는 no-op 이다 — SSG 산출물은 언제나 step 0(base) 을 그린다.
library;

/// 상호작용 런타임에서 true — dart2js/wasm(브라우저 클라이언트) **또는**
/// Flutter(`dart.library.ui` — 네이티브 docs_app·Flutter 임베드). jaspr SSG
/// 서버와 pure-VM 테스트는 둘 다 없어 false 로 남는다 (read-only 계약 유지).
/// `js_interop` 하나만 보면 네이티브 docs_app 이 서버로 오판되어 셔플이
/// 조용히 no-op 이 된다.
const bool _kIsClientRuntime =
    bool.fromEnvironment('dart.library.js_interop') || bool.fromEnvironment('dart.library.ui');

/// chain 프리뷰 패널별 셔플 step 을 보유·통지하는 스토어.
///
/// step 의 의미(어느 순열인가)는 스토어가 모른다 — 좌표 해석은
/// `chain_permutations.dart` 의 `chainPermutationAt(step)` 몫이고, 여기는
/// panelId 스코프의 정수 카운터와 리스너만 산다 (역할 분리).
class ChainShuffleStore {
  /// [isClientRuntime] 은 테스트 전용 오버라이드 — VM 테스트가 클라이언트
  /// 동작(리스너 발화)을 검증할 수 있게 한다. 프로덕션 호출부는 넘기지
  /// 않는다 (컴파일 환경이 결정).
  ChainShuffleStore({bool? isClientRuntime}) : _isClientRuntime = isClientRuntime ?? _kIsClientRuntime;

  final bool _isClientRuntime;
  final Map<String, int> _steps = {};
  final Map<String, List<void Function()>> _listeners = {};

  /// [panelId] 의 현재 step — 미초기화면 0 (= base 순열, throw 0).
  int stepOf(String panelId) => _steps[panelId] ?? 0;

  /// [panelId] 의 step 을 1 전진시키고 그 패널의 리스너에게 통지한다.
  ///
  /// 클라이언트 전용 — 서버 경로에서는 no-op (read-only 계약). 다른
  /// 패널의 리스너는 통지받지 않는다 (per-panel 격리, REQ-B7 의 역).
  void advance(String panelId) {
    if (!_isClientRuntime) return;
    _steps[panelId] = stepOf(panelId) + 1;
    // 통지 중 리스너가 자신을 제거해도 순회가 깨지지 않도록 복사본 순회.
    for (final listener in [...?_listeners[panelId]]) {
      listener();
    }
  }

  /// [panelId] 의 step 을 [step] 으로 복원하고 리스너에게 통지한다 —
  /// 순열 딥링크(URL 쿼리)가 하이드레이션 시점에 부른다.
  ///
  /// [advance] 와 같은 클라이언트 전용 쓰기다 (서버 경로 no-op). 음수는
  /// 무시한다 — step 은 전진 카운터라 음수 상태가 존재하지 않고, 잘못된
  /// 딥링크가 base(0) 아래로 내려가게 두지 않는다.
  void restore(String panelId, int step) {
    if (!_isClientRuntime || step < 0) return;
    _steps[panelId] = step;
    for (final listener in [...?_listeners[panelId]]) {
      listener();
    }
  }

  /// [panelId] 의 step 변경 리스너를 등록한다 — 서버 경로에서는 no-op.
  void addListener(String panelId, void Function() listener) {
    if (!_isClientRuntime) return;
    (_listeners[panelId] ??= []).add(listener);
  }

  /// [listener] 를 해제한다. 등록과 대칭으로 서버 경로 no-op.
  void removeListener(String panelId, void Function() listener) {
    if (!_isClientRuntime) return;
    final list = _listeners[panelId];
    if (list == null) return;
    list.remove(listener);
    if (list.isEmpty) _listeners.remove(panelId);
  }
}

/// 전역 스토어 — 아일랜드와 임베드가 같은 힙에서 공유하는 인스턴스.
final ChainShuffleStore chainShuffleStore = ChainShuffleStore();
