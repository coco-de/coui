/// Alert 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="alert/...">` 가 읽는다. 같은 이름의 Flutter 파일(`alert_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';

/// 속성 → Component.
///
/// 태그의 `label` 이 제목(`title`)이 된다. `description` · `action` 은 글자를
/// 그대로, `dismiss` 는 켜면 닫기 버튼을, `leading` 은 아이콘 이름을 읽는다.
WebPropPreviewBuilder? get propPreview => _alert;

/// 장면 이름(`alert/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 번호가 설명 오른쪽에 놓일 자리를 두려고 폭을 정한다 — 내용 폭이면
  // 설명 끝 바로 뒤에 행동 버튼이 와서 번호가 버튼 위에 겹친다.
  'alert/anatomy': () => div(styles: Styles(raw: {'width': '32rem'}), [
    Alert.info(
      title: '새 버전이 나왔어요',
      description: '지금 업데이트하면 새 기능을 쓸 수 있어요.',
      onDismiss: () {},
      action: _action('업데이트'),
    ),
  ]),
  'alert/leading-badge': () => const Alert.warning(
    leading: Badge(tone: CoreBadgeTone.warning, child: Text('베타')),
    title: '미리 보기 기능',
    description: '출시 전까지 동작이 바뀔 수 있습니다.',
  ),
  'alert/inline': () => const Alert(
    layout: CoreAlertLayout.inline,
    leading: Badge(tone: CoreBadgeTone.success, showDot: true, child: Text('동기화됨')),
    title: '모든 변경 사항을 클라우드에 저장했어요.',
    action: Icon(
      LucideIcons.chevronDown,
      iconStyle: CoreIconStyle(size: CoreIconSize.size16, color: CoreColor.token(CoreColors.onSurfaceSubtle)),
    ),
  ),
  'alert/do-match-tone': () => const Alert.warning(
    title: '삭제하면 되돌릴 수 없어요',
    description: '프로젝트와 파일 12개가 함께 지워져요.',
  ),
  'alert/dont-wrong-tone': () => const Alert.destructive(
    title: '새 버전이 나왔어요',
    description: '설정에서 업데이트할 수 있어요.',
  ),
  'alert/do-recovery': () => Alert.destructive(
    title: '주문을 저장하지 못했어요',
    description: '연결을 확인한 뒤 다시 시도해 주세요.',
    action: _action('다시 시도'),
  ),
  'alert/dont-dead-end': () => const Alert.destructive(title: '오류가 발생했어요'),
  'alert/do-summary-title': () => const Alert.warning(
    title: '3월 15일 새벽 2시~4시 점검',
    description: '이 시간에는 서비스를 쓸 수 없어요.',
  ),
  'alert/dont-long-description': () => const Alert.warning(
    title: '시스템 점검 안내',
    description: '시스템 점검으로 인해 3월 15일 오전 2시부터 4시까지 서비스가 일시 중단됩니다. 이용에 불편을 드려 죄송합니다.',
  ),
  'alert/do-empty-state': () => _ordersPanel(
    EmptyState(
      title: const Text('주문을 불러오지 못했어요'),
      description: const Text('연결을 확인한 뒤 다시 시도해 주세요.'),
      tone: CoreEmptyStateTone.failure,
      variant: CoreEmptyStateVariant.compact,
      action: _action('다시 시도'),
    ),
  ),
  'alert/dont-alert-for-empty': () => _ordersPanel(
    Alert.destructive(
      title: '주문을 불러오지 못했어요',
      description: '연결을 확인한 뒤 다시 시도해 주세요.',
      action: _action('다시 시도'),
    ),
  ),
  'alert/placement-form': () => _stack([
    Alert.destructive(
      title: '결제하지 못했어요',
      description: '카드 한도를 확인한 뒤 다시 시도해 주세요.',
      onDismiss: () {},
    ),
    div(styles: Styles(raw: {'width': '100%'}), [
      const TextField(label: '카드 번호', placeholder: Text('0000 0000 0000 0000')),
    ]),
    Button(onPressed: () {}, child: const Text('다시 결제')),
  ]),
  'alert/placement-list': () => _stack([
    Alert(
      variant: CoreAlertVariant.warning,
      layout: CoreAlertLayout.inline,
      title: '동기화에 실패했어요.',
      action: Button(
        variant: CoreButtonVariant.ghost,
        size: CoreComponentSize.xs,
        onPressed: () {},
        child: const Text('다시 시도'),
      ),
    ),
    for (final row in _orderRows) Text(row).bodyMedium.onSurface,
  ]),
  'alert/theme-order': () => div(classes: 'docs-demo-order', [
    const Text('적용 순서 · 뒤로 갈수록 우선합니다').labelMedium.onSurfaceVariant,
    ol([
      for (final (index, step) in _themeOrder.indexed)
        li(classes: index == _themeOrder.length - 1 ? 'is-strong' : null, [
          span([Component.text('${index + 1}')]),
          Component.text(step),
        ]),
    ]),
  ]),
  'alert/related-banner': () => const Banner.info(message: Text('3월 15일 새벽 2시부터 점검이 있어요.')),
  'alert/related-toast': () => Toast(message: '저장했어요', variant: CoreToastVariant.success),
  'alert/related-dialog': () => div(classes: 'docs-demo-dialog', [
    div(classes: 'docs-demo-dialog-text', [
      const Text('변경 사항을 버릴까요?').titleMedium.semiBold,
      const Text('저장하지 않은 내용은 사라져요.').bodyMedium.onSurfaceVariant,
    ]),
    div(classes: 'docs-demo-dialog-actions', [
      Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: const Text('취소')),
      Button(variant: CoreButtonVariant.destructive, onPressed: () {}, child: const Text('버리기')),
    ]),
  ]),
};

/// 값이 정해지는 순서 — 왼쪽부터 깔리고, 뒤의 것이 이긴다.
const List<String> _themeOrder = ['레이아웃별 기본값', '종류별 기본값', '테마 기본값', '테마 종류별 값', '인스턴스 alertStyle'];

/// 배치 장면의 목록 행.
const List<String> _orderRows = ['주문 #1024 · 배송 중', '주문 #1023 · 배송 완료', '주문 #1022 · 배송 완료'];

Component _alert(Map<String, String> props, String? label) {
  final action = props['action'];
  return Alert(
    title: label ?? '알림',
    description: props['description'],
    variant: previewEnum(CoreAlertVariant.values, props['variant'], CoreAlertVariant.defaultVariant),
    layout: previewEnum(CoreAlertLayout.values, props['layout'], CoreAlertLayout.defaultLayout),
    leading: docsWebIcon(props['leading']),
    showIcon: previewFlag(props, 'showIcon', fallback: CoreAlertContract.defaultShowIcon),
    onDismiss: previewFlag(props, 'dismiss') ? () {} : null,
    action: action == null ? null : _action(action),
  );
}

/// 알림 끝에 놓는 행동 버튼 — 플레이그라운드 코드(`alert_page.dart`)와 같은 모양.
Component _action(String label) => Button(
  variant: CoreButtonVariant.outline,
  size: CoreComponentSize.sm,
  onPressed: () {},
  child: Text(label),
);

/// 여러 블록을 위에서 아래로 쌓는다 — 폭은 카드 무대 안에 들어가는 20rem.
Component _stack(List<Component> children) => div(
  classes: 'docs-demo-stack',
  styles: Styles(raw: {'width': '20rem'}),
  children,
);

/// 주문 목록 자리 — 제목 아래에 [body] 가 목록 대신 놓인다.
Component _ordersPanel(Component body) => _stack([const Text('주문 목록').titleSmall.semiBold, body]);
