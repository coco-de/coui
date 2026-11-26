/// chain 순열 축 어휘 · 좌표 · 결정적 시퀀스 · 코드 치환 — **단일 출처**.
///
/// 순수 Dart 다: jaspr 도 Flutter 도 import 하지 않는다 (docs_app 공유
/// 가능, `preview_variants.dart` 선례). 랜덤 토글이 나르는 값은 임의
/// 런타임 값이 아니라 **토큰 이름 좌표** `(radiusIndex, colorIndex)` 뿐이고,
/// 그 좌표가 가리키는 이름은 아래 어휘 상수 30개(정본)에서만 나온다 —
/// 존재하지 않는 getter 이름은 구조적으로 생성될 수 없다.
///
/// 어휘가 실제 `*StyleChain` extension 표면과 1:1 인지는 실측표
/// (`chain_axis_table.dart`) 대조 테스트가 게이트한다 — 여기 상수를 고칠
/// 일은 라이브러리 getter 표면이 바뀔 때뿐이다.
library;

/// radius 축 getter 이름 19종 — `CoreRadius` primitive scale 순.
const List<String> kChainRadiusGetters = [
  'radius0',
  'radius2',
  'radius4',
  'radius6',
  'radius8',
  'radius10',
  'radius12',
  'radius14',
  'radius16',
  'radius20',
  'radius24',
  'radius28',
  'radius32',
  'radius36',
  'radius40',
  'radius48',
  'radius56',
  'radius64',
  'radius9999',
];

/// 색 축 getter 이름 11종 — 시맨틱 순 (extension 선언 순과 동일).
const List<String> kChainColorGetters = [
  'primary',
  'secondary',
  'tertiary',
  'surface',
  'surfaceContainer',
  'error',
  'success',
  'warning',
  'info',
  'outline',
  'transparent',
];

/// 시퀀스 셔플 seed — 값 자체에 의미는 없다. 바꾸면 모든 패널의 순열
/// **순서**가 바뀔 뿐 커버리지(전 조합 순회)는 불변이다.
const int kChainShuffleSeed = 0x5EED;

/// 한 순열 좌표 — 양축 어휘의 인덱스 쌍.
///
/// 값이 아니라 좌표를 나르는 이유: 임의 값 transport 는 착수 보류 판정이
/// 유지 중이고, 좌표는 기존 채널의 enum 문자열과 동급의 유한 어휘라
/// 그 판정에 저촉되지 않는다.
class ChainPermutation {
  const ChainPermutation({required this.radiusIndex, required this.colorIndex});

  /// [kChainRadiusGetters] 인덱스.
  final int radiusIndex;

  /// [kChainColorGetters] 인덱스.
  final int colorIndex;

  /// 좌표가 두 어휘 범위 안에 있는가.
  bool get isInRange =>
      radiusIndex >= 0 &&
      radiusIndex < kChainRadiusGetters.length &&
      colorIndex >= 0 &&
      colorIndex < kChainColorGetters.length;

  @override
  bool operator ==(Object other) =>
      other is ChainPermutation && other.radiusIndex == radiusIndex && other.colorIndex == colorIndex;

  @override
  int get hashCode => Object.hash(radiusIndex, colorIndex);

  @override
  String toString() =>
      'ChainPermutation(${kChainRadiusGetters[radiusIndex]}, '
      '${kChainColorGetters[colorIndex]})';
}

/// base 순열 — T1 base 저작 규약이 고정하는 combo 앵커 `.radius16.primary`
/// 의 좌표. 시퀀스 position 0 이 항상 이 좌표라서 "클릭 전 = base" 와
/// "전 조합 순회 후 base 복귀" 가 같은 사실이 된다.
///
/// 인덱스가 어휘와 어긋나면 단위 테스트가 잡는다 (radius16 = scale 9번째,
/// primary = 시맨틱 첫 번째).
const ChainPermutation kChainBasePermutation = ChainPermutation(
  radiusIndex: 8,
  colorIndex: 0,
);

/// 전 조합 수 — 19 × 11.
const int kChainPermutationCount = 209;

/// [step] 번째 순열 좌표 — 결정적.
///
/// 시퀀스는 209 전 조합의 seed 셔플 순환이고 **position 0 = base**
/// ([kChainBasePermutation]) 로 회전되어 있다: step 0(클릭 전) = base,
/// step 1~208 = 나머지 조합 무중복, step 209 = base 복귀, step 210 =
/// step 1 과 동일 (순환). 음수 step 은 순환 위로 정규화한다 — throw 0.
ChainPermutation chainPermutationAt(int step, {int seed = kChainShuffleSeed}) {
  final cycle = seed == kChainShuffleSeed ? _defaultCycle : _buildCycle(seed);
  final index = step % cycle.length;
  return cycle[index < 0 ? index + cycle.length : index];
}

/// [permutation] 의 사용자-표기 라벨 — 칩·SR 통보·네이티브 컨트롤이
/// 공유하는 단일 표기 (`.radius16.primary`).
///
/// 실재 getter 이름 그대로다 — 치환 어휘 밖 표기를 각 UI 가 따로 만들면
/// 표기끼리 갈라진다 (jaspr 칩과 네이티브 칩이 두 번째 사본이 되는 것을
/// 막는 자리).
String chainPermutationLabel(ChainPermutation permutation) =>
    '.${kChainRadiusGetters[permutation.radiusIndex]}'
    '.${kChainColorGetters[permutation.colorIndex]}';

final List<ChainPermutation> _defaultCycle = _buildCycle(kChainShuffleSeed);

/// Park-Miller LCG (a=48271, m=2³¹−1) 기반 Fisher-Yates.
///
/// `dart:math` [Random] 을 쓰지 않는 이유: 같은 seed 라도 VM 과
/// dart2js 의 구현이 같은 수열을 보장하지 않는다 — 단위 테스트(VM)가
/// 브라우저 런타임(JS)의 순서를 예측할 수 있어야 AC 가 성립한다.
/// 곱의 최대값 48271×(2³¹−2) ≈ 2⁴⁷ 은 JS double 정수 한계(2⁵³) 안이라
/// 양쪽에서 비트-동일하게 계산된다.
List<ChainPermutation> _buildCycle(int seed) {
  final combos = [
    for (var r = 0; r < kChainRadiusGetters.length; r++)
      for (var c = 0; c < kChainColorGetters.length; c++) ChainPermutation(radiusIndex: r, colorIndex: c),
  ];

  var state = seed % 2147483647;
  if (state <= 0) state += 2147483646;
  int next(int bound) {
    state = (state * 48271) % 2147483647;
    return state % bound;
  }

  final shuffled = [...combos];
  for (var i = shuffled.length - 1; i > 0; i--) {
    final j = next(i + 1);
    final swap = shuffled[i];
    shuffled[i] = shuffled[j];
    shuffled[j] = swap;
  }

  // base 를 position 0 으로 회전 — "step 0 = 기본 순열" 계약.
  final baseIndex = shuffled.indexOf(kChainBasePermutation);
  return [...shuffled.sublist(baseIndex), ...shuffled.sublist(0, baseIndex)];
}

/// [baseSnippet] 의 양축 getter 리터럴을 [permutation] 좌표의 이름으로
/// 교체한 코드를 돌려준다 — 순열별 스니펫 저작 금지(REQ-B3)의 구현.
///
/// **identifier-boundary 매칭**: `.{name}` 뒤에 식별자 문자가 이어지지
/// 않는 위치만 센다 — `radius4` 가 `radius40` 안에서, `surface` 가
/// `surfaceContainer` 안에서 매칭되면 안 된다. 단순 부분문자열 치환 금지.
///
/// **receiver-위치 판별**: 앞쪽(공백·개행 스킵)이 `)` 이거나 어휘 getter
/// 식별자일 때만 체인 적용으로 센다. 그래서 값-위치의 동명 심볼 —
/// `CoreButtonVariant.primary`(enum 멤버) · `CoreRadius.radius16`(토큰
/// 상수) · `variant: .primary`(dot shorthand) — 는 앵커로 오인되지 않고,
/// `dart format` 이 체인을 여러 줄로 꺾어도 매칭이 유지된다.
///
/// **fail-safe**: 축당 체인 출현이 정확히 1회가 아니거나(T1 base 저작
/// 규약 위반 — 저작 단계 AC 테스트가 잡는다) 좌표가 범위 밖이면 **원문을
/// 그대로** 돌려준다 — 부분 치환된 문자열은 어떤 경로로도 나가지 않는다.
String substituteChainTokens(String baseSnippet, ChainPermutation permutation) {
  if (!permutation.isInRange) return baseSnippet;

  final radiusMatch = _soleAxisMatch(baseSnippet, kChainRadiusGetters);
  final colorMatch = _soleAxisMatch(baseSnippet, kChainColorGetters);
  if (radiusMatch == null || colorMatch == null) return baseSnippet;

  final replacements = [
    (match: radiusMatch, name: kChainRadiusGetters[permutation.radiusIndex]),
    (match: colorMatch, name: kChainColorGetters[permutation.colorIndex]),
  ];
  // 뒤 위치부터 교체해야 앞 교체가 뒤 오프셋을 흔들지 않는다.
  if (replacements[0].match.start < replacements[1].match.start) {
    final swap = replacements[0];
    replacements[0] = replacements[1];
    replacements[1] = swap;
  }

  var result = baseSnippet;
  for (final r in replacements) {
    result =
        '${result.substring(0, r.match.start)}'
        '.${r.name}'
        '${result.substring(r.match.end)}';
  }
  return result;
}

/// [snippet] 안에서 [vocab] 축 getter 의 **체인-적용** 출현 수를 센다.
///
/// [substituteChainTokens] 와 같은 매칭(identifier-boundary +
/// receiver-위치 판별)을 쓴다 — 값-위치 동명 심볼(enum 멤버·토큰 상수·
/// dot shorthand)은 세지 않는다. 티어별 저작 규약 검사가 소비한다:
/// T1 은 축당 정확 1회(치환 앵커), T2 는 보유 축 ≥1회.
int chainAxisAnchorCount(String snippet, List<String> vocab) {
  var count = 0;
  for (final name in vocab) {
    final pattern = RegExp(
      '\\.$name'
      r'(?![A-Za-z0-9_$])',
    );
    for (final match in pattern.allMatches(snippet)) {
      if (_isChainApplication(snippet, match.start)) count++;
    }
  }
  return count;
}

/// [vocab] 전체에 대해 `.{name}` 체인-적용 매칭을 세어, 축 전체 출현이
/// 정확히 1회일 때만 그 위치를 돌려준다 (아니면 `null` — fail-safe).
({int start, int end})? _soleAxisMatch(String snippet, List<String> vocab) {
  ({int start, int end})? sole;
  var count = 0;
  for (final name in vocab) {
    final pattern = RegExp(
      '\\.$name'
      r'(?![A-Za-z0-9_$])',
    );
    for (final match in pattern.allMatches(snippet)) {
      if (!_isChainApplication(snippet, match.start)) continue;
      count++;
      if (count > 1) return null;
      sole = (start: match.start, end: match.start + 1 + name.length);
    }
  }
  return count == 1 ? sole : null;
}

/// 양축 어휘 합집합 — receiver 식별자 판별용.
final Set<String> _chainVocabulary = {
  ...kChainRadiusGetters,
  ...kChainColorGetters,
};

const String _identifierChars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_\$';

/// [dotIndex] 의 `.` 가 **체인 getter 적용**인가 — receiver 판별.
///
/// 공백·개행을 거슬러 올라가 직전 유효 문자를 본다: `)` (호출 결과에
/// 적용) 이거나, 직전 식별자가 어휘 getter (getter 에 getter 를 잇는
/// `.radius16.primary` 의 두 번째 `.`) 일 때만 참. 그 외 — 타입/네임스페이스
/// 멤버 접근(`CoreButtonVariant.primary`), 값-위치 dot shorthand
/// (`variant: .primary`) — 는 거짓.
bool _isChainApplication(String snippet, int dotIndex) {
  var i = dotIndex - 1;
  while (i >= 0 && (snippet[i] == ' ' || snippet[i] == '\n' || snippet[i] == '\t' || snippet[i] == '\r')) {
    i--;
  }
  if (i < 0) return false;
  if (snippet[i] == ')') return true;

  if (!_identifierChars.contains(snippet[i])) return false;
  final end = i + 1;
  while (i >= 0 && _identifierChars.contains(snippet[i])) {
    i--;
  }
  return _chainVocabulary.contains(snippet.substring(i + 1, end));
}
