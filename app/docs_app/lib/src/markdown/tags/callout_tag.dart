/// `<Callout type="...">` 와 bare `<Info>` / `<Warning>` / `<Error>` /
/// `<Success>` 태그.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/markdown/docs_tag.dart';
import 'package:docs_app/src/markdown/docs_tag_registry.dart';

/// 콜아웃 태그 이름 → 빌더. [nested] 는 콜아웃 본문(마크다운)을 렌더한다.
///
/// `Callout` 은 `type` 속성으로, bare 태그(`Info` 등)는 태그 이름 자체로
/// variant 를 정한다 — 둘 다 [docsCalloutVariant] 한 곳을 거친다.
Map<String, DocsTagBuilder> docsCalloutTagBuilders({
  required Widget Function(String markdown) nested,
}) {
  Widget build(BuildContext context, DocsTag tag, {String? type}) =>
      _CalloutBox(
        variant: docsCalloutVariant(type),
        child: nested(tag.innerMarkdown ?? ''),
      );

  return {
    'Callout': (context, tag) =>
        build(context, tag, type: tag.attributes['type']),
    for (final name in const ['Info', 'Warning', 'Error', 'Success'])
      name: (context, tag) => build(context, tag, type: name),
  };
}

/// 콜아웃 `type` 문자열을 [CoreAlertVariant] 로 매핑한다.
///
/// 알 수 없는 값·`null` 은 `info` 로 저하시킨다 — 콘텐츠 192 곳이 쓰는
/// 태그라 오타 하나가 페이지를 비우면 안 된다.
///
/// `tip` 이 `success`(초록)인 이유: 콘텐츠의 tip 은 99 개로 info/note 와
/// 압도적으로 많은데, info 에 합치면 둘이 같은 파랑으로 뭉개져 "팁" 이라는
/// 어포던스가 사라진다. Docusaurus `:::tip` 도 초록이라 독자 기대와 맞는다.
CoreAlertVariant docsCalloutVariant(String? type) =>
    switch (type?.trim().toLowerCase()) {
      'warning' => .warning,
      'error' => .destructive,
      'success' || 'tip' => .success,
      _ => .info,
    };

/// 마크다운 본문을 담는 콜아웃 상자.
///
/// `Alert` 자체를 합성하지 못하는 이유: `Alert.description` 이 `String` 이라
/// 블록 마크다운(굵게·인라인 코드·펜스 코드 블록)을 넣을 자리가 없다.
/// 콘텐츠의 콜아웃 192 개는 **전부** 그런 rich 본문이라 문자열로 넘기면
/// 백틱과 `**` 가 그대로 노출된다. 그래서 chrome 은 `resolveAlert` 가 낸
/// paint-ready 값만 읽고(색·패딩·radius·간격·아이콘 전부 `CoreAlertStyle`
/// 단일 출처), 본문 자리에만 `String` 대신 위젯을 놓는다 — Alert 의 Row
/// 구조와 동일. `Alert` 에 `child` 슬롯이 생기면 이 위젯은 지운다.
class _CalloutBox extends StatelessWidget {
  const _CalloutBox({required this.variant, required this.child});

  final CoreAlertVariant variant;
  final Widget child;

  /// `Alert._variantIconName` 의 쌍둥이 — private 이라 참조할 수 없다.
  /// 시맨틱 매핑(변형 → 글리프)이라 chrome 값 복제는 아니다.
  IconName get _iconName => switch (variant) {
    .defaultVariant || .info => LucideIcons.info,
    .success => LucideIcons.circleCheck,
    .warning => LucideIcons.triangleAlert,
    .destructive => LucideIcons.circleX,
  };

  @override
  Widget build(BuildContext context) {
    final resolved = resolveAlert(context, variant: variant);

    return Semantics(
      container: true,
      label: 'Callout',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: resolved.backgroundColor,
          border: Border.all(
            color: resolved.borderColor,
            width: resolved.borderWidth,
          ),
          borderRadius: resolved.borderRadius,
        ),
        child: Padding(
          padding: resolved.padding,
          child: Row(
            crossAxisAlignment: .start,
            children: [
              Icon(_iconName, iconStyle: resolved.iconStyle),
              Gap(gapStyle: resolved.iconContentGapStyle),
              // 본문은 Alert 의 설명 타이포를 상속한다 — 마크다운 렌더러가
              // 자기 블록(헤딩/코드)에 대해 다시 override 한다.
              Expanded(
                child: DefaultTextStyle(
                  style: resolved.descriptionTextStyle,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
