/// panelId → 플레이그라운드 속성 스토어 — 컨트롤과 두 미리보기의 단일 상태 출처.
///
/// `chain_shuffle_store.dart` 와 같은 모양이다: jaspr 도 Flutter 도 import
/// 하지 않는 자체 리스너 목록이고, 컨트롤 아일랜드(jaspr `@client`)와
/// Flutter 임베드(`PreviewApp`)가 **같은 Dart 힙**에서 같은 인스턴스를
/// 구독한다. 그래서 컨트롤을 바꾸면 Flutter 미리보기가 DOM 을 거치지 않고
/// 같은 속성으로 다시 그린다.
///
/// 서버 경로(SSG · VM 테스트)에서는 쓰기와 리스너 등록이 no-op 이다 —
/// 정적 빌드가 리스너를 쌓지 않는다.
library;

const bool _kIsClientRuntime =
    bool.fromEnvironment('dart.library.js_interop') || bool.fromEnvironment('dart.library.ui');

/// 플레이그라운드 패널별 속성을 보유 · 통지한다.
class PlaygroundStore {
  /// [isClientRuntime] 은 테스트 전용 오버라이드다.
  PlaygroundStore({bool? isClientRuntime}) : _isClientRuntime = isClientRuntime ?? _kIsClientRuntime;

  final bool _isClientRuntime;
  final Map<String, Map<String, String>> _props = {};
  final Map<String, List<void Function()>> _listeners = {};

  /// [panelId] 의 현재 속성. 아직 쓰인 적이 없으면 null.
  Map<String, String>? propsOf(String panelId) => _props[panelId];

  /// [panelId] 의 속성을 바꾸고 그 패널의 리스너에게 알린다.
  void set(String panelId, Map<String, String> props) {
    if (!_isClientRuntime) return;
    _props[panelId] = Map.unmodifiable(props);
    for (final listener in [...?_listeners[panelId]]) {
      listener();
    }
  }

  /// 리스너를 등록한다.
  void addListener(String panelId, void Function() listener) {
    if (!_isClientRuntime) return;
    (_listeners[panelId] ??= []).add(listener);
  }

  /// 리스너를 해제한다.
  void removeListener(String panelId, void Function() listener) {
    if (!_isClientRuntime) return;
    final list = _listeners[panelId];
    if (list == null) return;
    list.remove(listener);
    if (list.isEmpty) _listeners.remove(panelId);
  }
}

/// 아일랜드와 임베드가 함께 쓰는 인스턴스.
final PlaygroundStore playgroundStore = PlaygroundStore();
