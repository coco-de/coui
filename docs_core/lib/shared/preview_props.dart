/// 문서 블록이 미리보기에 넘기는 속성 문자열 — `variant=outline;size=md`.
///
/// 컴포넌트 페이지(v2 템플릿)의 블록은 미리보기를 예제 파일이 아니라
/// **속성**으로 고른다. Variant 행 · 크기 무대 · 형태 카드처럼 "속성만 다른
/// 같은 컴포넌트" 가 페이지 미리보기의 대부분이라, 블록마다 예제 파일을
/// 두 벌(웹 · Flutter) 만들면 페이지 하나에 수십 개가 생긴다. 속성 문자열
/// 하나를 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 같은 파서로 읽어
/// 각자의 빌더에 넘긴다 — 두 표면이 같은 마크다운에서 같은 속성을 읽는다.
library;

/// `key=value;key=value` 를 이름 → 값으로 푼다.
///
/// - 조각은 `;` 로 나눈다. 값 안의 `=` 는 첫 번째 것만 구분자로 본다
///   (`placeholder=a=b` → `a=b`).
/// - 앞뒤 공백은 지운다. 값 없는 조각(`enabled`)은 `true` 로 읽는다 —
///   켜고 끄는 속성을 짧게 쓰게 한다.
/// - 빈 조각은 버린다(`;;`, 끝의 `;`).
Map<String, String> parsePreviewProps(String? raw) {
  if (raw == null) return const {};
  final props = <String, String>{};
  for (final part in raw.split(';')) {
    final piece = part.trim();
    if (piece.isEmpty) continue;
    final eq = piece.indexOf('=');
    if (eq < 0) {
      props[piece] = 'true';
    } else {
      final key = piece.substring(0, eq).trim();
      if (key.isEmpty) continue;
      props[key] = piece.substring(eq + 1).trim();
    }
  }
  return props;
}

/// 속성 하나를 불린으로 읽는다 — `true` / `false` 만, 없으면 [fallback].
bool previewFlag(Map<String, String> props, String key, {bool fallback = false}) {
  return switch (props[key]) {
    'true' => true,
    'false' => false,
    _ => fallback,
  };
}

/// [values] 중 이름이 [name] 인 enum 값 — 없거나 모르는 이름이면 [fallback].
///
/// 문서 한 줄의 오타가 페이지를 깨뜨리지 않게 던지지 않는다. 오타는
/// 문서 테스트(`preview_props_test.dart`)가 콘텐츠를 읽어 잡는다.
T previewEnum<T extends Enum>(List<T> values, String? name, T fallback) {
  if (name == null) return fallback;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
