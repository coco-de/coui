/// 플레이그라운드의 컨트롤 정의와 코드 생성 — 순수 Dart.
///
/// 컨트롤은 속성 문자열(`preview_props.dart`)을 바꾸는 손잡이다. 미리보기는
/// 그 속성을 프롭 빌더(`web_prop_previews.dart` · `flutter_prop_previews.dart`)
/// 에 넘겨 그리고, 코드는 같은 속성에서 만든다. 그래서 화면 · 코드 · 두
/// 플랫폼이 한 속성 묶음에서 나온다.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 이 파일을 함께 읽는다.
library;

export '../pages/page_registry.g.dart' show kDocsPlaygrounds;

/// Flutter 임베드에 넘기는 변형 이름 — 이 이름이면 미리보기 앱이 속성을
/// 플레이그라운드 스토어(`playground_store.dart`)에서 읽는다.
const String kPlaygroundVariant = 'playground';

/// 컨트롤 하나.
sealed class DocsPlaygroundControl {
  const DocsPlaygroundControl({required this.label});

  /// 컨트롤 옆에 적는 이름.
  final String label;
}

/// 값 하나를 고르는 컨트롤 — 속성 [prop] 에 고른 값을 쓴다.
final class DocsPlaygroundChoice extends DocsPlaygroundControl {
  const DocsPlaygroundChoice({
    required super.label,
    required this.prop,
    required this.options,
    this.segmented = false,
  });

  /// 바꾸는 속성 이름.
  final String prop;

  /// 고를 수 있는 값 — 위젯 enum 의 이름.
  final List<String> options;

  /// true 면 칸을 나란히 놓고, false 면 펼침 목록으로 고른다.
  final bool segmented;
}

/// 켜고 끄는 컨트롤 — 켜면 [on] 의 속성을 얹고, 끄면 그 속성을 뺀다.
final class DocsPlaygroundFlag extends DocsPlaygroundControl {
  const DocsPlaygroundFlag({required super.label, required this.on});

  /// 켰을 때의 속성.
  final Map<String, String> on;

  /// 지금 속성에서 켜져 있는가.
  bool isOn(Map<String, String> props) => on.entries.every((e) => props[e.key] == e.value);

  /// 켜거나 끈 속성.
  Map<String, String> apply(Map<String, String> props, {required bool value}) => {
    for (final entry in props.entries)
      if (!on.containsKey(entry.key)) entry.key: entry.value,
    if (value) ...on,
  };
}

/// 컴포넌트 하나의 플레이그라운드.
class DocsPlaygroundSpec {
  const DocsPlaygroundSpec({
    required this.initial,
    required this.controls,
    required this.code,
    this.webCode,
    this.label,
  });

  /// 처음 속성.
  final Map<String, String> initial;

  /// 컨트롤 — 위에서 아래 순서.
  final List<DocsPlaygroundControl> controls;

  /// 미리보기의 본문 글자(버튼 라벨 같은).
  final String? label;

  /// 속성 → 코드. 두 플랫폼의 API 가 같으므로 보통 이것 하나가 두 플랫폼의
  /// 코드다 — [webCode] 가 없으면 Web 도 이 코드를 보인다.
  final String Function(Map<String, String> props, String? label) code;

  /// 속성 → Web 코드. Web 의 코드가 Flutter 와 다를 때만 둔다.
  ///
  /// 컴포넌트의 API 는 같아도 둘레의 코드가 다른 경우다 — 레이아웃 부품은
  /// 부모가 Flutter 에서는 `Row` · `Column`, Web 에서는 flex `div` 이고, Web
  /// 에만 있는 클래스 · 속성을 보여야 하는 컴포넌트도 있다. 한 스니펫에 두
  /// 플랫폼을 이어 적으면 복사한 코드가 어느 쪽에서도 그대로 컴파일되지 않는다.
  final String Function(Map<String, String> props, String? label)? webCode;

  /// [platform] 에서 보일 코드.
  String codeFor(DocsCodePlatform platform, Map<String, String> props, String? label) => switch (platform) {
    DocsCodePlatform.web => (webCode ?? code)(props, label),
    DocsCodePlatform.flutter => code(props, label),
  };

  /// 두 플랫폼의 코드가 다른가 — 다르면 두 플랫폼을 함께 볼 때 코드를 둘로 보인다.
  bool get codeDiffersByPlatform => webCode != null;
}

/// 플레이그라운드 코드의 플랫폼.
enum DocsCodePlatform {
  /// Flutter.
  flutter('Flutter'),

  /// Jaspr Web.
  web('Jaspr Web');

  const DocsCodePlatform(this.label);

  /// 코드 상자 제목.
  final String label;
}

/// Lucide kebab-case → Dart 식별자 (`arrow-right` → `arrowRight`).
String docsIconIdentifier(String name) {
  final parts = name.split('-');
  return parts.first + [for (final p in parts.skip(1)) p.isEmpty ? p : p[0].toUpperCase() + p.substring(1)].join();
}
