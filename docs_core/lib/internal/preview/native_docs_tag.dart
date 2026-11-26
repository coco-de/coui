/// 마크다운 본문에 박힌 커스텀 태그(`<LivePreview />`, `<Callout>…</Callout>`)
/// 의 모델과 파서.
library;

/// 블록 레벨 여는 태그 한 줄 — `<Name>` / `<Name attr="v">` / `<Name … />`.
///
/// 따옴표로 감싼 속성값은 통째로 읽는다 — `selector=".a > b"` 처럼 값에 `>` 가
/// 들어간다. 따옴표 밖의 `>` 만 태그를 닫는다. 세 갈래가 첫 글자로 갈리므로
/// 닫히지 않은 따옴표가 있어도 되짚기가 늘어나지 않는다.
final _kOpenTag = RegExp(
  r'''^<([A-Z][A-Za-z0-9]*)((?:\s(?:[^>"']|"[^"]*"|'[^']*')*)?)>$''',
);

/// 블록 레벨 닫는 태그 한 줄 — `</Name>`.
final _kCloseTag = RegExp('^</([A-Z][A-Za-z0-9]*)>');

/// 펜스 코드 블록의 시작/끝 — ``` 또는 ~~~ (3개 이상).
final _kFence = RegExp('^(`{3,}|~{3,})');

/// `name`, `name=value`, `name="value"`, `name='value'` 를 모두 받는다.
final _kAttribute = RegExp(
  r'''([A-Za-z_:][-.\w:]*)(?:\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'`=<>]+)))?''',
);

/// [_kAttribute] 의 값 캡처 그룹 — 큰따옴표 / 작은따옴표 / 따옴표 없음 순.
const _kDoubleQuotedValue = 2;
const _kSingleQuotedValue = 3;
const _kUnquotedValue = 4;

/// 마크다운 안의 커스텀 태그 하나.
///
/// [name] 은 원본 대소문자를 그대로 보존한다 — `LivePreview` 와 `livepreview`
/// 는 다른 태그다.
class DocsTag {
  /// 태그를 만든다.
  const DocsTag({
    required this.name,
    this.attributes = const {},
    this.innerMarkdown,
  });

  /// 태그 이름 — 대소문자 보존.
  final String name;

  /// 속성 — 선언 순서와 무관하게 이름으로 조회한다.
  ///
  /// 값 없는 속성(`<Callout dense>`)은 빈 문자열로 들어온다.
  final Map<String, String> attributes;

  /// 여는 태그와 닫는 태그 사이의 원본 마크다운.
  ///
  /// 태그가 self-closing 이면 `null` 이다 — 빈 문자열(`<X></X>`)과 구분된다.
  final String? innerMarkdown;

  /// 속성 하나를 읽는다 — 없으면 `null`.
  String? attribute(String key) => attributes[key];
}

/// [DocsTag] 와 그 태그가 원본에서 차지한 구간.
class DocsTagMatch {
  /// 매치를 만든다.
  const DocsTagMatch({
    required this.tag,
    required this.start,
    required this.end,
  });

  /// 파싱된 태그.
  final DocsTag tag;

  /// 원본에서 여는 태그가 시작하는 문자 오프셋 (포함).
  final int start;

  /// 원본에서 닫는(또는 self-closing) 태그가 끝나는 오프셋 (미포함).
  final int end;
}

/// [source] 안의 최상위 커스텀 태그를 원본 순서대로 찾는다.
///
/// 코드 펜스 안은 건너뛴다 — 문서 본문은 `List<String>` / `<Widget>` 같은
/// 제네릭으로 가득해서, 순진한 태그 정규식은 그걸 전부 망가뜨린다. 같은
/// 이유로 태그로 인정하는 조건을 좁게 잡았다: 대문자로 시작하고, 여는 태그가
/// 한 줄을 통째로 차지하며, self-closing 이거나 짝이 맞는 닫는 태그가 있어야
/// 한다. 그래서 산문 속의 `<Widget>` 은 닫는 태그가 없어 태그가 아니고,
/// 중첩된 `<TabItem>` 은 부모 `innerMarkdown` 안에 남아 재귀 호출에서 잡힌다.
List<DocsTagMatch> findDocsTags(String source) {
  final lines = source.split('\n');
  final offsets = _lineOffsets(lines);
  final matches = <DocsTagMatch>[];

  String? fence;
  var i = 0;
  while (i < lines.length) {
    final trimmed = lines[i].trim();

    if (fence != null) {
      if (trimmed.startsWith(fence)) fence = null;
      i++;
      continue;
    }
    final fenceStart = _kFence.firstMatch(trimmed);
    if (fenceStart != null) {
      fence = fenceStart.group(1);
      i++;
      continue;
    }

    final open = _kOpenTag.firstMatch(trimmed);
    if (open == null) {
      i++;
      continue;
    }

    final name = open.group(1)!;
    final raw = _stripSelfClosingSlash(open.group(2) ?? '');
    final attributes = parseDocsTagAttributes(raw.attributes);

    if (raw.selfClosing) {
      matches.add(
        DocsTagMatch(
          tag: DocsTag(name: name, attributes: attributes),
          start: offsets[i],
          end: offsets[i] + lines[i].length,
        ),
      );
      i++;
      continue;
    }

    final close = _findCloseLine(lines, name, i + 1);
    if (close == null) {
      i++;
      continue;
    }

    matches.add(
      DocsTagMatch(
        tag: DocsTag(
          name: name,
          attributes: attributes,
          innerMarkdown: lines.sublist(i + 1, close).join('\n'),
        ),
        start: offsets[i],
        end: offsets[close] + lines[close].length,
      ),
    );
    i = close + 1;
  }

  return matches;
}

/// [source] 전체가 커스텀 태그 하나면 그 태그를, 아니면 `null` 을 준다.
///
/// 마크다운 파서가 통째로 넘겨준 raw HTML 블록을 해석할 때 쓴다.
DocsTag? parseDocsTag(String source) {
  final matches = findDocsTags(source);
  if (matches.length != 1) return null;

  final match = matches.single;
  if (source.substring(0, match.start).trim().isNotEmpty) return null;
  if (source.substring(match.end).trim().isNotEmpty) return null;
  return match.tag;
}

/// 여는 태그의 속성 문자열(`' type="tip" dense'`)을 맵으로 만든다.
Map<String, String> parseDocsTagAttributes(String source) {
  final attributes = <String, String>{};
  for (final match in _kAttribute.allMatches(source)) {
    final name = match.group(1);
    if (name == null) continue;
    attributes[name] =
        match.group(_kDoubleQuotedValue) ?? match.group(_kSingleQuotedValue) ?? match.group(_kUnquotedValue) ?? '';
  }
  return attributes;
}

/// `<X a="b" />` 의 속성 문자열에서 끝의 `/` 를 떼어낸다.
///
/// 여는 태그 정규식의 속성 구간이 self-closing 슬래시까지 먹기 때문에 이
/// 단계에서 되돌린다.
({String attributes, bool selfClosing}) _stripSelfClosingSlash(String source) {
  final trimmed = source.trimRight();
  if (!trimmed.endsWith('/')) return (attributes: source, selfClosing: false);
  return (
    attributes: trimmed.substring(0, trimmed.length - 1),
    selfClosing: true,
  );
}

/// [from] 부터 [name] 의 짝이 맞는 닫는 태그 줄을 찾는다 — 없으면 `null`.
int? _findCloseLine(List<String> lines, String name, int from) {
  var depth = 0;
  String? fence;

  for (var i = from; i < lines.length; i++) {
    final trimmed = lines[i].trim();

    if (fence != null) {
      if (trimmed.startsWith(fence)) fence = null;
      continue;
    }
    final fenceStart = _kFence.firstMatch(trimmed);
    if (fenceStart != null) {
      fence = fenceStart.group(1);
      continue;
    }

    final open = _kOpenTag.firstMatch(trimmed);
    if (open != null && open.group(1) == name) {
      if (!_stripSelfClosingSlash(open.group(2) ?? '').selfClosing) depth++;
      continue;
    }

    final close = _kCloseTag.firstMatch(trimmed);
    if (close != null && close.group(1) == name) {
      if (depth == 0) return i;
      depth--;
    }
  }
  return null;
}

/// 각 줄이 원본에서 시작하는 문자 오프셋.
List<int> _lineOffsets(List<String> lines) {
  final offsets = List.filled(lines.length, 0);
  var offset = 0;
  for (var i = 0; i < lines.length; i++) {
    offsets[i] = offset;
    offset += lines[i].length + 1;
  }
  return offsets;
}
