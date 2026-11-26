/// 컴포넌트 페이지의 크기 표 — 손으로 적지 않고 Core 의 크기 행에서 읽는다.
///
/// 크기 표의 숫자(높이 · 여백 · 아이콘 · 글자 · 모서리)는 전부
/// `CoreXxxStyle.defaultsBySize` 가 정한다. 그 숫자를 문서에 옮겨 적으면
/// 크기 행이 움직이는 날 문서만 옛 값에 남는다 — 실제로 Button 페이지
/// 시안의 아이콘 · 라벨 열이 코드와 달랐다. 그래서 표는 크기 행을 읽어
/// 만들고, 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 같은 표를 그린다.
///
/// 열은 컴포넌트마다 다르다(버튼은 아이콘 · 라벨, 입력창은 글자 · 짝이 되는
/// 버튼). 어느 열을 보일지는 여기서 컴포넌트마다 정하고, 값은 늘 크기
/// 행에서 온다.
library;

import 'package:coui_core/coui_core.dart';

import '../pages/page_registry.g.dart';

export '../pages/page_registry.g.dart' show kDocsSizeSpecs;

/// 크기 표 하나 — 머리글과 크기마다의 행.
class DocsSizeSpec {
  /// 표를 만든다.
  const DocsSizeSpec({required this.columns, required this.rows});

  /// 머리글. 첫 열은 늘 크기 이름이다.
  final List<String> columns;

  /// 크기마다 한 행 — 작은 크기부터.
  final List<DocsSizeSpecRow> rows;
}

/// 크기 표의 행 하나.
class DocsSizeSpecRow {
  /// 행을 만든다.
  const DocsSizeSpecRow({required this.size, required this.cells});

  /// 이 행의 크기.
  final CoreComponentSize size;

  /// 크기 이름 열을 뺀 나머지 칸 — [DocsSizeSpec.columns] 의 둘째 열부터.
  final List<String> cells;
}

/// [component](문서 슬러그)의 크기 표 — 표를 정의하지 않은 컴포넌트는 `null`.
DocsSizeSpec? docsSizeSpecFor(String component) => kDocsSizeSpecs[component]?.call();

/// 크기 표가 있는 컴포넌트 — 문서 테스트가 `<SizeSpec>` 태그의 이름을 대조한다.
Set<String> get kDocsSizeSpecComponents => kDocsSizeSpecs.keys.toSet();

/// 역할 토큰을 CoUI 기본 스케일로 푼다 — 표는 기본 스케일의 숫자를 적는다.
CoreTextStyle? docsSizeResolve(CoreTextStyle? style) => style == null ? null : CoreTypography.coui.resolve(style);

/// `14 Medium` — 크기와 굵기 이름.
String docsSizeLabel(CoreTextStyle? style) {
  final resolved = docsSizeResolve(style);
  if (resolved == null) return '–';
  return '${docsSizeNumber(resolved.fontSize)} ${_weightName(resolved.fontWeight)}';
}

String _weightName(int? weight) => switch (weight) {
  100 => 'Thin',
  200 => 'ExtraLight',
  300 => 'Light',
  400 => 'Regular',
  500 => 'Medium',
  600 => 'SemiBold',
  700 => 'Bold',
  800 => 'ExtraBold',
  900 => 'Black',
  _ => '',
};

/// 숫자를 표에 적는 모양 — 정수면 소수점을 떼고, 없으면 `–`.
String docsSizeNumber(double? value) {
  if (value == null) return '–';
  return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
}
