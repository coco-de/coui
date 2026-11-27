/// Banner 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `banner_web.dart` · `banner_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/banner.md`.
const String slug = 'banner';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. Banner 에는 `CoreComponentSize` 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 플레이그라운드의 메시지이자, 미리보기에 라벨을 주지 않았을 때의 메시지.
const String bannerSampleMessage = '새벽 2시에 점검이 있어요';

/// `showIcon` 을 적지 않았을 때의 값 — 생성자의 기본값과 같다.
const bool bannerDefaultShowIcon = true;

/// 구조 장면의 폭 — 글과 행동 · 닫기 버튼이 한 줄에 놓인다.
const double bannerAnatomyWidth = 512;

/// 좁은 폭 장면의 폭(휴대폰 폭) — 버튼이 다음 줄로 내려간다.
const double bannerNarrowWidth = 320;

/// 배치 장면의 화면 폭.
const double bannerPageWidth = 448;

/// 값이 정해지는 순서 — 왼쪽부터 깔리고, 뒤의 것이 이긴다. 두 플랫폼 장면이 함께 읽는다.
const List<String> bannerThemeOrder = ['디자인 시스템 기본값', '테마 style', '테마 variantStyles', '인스턴스 bannerStyle'];

/// 배치 장면에서 배너 아래에 놓는 목록 행.
const List<String> bannerPageRows = ['주문 접수 · 2건', '배송 준비 · 1건', '배송 중 · 4건'];

/// 플레이그라운드에 처음 보이는 설명 — 설명 플래그를 켰을 때의 값과 같다.
const String _description = '4시까지 결제를 할 수 없어요.';

// 선택지는 Core 의 enum 에서 읽는다 — 종류나 세기가 늘면 컨트롤이 함께
// 따라온다. 처음 종류는 info 다: 기본값인 neutral 은 채움이 흰 무대와 거의
// 같아 띠의 경계가 잘 보이지 않는다.
final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {
    'variant': CoreBannerVariant.info.name,
    'emphasis': CoreBannerEmphasis.defaultEmphasis.name,
    'description': _description,
    'dismiss': 'true',
  },
  label: bannerSampleMessage,
  controls: [
    DocsPlaygroundChoice(
      label: 'variant',
      prop: 'variant',
      options: [for (final variant in CoreBannerVariant.values) variant.name],
    ),
    DocsPlaygroundChoice(
      label: 'emphasis',
      prop: 'emphasis',
      options: [for (final emphasis in CoreBannerEmphasis.values) emphasis.name],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: '설명', on: {'description': _description}),
    const DocsPlaygroundFlag(label: '행동 버튼', on: {'action': '자세히 보기'}),
    const DocsPlaygroundFlag(label: '닫기 버튼', on: {'dismiss': 'true'}),
    const DocsPlaygroundFlag(label: '아이콘 끄기', on: {'showIcon': 'false'}),
  ],
  code: _bannerCode,
);

/// 속성 → 코드. 기본값과 같은 속성은 적지 않는다. 행동 버튼은 두 강조에서
/// 모두 글자가 보이는 `plain` 이다 — 미리보기 빌더와 같은 모양이다.
String _bannerCode(Map<String, String> props, String? label) {
  String quoted(String value) => "'${value.replaceAll("'", r"\'")}'";
  final variant = previewEnum(CoreBannerVariant.values, props['variant'], CoreBannerVariant.defaultVariant);
  final emphasis = previewEnum(CoreBannerEmphasis.values, props['emphasis'], CoreBannerEmphasis.defaultEmphasis);
  final lines = [
    'message: Text(${quoted(label ?? bannerSampleMessage)}),',
    if (props['description'] case final description?) 'description: Text(${quoted(description)}),',
    if (variant != CoreBannerVariant.defaultVariant) 'variant: CoreBannerVariant.${variant.name},',
    if (emphasis != CoreBannerEmphasis.defaultEmphasis) 'emphasis: CoreBannerEmphasis.${emphasis.name},',
    if (!previewFlag(props, 'showIcon', fallback: bannerDefaultShowIcon)) 'showIcon: false,',
    if (props['action'] case final action?) ...[
      'action: Button(',
      '  variant: CoreButtonVariant.plain,',
      '  size: CoreComponentSize.sm,',
      '  onPressed: showDetails,',
      '  child: Text(${quoted(action)}),',
      '),',
    ],
    if (previewFlag(props, 'dismiss')) 'onDismiss: hideBanner,',
  ];
  return 'Banner(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
