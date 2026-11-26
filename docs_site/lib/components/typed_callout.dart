import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/components/callout.dart';
import 'package:jaspr_content/jaspr_content.dart' show CustomComponentBase;

/// `<Callout type="tip">` 처럼 **`type` 속성**으로 variant 를 정하는 콜아웃.
///
/// jaspr_content 기본 [Callout] 은 pattern 이 태그명(`Info`/`Warning`/…)만
/// 매칭한다. 그런데 콘텐츠는 `<Callout type="tip">` / `<Callout type="warning">`
/// (192 블록)을 쓰므로 태그명이 `Callout` 이라 하나도 안 걸려, 그 블록들이
/// 스타일 없이 민짜로 샜다 (#3159). 이 컴포넌트는 `Callout` 태그와 bare 태그를
/// 모두 매칭하고 `type` 을 variant 로 매핑한 뒤 기본 [Callout] 의 렌더/스타일을
/// 그대로 재사용한다.
///
/// 매핑은 docs_app 의 `docsCalloutVariant` 와 **일치**시켜(tip→success 초록 등)
/// 두 문서 표면이 같은 색 어포던스를 갖게 한다.
class TypedCallout extends CustomComponentBase {
  @override
  Pattern get pattern => RegExp(r'Callout|Info|Warning|Error|Success');

  @override
  Component apply(
    String name,
    Map<String, String> attributes,
    Component? child,
  ) {
    // `Callout` 은 `type` 속성으로, bare 태그(`Info` 등)는 태그 이름 자체로
    // variant 를 정한다.
    final type = name == 'Callout' ? _variant(attributes['type']) : name.toLowerCase();
    return Callout.from(
      type: type,
      child: child ?? const Component.fragment([]),
    );
  }

  /// 기본 [Callout] 의 `@css` 스타일을 그대로 emit 시킨다 — `.callout-*`
  /// 규칙은 그 컴포넌트가 단일 출처다.
  @css
  static List<StyleRule> get styles => Callout.styles;
}

/// `type` 문자열 → 기본 [Callout] 의 variant (`info`/`warning`/`error`/
/// `success`).
///
/// docs_app 의 `docsCalloutVariant` 와 같은 매핑이다 — 알 수 없는 값·`null` 은
/// `info` 로 저하시키고(오타 하나가 페이지를 비우지 않게), `tip` 은
/// `success`(초록)로 보낸다. tip 이 초록인 근거(콘텐츠 99 개가 info 와 뭉개지지
/// 않게 + Docusaurus `:::tip` 파리티)는 docs_app 쪽 주석 참조.
String _variant(String? type) => switch (type?.trim().toLowerCase()) {
  'warning' => 'warning',
  'error' => 'error',
  'success' || 'tip' => 'success',
  _ => 'info',
};
