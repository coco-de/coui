/// Banner 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="banner/...">` · `<Card demo>` · `<Anatomy>` 가 읽는다. 같은
/// 이름의 Flutter 파일(`banner_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이
/// 같아야 한다.
///
/// 배너는 부모의 폭을 채우는 띠다. 그래서 속성 빌더와 장면은 폭을 정한 상자
/// 안에 놓는다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'banner_page.dart';

/// 속성 → Component.
///
/// 태그의 `label` 이 `message` 가 된다. `description` · `action` 은 글자를
/// 그대로, `dismiss` 는 켜면 닫기 버튼을 읽는다.
WebPropPreviewBuilder? get propPreview => _banner;

/// 장면 이름(`banner/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 — 설명과 행동 버튼은 번호가 가리킬 수 있게 문서 표지를 단다.
  // 구조 무대의 대상 상자는 내용 폭을 따르므로 `100%` 로는 좁아지지 않는다 —
  // 좁은 화면에서는 화면 폭에서 문서 여백을 뺀 값이 상한이다.
  'banner/anatomy': () => _frame(
    width: 'min(${pinnedLengthCss(bannerAnatomyWidth)}, calc(100vw - ${pinnedLengthCss(CoreSpace.space128)}))',
    Banner.info(
      message: const Text('새 버전이 나왔어요'),
      description: span(
        attributes: const {'data-docs-part': 'description'},
        [const Text('지금 받을 수 있어요.')],
      ),
      action: Button(
        variant: CoreButtonVariant.plain,
        size: CoreComponentSize.sm,
        attributes: const {'data-docs-part': 'action'},
        onPressed: () {},
        child: const Text('업데이트'),
      ),
      onDismiss: () {},
    ),
  ),
  'banner/emphasis': () => _stack(gap: CoreSpace.space6, [
    for (final emphasis in CoreBannerEmphasis.values) ...[
      Text(emphasis.name).labelSmall.onSurfaceVariant,
      Banner.destructive(
        emphasis: emphasis,
        message: const Text('지금은 결제를 할 수 없어요'),
        description: const Text('복구하고 있어요.'),
      ),
    ],
  ]),
  'banner/do-solid-outage': () => _frame(
    const Banner.destructive(
      emphasis: CoreBannerEmphasis.solid,
      message: Text('지금은 결제를 할 수 없어요'),
      description: Text('복구하고 있어요.'),
    ),
  ),
  'banner/dont-solid-routine': () => _frame(
    const Banner.info(emphasis: CoreBannerEmphasis.solid, message: Text('새 글꼴이 추가됐어요')),
  ),
  'banner/action-plain': () => _frame(
    Banner.warning(
      emphasis: CoreBannerEmphasis.solid,
      message: const Text('세션이 곧 만료돼요'),
      action: _action('연장하기'),
    ),
  ),
  // 하지 말 예 — solid 위의 outline 버튼은 글자가 버튼 채움에 묻힌다.
  'banner/action-outline-on-solid': () => _frame(
    Banner.warning(
      emphasis: CoreBannerEmphasis.solid,
      message: const Text('세션이 곧 만료돼요'),
      action: _action('연장하기', variant: CoreButtonVariant.outline),
    ),
  ),
  // 휴대폰 폭 — 메시지가 최소 폭을 지키지 못해 버튼이 다음 줄로 내려간다.
  'banner/narrow': () => _frame(
    width: pinnedLengthCss(bannerNarrowWidth),
    Banner.warning(
      message: const Text('체험 기간이 3일 남았어요.'),
      description: const Text('업그레이드하면 프로젝트를 계속 쓸 수 있어요.'),
      action: _action('업그레이드', variant: CoreButtonVariant.outline),
      onDismiss: () {},
    ),
  ),
  'banner/do-match-tone': () => _frame(
    Banner.warning(message: const Text('비밀번호를 90일 넘게 안 바꿨어요'), action: _action('바꾸기')),
  ),
  'banner/dont-wrong-tone': () => _frame(
    const Banner.destructive(message: Text('프리미엄 회원 전용 기능이에요')),
  ),
  'banner/do-severity-text': () => _frame(
    const Banner.destructive(message: Text('오류: 결제하지 못했어요')),
  ),
  'banner/dont-color-only': () => _frame(
    const Banner.destructive(message: Text('결제 상태를 확인하세요')),
  ),
  'banner/do-dismissible': () => _frame(
    Banner.info(message: const Text('새 기능이 추가됐어요'), onDismiss: () {}),
  ),
  'banner/dont-undismissible': () => _frame(
    const Banner.info(message: Text('새 기능이 추가됐어요')),
  ),
  'banner/do-one': () => _frame(
    Banner.warning(message: const Text('구독이 3일 뒤에 끝나요'), action: _action('갱신하기')),
  ),
  'banner/dont-stack': () => _stack(gap: CoreSpace.space0, const [
    Banner.info(message: Text('점검이 예정되어 있어요')),
    Banner.success(message: Text('저장을 마쳤어요')),
    Banner.warning(message: Text('세션이 곧 만료돼요')),
  ]),
  'banner/placement-page': () => _stack(width: pinnedLengthCss(bannerPageWidth), [
    Banner.info(message: const Text(bannerSampleMessage), onDismiss: () {}),
    const Text('주문 현황').titleSmall.semiBold,
    for (final row in bannerPageRows) Text(row).bodyMedium.onSurface,
  ]),
  'banner/theme-order': () => div(classes: 'docs-demo-order', [
    const Text('적용 순서 · 뒤로 갈수록 우선합니다').labelMedium.onSurfaceVariant,
    ol(styles: Styles(raw: {'grid-template-columns': 'repeat(${bannerThemeOrder.length}, minmax(0, 1fr))'}), [
      for (final (index, step) in bannerThemeOrder.indexed)
        li(classes: index == bannerThemeOrder.length - 1 ? 'is-strong' : null, [
          span([Component.text('${index + 1}')]),
          Component.text(step),
        ]),
    ]),
  ]),
  'banner/related-toast': () => Toast(message: '저장했어요', variant: CoreToastVariant.success),
  'banner/related-alert': () => const Alert.destructive(title: '결제하지 못했어요', description: '카드 정보를 확인해 주세요.'),
  'banner/related-status': () => Status(color: CoreStatusColor.success, label: const Text('정상 운영 중')),
};

Component _banner(Map<String, String> props, String? label) {
  final description = props['description'];
  final action = props['action'];
  return _frame(
    Banner(
      message: Text(label ?? bannerSampleMessage),
      description: description == null ? null : Text(description),
      variant: previewEnum(CoreBannerVariant.values, props['variant'], CoreBannerVariant.defaultVariant),
      emphasis: previewEnum(CoreBannerEmphasis.values, props['emphasis'], CoreBannerEmphasis.defaultEmphasis),
      showIcon: previewFlag(props, 'showIcon', fallback: bannerDefaultShowIcon),
      action: action == null ? null : _action(action),
      onDismiss: previewFlag(props, 'dismiss') ? () {} : null,
    ),
  );
}

/// 배너에 놓는 행동 버튼 — 플레이그라운드 코드(`banner_page.dart`)와 같은 모양.
Component _action(String label, {CoreButtonVariant variant = CoreButtonVariant.plain}) => Button(
  variant: variant,
  size: CoreComponentSize.sm,
  onPressed: () {},
  child: Text(label),
);

/// 배너가 채울 폭. `max-width` 까지 적어, 플레이그라운드 칸이 내용에 거는 폭
/// 제한을 받지 않고 무대 폭을 쓴다.
Component _frame(Component child, {String width = '100%'}) => div(
  styles: Styles(raw: {'width': width, 'max-width': '100%'}),
  [child],
);

/// 여러 블록을 위에서 아래로 쌓는다.
Component _stack(List<Component> children, {String width = '100%', double gap = CoreSpace.space8}) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'gap': spaceCss(gap),
      'width': width,
      'max-width': '100%',
    },
  ),
  children,
);
