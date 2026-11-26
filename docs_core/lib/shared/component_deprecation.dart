/// 컴포넌트의 `@Deprecated` 상태 — 소스에서 파싱된 값, 손으로 관리하지
/// 않는다.
///
/// `docs_core/tool/gen_deprecation_status.dart` 가 [parseClassDeprecation] 을
/// 위젯 소스에 돌려 상태를 계산하고 `component_deprecation_status.g.dart` 에
/// 굽는다. 이 파일은 파싱 로직만 갖고 파일시스템은 만지지 않는다 — 그래서
/// `component_catalog.dart` 와 마찬가지로 jaspr 도 Flutter 도 import 하지
/// 않아, docs_site 와 docs_app 양쪽 런타임에서 import 안전하다.
library;

/// 한 컴포넌트의 파싱된 deprecation 상태.
class DocsDeprecationStatus {
  /// 상태를 만든다.
  const DocsDeprecationStatus({
    required this.since,
    required this.message,
    this.replacementSlug,
    this.replacementName,
  });

  /// `since X.Y` 에서 뽑은 버전 (예: `'0.128'`).
  final String since;

  /// `@Deprecated(...)` 의 원문 메시지 — 사이드바/그리드가 tooltip 이나
  /// 컴포넌트 페이지 배너에서 전체 이유를 보여줄 때 쓴다.
  final String message;

  /// 대체 컴포넌트의 카탈로그 슬러그.
  ///
  /// 메시지에서 뽑은 이름을 카탈로그 엔트리 이름과 대조해 찾았을 때만
  /// 채워진다. 대체가 없거나(순수 제거) 대체가 카탈로그 밖의 것을 가리키면
  /// null — 이 경우 [replacementName] 이 원문 힌트로 남는다.
  final String? replacementSlug;

  /// 메시지에서 뽑은 원문 대체 이름(예: `'NewWidget'`).
  ///
  /// [replacementSlug] 해석에 실패해도 사람이 읽을 힌트로 남는다.
  final String? replacementName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocsDeprecationStatus &&
          other.since == since &&
          other.message == message &&
          other.replacementSlug == replacementSlug &&
          other.replacementName == replacementName);

  @override
  int get hashCode => Object.hash(since, message, replacementSlug, replacementName);

  @override
  String toString() =>
      'DocsDeprecationStatus(since: $since, replacementSlug: $replacementSlug, '
      'replacementName: $replacementName)';
}

final RegExp _sinceExp = RegExp(r'since\s+(\d+\.\d+)');
final RegExp _replacementNameExp = RegExp(r'\bUse\s+([A-Z][A-Za-z0-9_]*)');

/// 인접한 문자열 리터럴 연결(`'a ' 'b'`)의 각 조각을 잡는다 — 홑/겹 따옴표
/// 둘 다.
final RegExp _quotedLiteralExp = RegExp(
  r'''(?:'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)")''',
);

/// [source] 안에서 `class $className` 선언 바로 앞의 `@Deprecated(...)`
/// 어노테이션을 찾아 파싱한다. 클래스가 없거나 deprecated 가 아니거나
/// `since X.Y` 를 못 찾으면 null.
///
/// 정규식 + 괄호 균형 스캔 기반이라 완벽하지 않다 — 애매하면 null 을
/// 돌려주는 쪽으로 기운다(오탐으로 멀쩡한 컴포넌트를 deprecated 로 표시하는
/// 것보다, 실제 deprecated 컴포넌트를 못 찾는 쪽이 덜 위험하다. 전자는
/// 사용자에게 거짓 경고를 주지만, 후자는 소스가 안 바뀌는 한 다음 생성기
/// 실행에서도 그대로다 — 놓친 게 눈에 띄면 정규식을 고치면 된다).
DocsDeprecationStatus? parseClassDeprecation(String source, String className) {
  final classMatch = RegExp(
    '(?:^|\\n)\\s*class\\s+$className\\b',
  ).firstMatch(source);
  if (classMatch == null) return null;

  final precedingBlock = source.substring(0, classMatch.start);
  final openIndex = precedingBlock.lastIndexOf('@Deprecated(');
  if (openIndex < 0) return null;

  final args = _matchBalancedArgs(precedingBlock, openIndex + '@Deprecated'.length);
  if (args == null) return null;

  // class 선언 직전 블록이어야 한다 — 사이에 다른 어노테이션(`@immutable`
  // 등)이나 문서 주석, 공백만 있어야 한다. 세미콜론/중괄호가 끼면 그
  // `@Deprecated` 는 다른 선언(필드/파라미터)에 속한다.
  final between = precedingBlock.substring(args.end);
  if (RegExp(r'[;{}]').hasMatch(between)) return null;

  final message = _quotedLiteralExp
      .allMatches(args.content)
      .map((m) => (m.group(1) ?? m.group(2) ?? '').replaceAll(r"\'", "'"))
      .join()
      .trim();
  if (message.isEmpty) return null;

  final since = _sinceExp.firstMatch(message)?.group(1);
  if (since == null) return null;

  final replacementName = _replacementNameExp.firstMatch(message)?.group(1);

  return DocsDeprecationStatus(
    since: since,
    message: message,
    replacementName: replacementName,
  );
}

/// `text[openParenIndex]` 가 여는 괄호 `(` 라고 가정하고, 그와 짝이 맞는
/// 닫는 괄호까지의 내용을 돌려준다. 중첩 괄호(예: 메시지 안의
/// `CoreSwitcherStyle(curve: ...)`)를 올바르게 건너뛴다.
({String content, int end})? _matchBalancedArgs(String text, int openParenIndex) {
  if (openParenIndex >= text.length || text[openParenIndex] != '(') return null;
  var depth = 0;
  for (var i = openParenIndex; i < text.length; i++) {
    final char = text[i];
    if (char == '(') depth++;
    if (char == ')') {
      depth--;
      if (depth == 0) {
        return (content: text.substring(openParenIndex + 1, i), end: i + 1);
      }
    }
  }
  return null;
}
