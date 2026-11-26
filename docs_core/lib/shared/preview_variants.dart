/// 라이브 프리뷰 변형 목록 해석 — **단일 출처**.
///
/// 순수 Dart 다: jaspr 도 Flutter 도 import 하지 않는다. md 의
/// `<LivePreview variants="…">` 가 선언한 목록에 **메타데이터 기반 공유
/// 변형**(현재는 `chain`)을 합성하는 자리이며, jaspr(`docs_site`) 와
/// 네이티브(`docs_app`) 양쪽 태그 핸들러가 같은 함수를 거친다.
///
/// 왜 md 선언이 아니라 여기인가: `chain` 은 122 컴포넌트가 공유하는
/// 횡단 변형이라, md 파일마다 `variants="…,chain"` 을 손으로 붙이면
/// 노출 여부를 바꿀 때 118 개 파일을 다시 편집해야 한다. 이 파일 한
/// 곳이 노출을 결정하면 켜고 끄기가 한 줄 변경이다.
library;

import '../previews/flutter_code_registry.dart';

/// docs 프리뷰가 공유 `chain` 변형을 어떻게 노출할지.
///
/// bool 이 아니라 enum 인 이유: 노출 방식이 이분법이 아니다 — 숨기기,
/// 선언 목록 뒤에 덧붙이기, chain 만 보이기 세 방식이 실재하고, 셋 다
/// [resolveDocsPreviewVariants] 한 곳에서 해석된다.
enum DocsChainPreviewMode {
  /// chain 을 노출하지 않는다 — 프리뷰는 md 가 선언한 변형(선언이 없으면
  /// default 예제)만 보여준다.
  hidden,

  /// md 선언 변형 목록 끝에 `chain` 을 덧붙인다. 선언이 없던 컴포넌트는
  /// default 예제가 먼저 보이도록 `default` 뒤에 붙는다 (`default` 는
  /// 레지스트리의 `_` 폴백으로 렌더).
  appended,

  /// chain 변형만 노출한다 — md 선언을 무시하고 `chain` 단일 목록으로
  /// 치환한다 (chain 스니펫이 없는 컴포넌트는 선언 그대로).
  only,
}

/// docs 프리뷰의 현재 chain 노출 모드 — 전 컴포넌트 일괄 적용.
///
/// md 파일은 건드리지 않는다: 이 상수 한 곳을 바꾸면
/// [resolveDocsPreviewVariants] 를 거치는 모든 프리뷰가 따라온다.
const DocsChainPreviewMode kDocsChainPreviewMode = DocsChainPreviewMode.appended;

/// [component] 가 chain 전용 프리뷰/스니펫을 갖는지 — 레지스트리에서 파생.
///
/// 손으로 관리하는 정적 목록은 rot 하므로 두지 않는다. 코드 스니펫
/// 레지스트리라는 기존 단일 출처로 판정한다: `'chain'` 스니펫이
/// default(`null`) 스니펫과 다르면 그 컴포넌트에 chain 케이스가 실제로
/// 존재하는 것이다.
bool docsComponentHasChainPreview(String component) {
  final builder = kFlutterCodeSnippetRegistry[component];
  if (builder == null) return false;
  return builder('chain') != builder(null);
}

/// md 가 선언한 [declared] 변형 목록에 메타데이터 기반 변형을 합성한다.
///
/// [kDocsChainPreviewMode] 가 결정한다: `hidden` 이면 선언 그대로,
/// `appended` 면 chain 스니펫을 가진 컴포넌트에 한해 목록 끝에 `chain`,
/// `only` 면 `chain` 단일 목록으로 치환. 어느 모드든 chain 스니펫이 없는
/// 컴포넌트는 선언을 그대로 돌려준다.
///
/// [chainOptOut] 은 태그 단위 저자 큐레이션(`<LivePreview … chain="off">`)
/// 이다 — 같은 컴포넌트 태그가 복수인 페이지(date-picker ×4 류)에서 chain
/// 갤러리가 태그 수만큼 중복 노출되는 것을 저자가 끈다. 콘텐츠 저작이
/// 아니라 노출 플래그이므로 "md 무편집" 원칙의 예외적 큐레이션이며,
/// **페이지당 chain ≥1** 불변식은 테스트가 강제한다 (전 태그 off 금지).
///
/// [chainMode] 는 테스트 전용 오버라이드다 — 프로덕션 호출부는 넘기지
/// 않는다 (모든 모드 분기를 컴파일타임 상수 수정 없이 검증하기 위함).
List<String> resolveDocsPreviewVariants(
  String component,
  List<String> declared, {
  bool chainOptOut = false,
  DocsChainPreviewMode? chainMode,
}) {
  final mode = chainMode ?? kDocsChainPreviewMode;
  if (chainOptOut) return declared;
  if (mode == DocsChainPreviewMode.hidden) return declared;
  if (!docsComponentHasChainPreview(component)) return declared;
  return switch (mode) {
    DocsChainPreviewMode.hidden => declared,
    DocsChainPreviewMode.appended =>
      declared.contains('chain')
          ? declared
          : [
              ...declared.isEmpty ? const ['default'] : declared,
              'chain',
            ],
    DocsChainPreviewMode.only => const ['chain'],
  };
}
