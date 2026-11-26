/// Toast 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="toast/...">` · `<Card demo>` · `<Anatomy>` 가 읽는다. 같은
/// 이름의 Web 파일(`toast_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야
/// 한다.
///
/// `Toast` 는 놓인 자리에 그려지는 카드라 무대의 카드는 실제 컴포넌트다. 속성
/// `opener` 가 켜지면(플레이그라운드) 카드 아래의 버튼이 같은 속성의 토스트를
/// `showToast` 로 띄운다. 장면은 토스트를 스스로 띄우지 않는다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'toast_page.dart' as page;

/// 속성 → Widget. 태그의 `label` 이 `message` 가 된다. `description` ·
/// `action` 은 글자를 그대로, `dismiss` 는 켜면 닫기 버튼을 읽는다.
FlutterPropPreviewBuilder? get propPreview => _toast;

/// 장면 이름(`toast/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
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
  'toast/do-short': () => _frame(const Toast(message: '링크를 복사했어요', variant: CoreToastVariant.success)),
  'toast/dont-long': () => _frame(
    const Toast(
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
    const Toast(
      message: '결제 수단이 만료됐어요',
      description: '카드를 바꾸지 않으면 다음 달부터 이용이 멈춰요.',
      variant: CoreToastVariant.destructive,
    ),
  ),
};

Widget _toast(Map<String, String> props, String? label) {
  if (previewFlag(props, 'opener')) return _ToastOpener(props: props, label: label);
  return _frame(_card(props, label));
}

/// 속성으로 고른 카드. [onDismiss] · [onAction] 은 띄운 토스트를 닫는 데 쓴다.
Toast _card(Map<String, String> props, String? label, {VoidCallback? onDismiss, VoidCallback? onAction}) {
  final action = props['action'];
  return Toast(
    message: label ?? page.demoMessage,
    description: props['description'],
    variant: page.demoVariant(props),
    showIcon: page.demoShowIcon(props),
    onDismiss: previewFlag(props, 'dismiss') ? onDismiss ?? () {} : null,
    action: action == null ? null : _action(action, onPressed: onAction),
  );
}

/// 토스트에 놓는 행동 버튼 — 플레이그라운드 코드(`toast_page.dart`)와 같은 모양.
Widget _action(String label, {CoreButtonVariant variant = CoreButtonVariant.plain, VoidCallback? onPressed}) => Button(
  variant: variant,
  size: CoreComponentSize.xs,
  onPressed: onPressed ?? () {},
  child: Text(label),
);

/// 카드가 채울 폭 — 카드는 폭이 정해진 부모가 필요하다.
Widget _frame(Widget child, {double width = page.demoToastWidth}) => SizedBox(width: width, child: child);

/// 플레이그라운드의 미리보기 — 카드 아래의 버튼이 같은 속성의 토스트를
/// `showToast` 로 띄운다.
///
/// 띄운 토스트는 둘레의 `ToastLayer`(`CoUIApp` 이 세운다)의 오른쪽 아래에
/// 쌓이고, 기본 시간이 지나면 닫힌다. 닫기 버튼과 행동 버튼은 그 토스트를 닫는다.
class _ToastOpener extends StatelessWidget {
  const _ToastOpener({required this.props, required this.label});

  final Map<String, String> props;
  final String? label;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _frame(_card(props, label)),
      const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space16)),
      Button(
        variant: CoreButtonVariant.outline,
        size: CoreComponentSize.sm,
        onPressed: () {
          showToast(
            context: context,
            builder: (_, overlay) => _card(props, label, onDismiss: overlay.close, onAction: overlay.close),
          );
        },
        child: const Text(page.demoOpener),
      ),
    ],
  );
}
