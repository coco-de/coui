/// SPIKE-5 (#3603) — 위젯 트리에서 렌더 값을 읽는 probe.
///
/// CoUI 의 render-only 규칙(`widget/render-only.md`)이 위젯을 `resolved.X`
/// 만 읽도록 강제하므로 "트리에서 읽은 값 = resolver 출력 = 실제 칠해지는
/// 값" 이 성립한다. 이 파일은 그 값을 안정적인 [Finder] 로 뽑아내는 세
/// 함수만 제공한다 — Command · DatePicker · Dialog 세 컴포넌트로 검증한
/// 결과는 이 파일이 아니라 각 `*_probe_test.dart` 와
/// `README.md`(probe 선언 방식 판단, root 단일 probe 로 충분한지 판단,
/// 실패 시 대안)에 있다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// [textFinder] 가 가리키는 [Text] 의 **실효** [TextStyle] 을 읽는다.
///
/// `Text.style` 필드를 직접 읽으면 안 된다 — [Text.build] 는 그 값을
/// `DefaultTextStyle.of(context).style` 과 merge 한 뒤에야 [RichText] 에
/// 굽는다. 위젯 자신이 선언한 필드가 아니라 **트리가 실제로 페인트하는
/// 값**을 읽어야 "토큰은 같은데 렌더가 다르다" 류 회귀(Command 라벨
/// font-weight, PRD 확인 완료 — `.bmad/prd-*.md` "Command 팔레트 리스트
/// 라벨 font-weight 불일치")가 여기서 잡힌다. `Text` 는 정확히 하나의
/// [RichText] 를 만들므로 `.first` 로 충분하다 — 여러 개면 [textFinder] 가
/// `Text` 가 아닌 더 넓은 것을 가리킨 것이다.
TextStyle probeEffectiveTextStyle(WidgetTester tester, Finder textFinder) {
  final richTextFinder = find.descendant(
    of: textFinder,
    matching: find.byType(RichText),
  );
  final richText = tester.widget<RichText>(richTextFinder.first);
  final span = richText.text;
  if (span is! TextSpan) {
    throw StateError(
      'RichText.text 가 TextSpan 이 아님 (${span.runtimeType}) — '
      '$textFinder 가 일반 텍스트가 아닌 것을 가리킴.',
    );
  }

  return span.style ?? const TextStyle();
}

/// [finder] 아래에서 가장 먼저 발견되는 [BoxDecoration] 을 읽는다.
///
/// `Container`/`AnimatedContainer`/`DecoratedBox` 는 전부 내부적으로
/// [DecoratedBox] 를 만들어 그 위에 실제 칠할 decoration 을 얹는다 — 위젯
/// 트리 테스트가 그 내부 구현 위젯까지 보이므로, 호출자가 컴포넌트마다
/// `Container` 인지 `AnimatedContainer` 인지 알 필요 없이 [DecoratedBox]
/// 하나만 찾으면 된다.
///
/// [finder] 아래에 [DecoratedBox] 가 여럿이면(예: 배경 박스 + 포커스 링을
/// 각각 감싼 경우) [skip] 개를 건너뛴다 — 어느 인덱스가 "그" 박스인지는
/// 호출자가 컴포넌트 구조를 보고 정한다(이게 바로 SPIKE-5 가 답해야 하는
/// "finder 안정성"의 실체 — README.md 의 컴포넌트별 판단 참조).
BoxDecoration? probeBoxDecoration(
  WidgetTester tester,
  Finder finder, {
  int skip = 0,
}) {
  final decoratedBoxFinder = find.descendant(
    of: finder,
    matching: find.byType(DecoratedBox),
  );
  final matches = decoratedBoxFinder.evaluate().toList(growable: false);
  if (skip >= matches.length) return null;

  final decoratedBox = tester.widget<DecoratedBox>(decoratedBoxFinder.at(skip));
  final decoration = decoratedBox.decoration;

  return decoration is BoxDecoration ? decoration : null;
}

/// Every [BoxDecoration] found under [finder], in tree order.
///
/// Prefer this over [probeBoxDecoration]'s positional `skip` when a
/// component draws more than one decorated box for different purposes
/// (e.g. [FocusOutline] draws an optional ring-offset band *and* an
/// unconditional border ring) — filtering the returned list by which
/// property is actually set (`border != null`, `color != null`) survives a
/// layout reorder that a hardcoded index would not.
List<BoxDecoration> probeAllBoxDecorations(WidgetTester tester, Finder finder) {
  final decoratedBoxFinder = find.descendant(
    of: finder,
    matching: find.byType(DecoratedBox),
  );

  return decoratedBoxFinder
      .evaluate()
      .map((element) => (element.widget as DecoratedBox).decoration)
      .whereType<BoxDecoration>()
      .toList(growable: false);
}

/// [finder] 아래에서 발견되는 [Padding] 의 실효 [EdgeInsets] 를 읽는다.
/// `EdgeInsetsDirectional` 등 방향성 값은 [direction] 기준으로 resolve 한다
/// — 기본은 `ltr`(하네스가 `textDirection` 을 고정하지 않고 매개변수로
/// 받는 것과 같은 이유로, 호출자가 실제 렌더 방향을 넘기게 둔다).
///
/// [finder] 아래에 같은 타입의 [Padding] 이 여럿 있으면(예: Button 의
/// focus-ring 자체 inset + 실제 chrome padding + ring stroke offset —
/// 이 셋은 [probeBoxDecoration] 의 `skip` 예시가 다루는 DecoratedBox 3중
/// 구조와 같은 자리에 나란히 존재) [skip] 개를 건너뛴다. `probeBoxDecoration`
/// 과 달리 `probeAllPadding` + 속성 필터가 없는 이유는, padding 값 자체가
/// "이게 그 padding" 임을 스스로 증명할 속성(border/color 같은)을 갖지
/// 않기 때문이다 — 인덱스가 유일한 선택지일 때는 이 필드 자체가 그 한계를
/// 인정하는 자리다.
EdgeInsets? probeEffectivePadding(
  WidgetTester tester,
  Finder finder, {
  TextDirection direction = .ltr,
  int skip = 0,
}) {
  final paddingFinder = find.descendant(
    of: finder,
    matching: find.byType(Padding),
  );
  final matches = paddingFinder.evaluate().toList(growable: false);
  if (skip >= matches.length) return null;

  final padding = tester.widget<Padding>(paddingFinder.at(skip));

  return padding.padding.resolve(direction);
}
