/// `<LivePreview />` 마크다운 태그 → 프리뷰 위젯.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/markdown/docs_tag.dart';
import 'package:docs_app/src/preview/live_preview.dart';
import 'package:docs_app/src/preview/variant_gallery.dart';
import 'package:docs_core/shared/preview_variants.dart';

/// `<LivePreview component="button" variant="primary" />` 와
/// `<LivePreview component="button" variants="a,b,c" />` 를 렌더한다.
///
/// `variants` 가 있으면 갤러리, 없으면 단일 패널이다 — jaspr 쪽 `LivePreview`
/// 커스텀 컴포넌트와 같은 분기.
///
/// `component` 가 없으면 `null` 을 돌려 태그를 건너뛴다. 문서 한 줄의 오타가
/// 페이지 전체를 깨뜨리지 않게 하려는 것이고, jaspr 도 같은 자리에서 `null`
/// 을 돌린다.
Widget? buildLivePreviewTag(BuildContext context, DocsTag tag) {
  final component = tag.attribute('component')?.trim();
  if (component == null || component.isEmpty) return null;

  final declared = _splitVariants(tag.attribute('variants'));
  final effective = resolveLivePreviewTagVariants(tag);

  if (declared.isNotEmpty || effective.length > 1) {
    return DocsVariantGallery(component: component, variants: effective);
  }

  return DocsLivePreview(
    component: component,
    variant: effective.isEmpty ? null : effective.single,
  );
}

/// 태그 속성 → 유효 변형 목록 해석 — jaspr 쪽 `LivePreview` 커스텀
/// 컴포넌트와 같은 단일 출처(`preview_variants.dart`)를 같은 인자로 부른다.
///
/// `chain="off"` 는 태그 단위 저자 큐레이션(같은 컴포넌트 태그가 복수인
/// 페이지의 chain 중복 노출 제거) — 이 배선이 빠지면 docs_site 는 chain
/// 1개인 페이지를 docs_app 이 태그 수만큼 중복 노출한다. 위젯을 pump 하지
/// 않고 이 해석만 단언할 수 있도록 별도 함수다.
List<String> resolveLivePreviewTagVariants(DocsTag tag) {
  final component = tag.attribute('component')?.trim();
  if (component == null || component.isEmpty) return const [];

  // 값 없는 속성(`<LivePreview variant />`)은 빈 문자열로 들어온다 — 변형을
  // 지정하지 않은 것으로 본다.
  final variant = tag.attribute('variant')?.trim();
  final declared = _splitVariants(tag.attribute('variants'));

  return resolveDocsPreviewVariants(
    component,
    declared.isNotEmpty
        ? declared
        : [if (variant != null && variant.isNotEmpty) variant],
    chainOptOut: tag.attribute('chain') == 'off',
  );
}

/// `variants="a, b, c"` 를 이름 목록으로 쪼갠다.
///
/// 빈 조각은 버린다 — `variants=""` 나 `variants="a,,b"` 가 이름 없는 프리뷰
/// 를 만들지 않게 한다. 결과가 비면 호출부가 단일 패널로 저하시킨다.
List<String> _splitVariants(String? raw) {
  if (raw == null) return const [];
  return [
    for (final part in raw.split(','))
      if (part.trim().isNotEmpty) part.trim(),
  ];
}
