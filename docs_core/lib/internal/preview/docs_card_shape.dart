/// 문서 카드의 모양 이름 — 사이트(`web_card_view.dart`)와 앱
/// (`flutter_card_view.dart`)이 같이 읽는다.
///
/// 이 파일은 플랫폼을 모른다. 같은 이름이 두 곳에 적히면 한쪽만 바뀌는 날
/// 같은 마크다운이 두 표면에서 다른 카드로 그려진다.
library;

/// 한 줄에 놓는 카드 수의 범위 — `<Cards columns>`.
const int kDocsCardsMinColumns = 1;

/// 한 줄에 놓는 카드 수의 상한.
const int kDocsCardsMaxColumns = 4;

/// 카드 묶음이 받는 모양의 이름 — `<Cards variant>` 와 `<Card variant>`.
///
/// 면 카드(`filled`)는 페이지의 첫 줄을 이끄는 카드, 선 카드(`outlined`)는
/// 묶음 안의 이름과 짧은 목록이다.
const Set<String> kDocsCardVariants = {'filled', 'outlined'};

/// 모양을 적지 않은 카드의 모양.
const String kDocsCardDefaultVariant = 'filled';

/// 적힌 모양이 아는 이름이면 그것, 아니면 [fallback].
///
/// 모르는 이름은 버린다 — 오타 하나가 카드의 모양을 비우지 않게.
String docsCardVariant(String? asked, {String fallback = kDocsCardDefaultVariant}) =>
    kDocsCardVariants.contains(asked?.trim()) ? asked!.trim() : fallback;

/// 카드 한 장의 모양 — 묶음이 정한 [groupVariant] 위에 카드가 적은 `variant` 가 이긴다.
String docsCardShape(Map<String, String> attributes, {String? groupVariant}) =>
    docsCardVariant(attributes['variant'], fallback: docsCardVariant(groupVariant));
