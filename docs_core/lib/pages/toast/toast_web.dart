/// Toast 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="toast/...">` · `<Card demo>` · `<Anatomy>` 가 읽는다. 같은
/// 이름의 Flutter 파일(`toast_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이
/// 같아야 한다.
///
/// `Toast` 는 놓인 자리에 그려지는 카드라 무대의 카드는 실제 컴포넌트다. Web
/// 에는 토스트를 띄우는 함수가 없어 속성 `opener` 를 읽지 않는다 — 띄워 보기는
/// Flutter 미리보기에만 있다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'toast_page.dart' as page;

/// 속성 → Component. 태그의 `label` 이 `message` 가 된다. `description` ·
/// `action` 은 글자를 그대로, `dismiss` 는 켜면 닫기 버튼을 읽는다.
WebPropPreviewBuilder? get propPreview => _toast;

/// 장면 이름(`toast/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'toast/anatomy': () => _frame(
    Toast(
      message: '저장했어요',
      description: '변경 사항을 저장했어요.',
      variant: CoreToastVariant.success,
      onDismiss: () {},
      action: _action('되돌리기'),
    ),
    width: page.demoAnatomyWidth,
  ),
  'toast/with-action': () => _frame(
    Toast(message: '파일 3개를 삭제했어요', onDismiss: () {}, action: _action('되돌리기')),
  ),
  'toast/do-short': () => _frame(Toast(message: '링크를 복사했어요', variant: CoreToastVariant.success)),
  'toast/dont-long': () => _frame(
    Toast(
      message: '링크 복사를 마쳤습니다. 원하는 곳에 붙여 넣어 팀원에게 공유할 수 있고, 링크 설정은 언제든 바꿀 수 있습니다.',
      variant: CoreToastVariant.success,
    ),
  ),
  'toast/do-quiet-action': () => _frame(Toast(message: '메일을 보관했어요', action: _action('되돌리기'))),
  'toast/dont-filled-action': () => _frame(
    Toast(
      message: '메일을 보관했어요',
      action: _action('되돌리기', variant: CoreButtonVariant.outline),
    ),
  ),
  'toast/do-recovery': () => _frame(
    Toast(
      message: '저장하지 못했어요',
      description: '연결을 확인한 뒤 다시 시도해 주세요.',
      variant: CoreToastVariant.destructive,
      onDismiss: () {},
      action: _action('다시 시도'),
    ),
  ),
  'toast/dont-lasting-news': () => _frame(
    Toast(
      message: '결제 수단이 만료됐어요',
      description: '카드를 바꾸지 않으면 다음 달부터 이용이 멈춰요.',
      variant: CoreToastVariant.destructive,
    ),
  ),
};

Component _toast(Map<String, String> props, String? label) {
  final action = props['action'];
  return _frame(
    Toast(
      message: label ?? page.demoMessage,
      description: props['description'],
      variant: page.demoVariant(props),
      showIcon: page.demoShowIcon(props),
      onDismiss: previewFlag(props, 'dismiss') ? () {} : null,
      action: action == null ? null : _action(action),
    ),
  );
}

/// 토스트에 놓는 행동 버튼 — 플레이그라운드 코드(`toast_page.dart`)와 같은 모양.
Component _action(String label, {CoreButtonVariant variant = CoreButtonVariant.plain}) => Button(
  variant: variant,
  size: CoreComponentSize.xs,
  onPressed: () {},
  child: Text(label),
);

/// 카드가 채울 폭 — 카드는 부모 폭을 다 쓴다.
Component _frame(Component child, {double width = page.demoToastWidth}) => div(
  styles: Styles(raw: {'width': 'min(100%, ${pinnedLengthCss(width)})'}),
  [child],
);
